import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import '../mqtt/mqtt_client.dart';

class MQTTProvider with ChangeNotifier {
  // Cliente MQTT
  MqttClient? _client;
  bool _isConnected = false;
  String _lastMessage = '';
  bool _ledState = false;
  
  // Callback para datos del BMI270
  Function(String)? _bmi270DataCallback;
  
  // Mapa para almacenar los valores de los sensores
  final Map<String, double> _sensorValues = {
    'temp': 0.0,
    'press': 0.0,
    'humidity': 0.0,
    'iaq': 0.0,
    'co2': 0.0,
    'voc': 0.0,
  };
  
  // Getters
  bool get isConnected => _isConnected;
  String get lastMessage => _lastMessage;
  bool get ledState => _ledState;
  Map<String, double> get sensorValues => _sensorValues;
  
  // Método para registrar callback de datos BMI270
  void setBMI270DataCallback(Function(String) callback) {
    _bmi270DataCallback = callback;
  }
  
  // Método para limpiar callback de datos BMI270
  void clearBMI270DataCallback() {
    _bmi270DataCallback = null;
  }
  
  // Tópicos MQTT para comunicación con la placa Thingy:91 X
  // La placa publica en este tópico y nosotros nos suscribimos para recibir sus mensajes
  static const String devicePublishTopic = 'test-mqtt-app-flutter-abcd951/publish/topic';
  // La placa se suscribe a este tópico y nosotros publicamos comandos en él
  static const String deviceSubscribeTopic = 'test-mqtt-app-flutter-abcd951/subscribe/topic';
  // static const String devicePublishTopic = 'devacademy/publish/topic';
  // // La placa se suscribe a este tópico y nosotros publicamos comandos en él
  // static const String deviceSubscribeTopic = 'devacademy/subscribe/topic';

  // Comandos para control del LED
  static const String turnLedOnCmd = 'LED1ON';
  static const String turnLedOffCmd = 'LED1OFF';

  void publishLedState(bool isOn) {
    final command = isOn ? turnLedOnCmd : turnLedOffCmd;
    _publishMessage(command);
  }

  void _publishMessage(String message) {
    if (_client != null && isConnected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      _client!.publishMessage(
          deviceSubscribeTopic, MqttQos.atLeastOnce, builder.payload!);
    }
  }

  Timer? _pingTimer;
  String? _lastBroker;
  int? _lastPort;

  void startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_client?.connectionStatus?.state != MqttConnectionState.connected) {
        print('Conexión MQTT perdida. Intentando reconectar...');
        _isConnected = false;
        notifyListeners();
        // Auto-reconectar
        if (_lastBroker != null && _lastPort != null) {
          connect(_lastBroker!, _lastPort!);
        }
      }
    });
  }

  Future<bool> connect(String broker, int port) async {
    return connectWithCredentials(broker, port, null, null, false);
  }

  Future<bool> connectWithCredentials(String broker, int port, String? username, String? password, bool useTLS) async {
    try {
      _lastBroker = broker;
      _lastPort = port;
      if (_client != null) {
        _client!.disconnect();
      }

      final clientId = 'flutter_${DateTime.now().millisecondsSinceEpoch}';
      
      _client = MQTTClientWrapper.createClient(broker, clientId, port);
      
      if (_client == null) {
        print('Error: Failed to create MQTT client');
        return false;
      }

      _client!.keepAlivePeriod = 60;
      _client!.onDisconnected = _onDisconnected;
      _client!.onConnected = _onConnected;
      _client!.onSubscribed = _onSubscribed;
      _client!.logging(on: true);

      // Configurar TLS si es requerido
      MQTTClientWrapper.configureClient(_client!, secure: useTLS);

      final connMessage = MqttConnectMessage()
        ..withClientIdentifier(clientId)
        ..startClean()
        ..withWillQos(MqttQos.atLeastOnce)
        ..withWillRetain()
        ..withWillTopic(deviceSubscribeTopic)
        ..withWillMessage('Flutter device disconnected')
        ..withWillQos(MqttQos.atLeastOnce);

      // Agregar credenciales si están disponibles
      if (username != null && username.isNotEmpty) {
        connMessage.authenticateAs(username, password ?? '');
      }

      _client!.connectionMessage = connMessage;

      print('Conectando a MQTT broker: $broker:$port (TLS: $useTLS, Usuario: ${username ?? 'ninguno'})');
      await _client!.connect();

      if (_client!.connectionStatus?.state == MqttConnectionState.connected) {
        print('MQTT Connected to $broker:$port');
        
        // Suscribirse al tópico donde la placa PUBLICA sus mensajes
        _client!.subscribe(devicePublishTopic, MqttQos.atLeastOnce);
        
        // Escuchar mensajes de la placa
        _client!.updates!.listen(
          (List<MqttReceivedMessage<MqttMessage>> c) {
            final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
            final payload = MqttPublishPayload.bytesToStringAsString(
              message.payload.message,
            );
            
            print('📡 SENSOR_PROVIDER: Datos recibidos (${payload.length} bytes): $payload');
            _lastMessage = payload;
            
            // Verificar si el mensaje contiene datos del BMI270
            if (payload.contains('BMI270')) {
              print('📡 SENSOR_PROVIDER: Detectados datos del BMI270');
              if (_bmi270DataCallback != null) {
                _bmi270DataCallback!(payload);
              }
            }
            
            // Actualizar el estado del LED si recibimos confirmación
            if (payload == turnLedOnCmd || payload.contains("LED ON")) {
              _ledState = true;
              print('LED encendido por mensaje');
            } else if (payload == turnLedOffCmd || payload.contains("LED OFF")) {
              _ledState = false;
              print('LED apagado por mensaje');
            }
            
            // Parseamos los datos de los sensores si vienen en el formato esperado
            _parseSensorData(payload);
            
            notifyListeners();
          },
          onError: (e) {
            print('Error al recibir mensaje: $e');
            disconnect();
          },
        );
        
        _isConnected = true;
        startPingTimer();
        notifyListeners();
        return true;
      }
      
      print('Connection failed - Status: ${_client!.connectionStatus}');
      _client!.disconnect();
      return false;
    } catch (e) {
      print('Error connecting to MQTT: $e');
      _isConnected = false;
      _client?.disconnect();
      notifyListeners();
      return false;
    }
  }

  // Analiza los datos del sensor en el formato enviado por el BME68X
  void _parseSensorData(String payload) {
    try {
      // El formato del mensaje es: "temp:28.240385,press:100043.570312,humidity:19.981348,iaq:50,co2:400.000000,voc:0.100000"
      final parts = payload.split(',');
      
      for (final part in parts) {
        final keyValue = part.split(':');
        if (keyValue.length == 2) {
          final key = keyValue[0].trim();
          final value = double.tryParse(keyValue[1].trim());
          
          if (value != null && _sensorValues.containsKey(key)) {
            _sensorValues[key] = value;
          }
        }
      }
      
      notifyListeners();
    } catch (e) {
      print('Error parsing sensor data: $e');
    }
  }

  void publishMessage(String message) {
    if (_client == null) {
      print('Error: Cliente MQTT es nulo');
      return;
    }
    
    if (_client!.connectionStatus?.state == MqttConnectionState.connected) {
      try {
        final builder = MqttClientPayloadBuilder();
        builder.addString(message);
        
        print('Enviando mensaje a $deviceSubscribeTopic: $message');
        
        _client!.publishMessage(
          deviceSubscribeTopic, // Publicamos en el tópico al que la placa está suscrita
          MqttQos.atLeastOnce,
          builder.payload!,
        );
      } catch (e) {
        print('Error al publicar mensaje: $e');
      }
    } else {
      print('Error: Cliente MQTT no está conectado');
    }
  }

  // Métodos para control del LED
  void turnOnLED() {
    if (_isConnected) {
      publishMessage(turnLedOnCmd);
      // No actualizamos _ledState aquí - esperamos confirmación de la placa
    }
  }

  void turnOffLED() {
    if (_isConnected) {
      publishMessage(turnLedOffCmd);
      // No actualizamos _ledState aquí - esperamos confirmación de la placa
    }
  }

  void toggleLED() {
    if (_isConnected) {
      if (_ledState) {
        turnOffLED();
      } else {
        turnOnLED();
      }
    }
  }

  // Unified method for LED control to match BleProvider interface
  Future<bool> toggleLed(bool turnOn) async {
    if (!_isConnected) return false;
    
    try {
      if (turnOn) {
        turnOnLED();
      } else {
        turnOffLED();
      }
      return true;
    } catch (e) {
      print('❌ MQTT LED: Error: $e');
      return false;
    }
  }
  
  // Method to request BMI270 data (similar to BLE implementation)
  void requestBMI270Data() {
    if (_isConnected) {
      publishMessage('BMI270_REQUEST');
    }
  }
  
  void disconnect() {
    try {
      _pingTimer?.cancel();
      if (_client != null) {
        if (_client!.connectionStatus?.state == MqttConnectionState.connected) {
          _client!.disconnect();
        }
        _client = null;
      }
      _isConnected = false;
      _lastMessage = '';
      _ledState = false;
      _sensorValues.updateAll((key, value) => 0.0);
      notifyListeners();
    } catch (e) {
      print('Error disconnecting: $e');
    }
  }
  
  void _onConnected() {
    print('Connected to MQTT broker');
  }
  
  void _onDisconnected() {
    print('Disconnected from MQTT broker');
    _isConnected = false;
    notifyListeners();
  }
  
  void _onSubscribed(String topic) {
    print('Subscribed to topic: $topic');
  }
  
  @override
  void dispose() {
    _pingTimer?.cancel();
    disconnect();
    super.dispose();
  }

  // Método para obtener un valor específico de sensor
  double getSensorValue(String sensorType) {
    return _sensorValues[sensorType] ?? 0.0;
  }
}
