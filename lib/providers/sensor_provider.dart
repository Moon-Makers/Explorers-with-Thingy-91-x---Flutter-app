import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:flutter_thingy_91x/models/sensor_data.dart';

class SensorProvider with ChangeNotifier {
  // Datos de los sensores con un límite máximo de puntos
  final int _maxDataPoints = 100;
  final Map<String, List<SensorData>> _sensorReadings = {
    'temperature': [],
    'humidity': [],
    'pressure': [],
    'iaq': [],
    'co2': [],
    'voc': [],
  };
  
  // Control LED
  BluetoothCharacteristic? _ledCharacteristic;
  bool _isLedOn = false;
  
  // Dispositivo
  String _deviceName = "Thingy:91 X";
  
  // Nordic UART Service
  final String nordicUartServiceUuid = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
  final String nordicUartTxUuid = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';
  final String nordicUartRxUuid = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

  // Para limpieza adecuada
  final Map<BluetoothCharacteristic, StreamSubscription> _subscriptions = {};

  // Para reducir logs (crítico para conexión)
  int _debugCount = 0;

  // Mapa para almacenar las últimas lecturas de cada sensor
  final Map<String, SensorData> _latestReadings = {};

  // Datos para los sensores de movimiento
  ThreeAxisData? _accelerometerData;
  ThreeAxisData? _gyroscopeData;

  // Historial de datos para gráficos
  final Map<String, Queue<SensorData>> _historicalData = {};
  static const int _maxHistoryLength = 100;

  // Getters
  Map<String, List<SensorData>> get sensorReadings => _sensorReadings;
  UnmodifiableListView<SensorData> getSensorReadings(String sensor) => 
      UnmodifiableListView(_sensorReadings[sensor] ?? []);
  bool get isLedOn => _isLedOn;
  String get deviceName => _deviceName;
  BluetoothCharacteristic? get ledCharacteristic => _ledCharacteristic;

  // Getters para la UI
  Map<String, SensorData> get latestReadings => _latestReadings;
  Queue<SensorData>? getHistoricalData(String name) => _historicalData[name];
  ThreeAxisData? get accelerometerData => _accelerometerData;
  ThreeAxisData? get gyroscopeData => _gyroscopeData;

  // Métodos para dispositivo
  void setDeviceName(String name) {
    _deviceName = name;
    notifyListeners();
  }

  // Método usado por MQTT Adapter
  void addSensorReading(String sensorName, double value, DateTime timestamp) {
    // Determinar unidad según el tipo de sensor
    String unit = _getUnitForSensor(sensorName);
    
    // Llamar al método general
    updateSensorReading(sensorName, value, unit);
  }
  
  // Método principal para actualizar lecturas de sensores
  void updateSensorReading(String sensorName, double value, String unit) {
    if (!_sensorReadings.containsKey(sensorName)) {
      _sensorReadings[sensorName] = [];
    }
    
    // Añadir nueva lectura
    _sensorReadings[sensorName]!.add(
      SensorData(
        name: sensorName, 
        value: value, 
        unit: unit, 
        timestamp: DateTime.now()
      )
    );
    
    // Limitar el número de puntos de datos almacenados
    if (_sensorReadings[sensorName]!.length > _maxDataPoints) {
      _sensorReadings[sensorName]!.removeAt(0);
    }
    
    // Actualizar también la última lectura
    _latestReadings[sensorName] = SensorData(
      name: sensorName, 
      value: value, 
      unit: unit, 
      timestamp: DateTime.now()
    );
    
    // Solo log cada 10 actualizaciones para reducir saturación
    if (_debugCount % 10 == 1) {
      print('📊 SENSOR: Updated $sensorName = $value $unit (total readings: ${_sensorReadings[sensorName]!.length})');
    }
    _debugCount++;
    notifyListeners();
  }

  String _getUnitForSensor(String sensorName) {
    switch (sensorName) {
      case 'temperature': return '°C';
      case 'humidity': return '%';
      case 'pressure': return 'hPa';
      case 'iaq': return '';
      case 'co2': return 'ppm';
      case 'voc': return 'ppm';
      default: return '';
    }
  }

  // Suscribirse a sensores BLE
  Future<void> subscribeToSensors(List<BluetoothService> services) async {
    print('✅ SENSOR_PROVIDER: Buscando Nordic UART Service para datos de sensores');
    
    BluetoothCharacteristic? rxCharacteristic;
    
    // Buscar el Nordic UART Service
    for (BluetoothService service in services) {
      if (service.uuid.toString().toLowerCase() == nordicUartServiceUuid.toLowerCase()) {
        print('✅ SENSOR_PROVIDER: Encontrado Nordic UART Service para datos de sensores');
        
        // Buscar la característica RX (para leer datos)
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.uuid.toString().toLowerCase() == nordicUartRxUuid.toLowerCase()) {
            if (characteristic.properties.notify) {
              rxCharacteristic = characteristic;
              print('✅ SENSOR_PROVIDER: Encontrada característica RX con notify para datos de sensores');
              break;
            }
          }
        }
        break;
      }
    }
    
    if (rxCharacteristic == null) {
      print('❌ SENSOR_PROVIDER: No se encontró la característica RX para datos de sensores');
      return;
    }

    try {
      // Limpiar cualquier suscripción anterior
      if (_subscriptions.containsKey(rxCharacteristic)) {
        await _subscriptions[rxCharacteristic]!.cancel();
        _subscriptions.remove(rxCharacteristic);
      }
      
      // Suscribirse a notificaciones
      await rxCharacteristic.setNotifyValue(true);
      
      // Crear la suscripción y guardarla para limpiar después
      final subscription = rxCharacteristic.lastValueStream.listen(
        (value) => _processSensorData(value),
        onError: (error) => print('❌ SENSOR_PROVIDER: Error en la suscripción: $error'),
      );
      
      _subscriptions[rxCharacteristic] = subscription;
      
      print('✅ SENSOR_PROVIDER: Suscripción a datos de sensores completada');
    } catch (e) {
      print('❌ SENSOR_PROVIDER: Error al suscribirse a datos de sensores: $e');
    }
  }

  void _processSensorData(List<int> data) {
    final String dataString = String.fromCharCodes(data).trim();
    
    // Solo log en errores o cada 20 actualizaciones para reducir saturación
    _debugCount++;
    if (_debugCount % 20 == 1) {
      print('📡 SENSOR_PROVIDER: Processing data packet #$_debugCount (${data.length} bytes)');
    }
    
    try {
      // Limpiar datos de códigos ANSI escape
      String cleanedData = dataString.replaceAll(RegExp(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])'), '');
      cleanedData = cleanedData.replaceAll(RegExp(r'[\^]\[\[.*?\]'), '');
      
      // Dividir en líneas y procesar cada una
      List<String> lines = cleanedData.split('\n');
      for (String line in lines) {
        String trimmedLine = line.trim();
        if (trimmedLine.isEmpty) continue;
        
        // Procesar formato BME680 desde Nordic logs
        if (trimmedLine.contains('BME680')) {
          _processBME680Data(trimmedLine);
        }
        // Procesar formato BMI270 para motion data
        else if (trimmedLine.contains('BMI270')) {
          _processBMI270Data(trimmedLine);
        }
      }
    } catch (e) {
      print('❌ SENSOR_PROVIDER: Error procesando datos: $e');
    }
  }

  void _processBME680Data(String dataString) {
    try {
      // Solo log cada 10 procesamiento para reducir saturación
      if (_debugCount % 10 == 1) {
        print('🌡️ SENSOR_PROVIDER: Processing BME680 data #$_debugCount');
      }
      
      // Extraer temperatura
      RegExp tempRegex = RegExp(r'temp:\s*([0-9.-]+)[\s°Â°]*C', caseSensitive: false);
      Match? tempMatch = tempRegex.firstMatch(dataString);
      if (tempMatch != null) {
        try {
          double temp = double.parse(tempMatch.group(1)!);
          updateSensorReading('temperature', temp, '°C');
        } catch (e) {
          print('❌ Error parsing temperature: $e');
        }
      }
      
      // Extraer humedad
      RegExp humidityRegex = RegExp(r'humidity:\s*([0-9.-]+)%', caseSensitive: false);
      Match? humidityMatch = humidityRegex.firstMatch(dataString);
      if (humidityMatch != null) {
        try {
          double humidity = double.parse(humidityMatch.group(1)!);
          updateSensorReading('humidity', humidity, '%');
        } catch (e) {
          print('❌ Error parsing humidity: $e');
        }
      }
      
      // Extraer presión
      RegExp pressureRegex = RegExp(r'press:\s*([0-9.-]+)\s*Pa', caseSensitive: false);
      Match? pressureMatch = pressureRegex.firstMatch(dataString);
      if (pressureMatch != null) {
        try {
          double pressure = double.parse(pressureMatch.group(1)!) / 100; // Convertir Pa a hPa
          updateSensorReading('pressure', pressure, 'hPa');
        } catch (e) {
          print('❌ Error parsing pressure: $e');
        }
      }
      
      // Extraer gas resistance
      RegExp gasRegex = RegExp(r'gas:\s*([0-9.-]+)\s*[ΩÎ©]', caseSensitive: false);
      Match? gasMatch = gasRegex.firstMatch(dataString);
      if (gasMatch != null) {
        try {
          double gasResistance = double.parse(gasMatch.group(1)!);
          // Convertir resistencia de gas a un valor de IAQ aproximado
          double iaq = _convertGasResistanceToIAQ(gasResistance);
          updateSensorReading('iaq', iaq, '');
          
          // Estimar CO2 y VOC basado en gas resistance
          double estimatedCO2 = _estimateCO2FromGas(gasResistance);
          updateSensorReading('co2', estimatedCO2, 'ppm');
          
          double estimatedVOC = _estimateVOCFromGas(gasResistance);
          updateSensorReading('voc', estimatedVOC, 'ppm');
        } catch (e) {
          print('❌ Error parsing gas resistance: $e');
        }
      }
      
    } catch (e) {
      print('❌ SENSOR_PROVIDER: Error procesando datos BME680: $e');
    }
  }

  void _processBMI270Data(String dataString) {
    // Procesar datos de acelerómetro y giroscopio si es necesario
    // Por ahora, simplemente ignoramos BMI270 data en el sensor dashboard
  }

  double _convertGasResistanceToIAQ(double gasResistance) {
    // Mapeo aproximado basado en valores típicos del BME680
    if (gasResistance > 50000000) { // >50 MΩ - Excelente
      return 25; // IAQ muy bueno
    } else if (gasResistance > 10000000) { // >10 MΩ - Bueno  
      return 50; // IAQ bueno
    } else if (gasResistance > 5000000) { // >5 MΩ - Promedio
      return 100; // IAQ promedio
    } else if (gasResistance > 1000000) { // >1 MΩ - Malo
      return 150; // IAQ malo
    } else { // <1 MΩ - Muy malo
      return 200; // IAQ muy malo
    }
  }

  double _estimateCO2FromGas(double gasResistance) {
    // Estimación simple de CO2 basada en resistencia de gas
    // Resistencia más baja = más compuestos orgánicos = más CO2 estimado
    if (gasResistance > 50000000) {
      return 400; // Nivel base de CO2
    } else if (gasResistance > 10000000) {
      return 450;
    } else if (gasResistance > 5000000) {
      return 500;
    } else if (gasResistance > 1000000) {
      return 600;
    } else {
      return 800;
    }
  }

  double _estimateVOCFromGas(double gasResistance) {
    // Estimación simple de VOC basada en resistencia de gas
    if (gasResistance > 50000000) {
      return 0.1; // VOC muy bajo
    } else if (gasResistance > 10000000) {
      return 0.3;
    } else if (gasResistance > 5000000) {
      return 0.5;
    } else if (gasResistance > 1000000) {
      return 1.0;
    } else {
      return 2.0; // VOC alto
    }
  }

  // Limpiar todas las lecturas
  void clearAllReadings({bool notify = true}) {
    for (var key in _sensorReadings.keys) {
      _sensorReadings[key] = [];
    }
    _latestReadings.clear();
    if (notify) {
      notifyListeners();
    }
  }

  // Limpiar suscripciones
  Future<void> dispose() async {
    for (var subscription in _subscriptions.values) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }
}
