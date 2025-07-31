import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter_thingy_91x/services/ble_service.dart';

class BleProvider with ChangeNotifier {
  final BleService _bleService = BleService();
  bool _isScanning = false;
  List<ScanResult> _scanResults = [];
  BluetoothDevice? _connectedDevice;
  bool _isConnected = false;
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  StreamSubscription? _adapterStateSubscription;
  StreamSubscription? _scanSubscription;
  bool _isBleSupported = false;
  
  // Getters
  bool get isScanning => _isScanning;
  List<ScanResult> get scanResults => _scanResults;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _isConnected;
  BluetoothAdapterState get adapterState => _adapterState;
  bool get isBleSupported => _isBleSupported;
  
  BleProvider() {
    _checkBleSupport();
    _initAdapterStateListener();
  }
  
  Future<void> _checkBleSupport() async {
    try {
      _isBleSupported = await FlutterBluePlus.isSupported;
    } catch (e) {
      _isBleSupported = false;
      print('Error verificando soporte BLE: $e');
    }
    notifyListeners();
  }

  // Añade este método a tu clase BleProvider
  Future<void> requestMtu(int mtu) async {
    if (_connectedDevice != null && !kIsWeb) {
      try {
        if (Platform.isAndroid) {
          await _connectedDevice!.requestMtu(mtu);
          print('MTU actualizado a: ${_connectedDevice!.mtuNow}');
        }
        // En iOS, MTU se negocia automáticamente
      } catch (e) {
        print('Error al solicitar cambio de MTU: $e');
      }
    }
  }
  
  void _initAdapterStateListener() {
    try {
      // En web, no hay eventos de estado del adaptador, por lo que lo manejamos diferente
      if (kIsWeb) {
        _adapterState = BluetoothAdapterState.on; // Asumimos que está encendido en web
        notifyListeners();
        return;
      }
      
      _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
        _adapterState = state;
        notifyListeners();
        print('Estado del adaptador Bluetooth: $_adapterState');
      }, onError: (error) {
        print('Error en adapterState stream: $error');
      });
    } catch (e) {
      print('Error al inicializar el listener de estado del adaptador: $e');
    }
  }
  
  // Verificar si el Bluetooth está disponible y listo
  Future<bool> isBluetoothReady() async {
    // En web simplemente asumimos que está disponible
    if (kIsWeb) {
      return true;
    }
    
    if (!_isBleSupported) {
      return false;
    }
    
    // Para iOS, necesitamos manejar el caso específico del estado desconocido
    if (Platform.isIOS && _adapterState == BluetoothAdapterState.unknown) {
      try {
        // Esperar un poco para que iOS actualice el estado
        await Future.delayed(const Duration(seconds: 1));
        
        // Si sigue siendo desconocido, intentamos una vez más
        if (_adapterState == BluetoothAdapterState.unknown) {
          await Future.delayed(const Duration(seconds: 2));
        }
      } catch (e) {
        print('Error esperando el estado del adaptador Bluetooth: $e');
      }
    }
    
    return _adapterState == BluetoothAdapterState.on;
  }
  
  // Start scanning for BLE devices
  Future<void> startScan() async {
    if (_isScanning) return;
    
    // Limpiar resultados anteriores
    _scanResults = [];
    notifyListeners();
    
    try {
      _isScanning = true;
      notifyListeners();
      
      // Cancelar suscripción anterior si existe
      await _scanSubscription?.cancel();
      
      // Escuchar resultados del escaneo
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        _scanResults = results;
        notifyListeners();
      }, onError: (e) {
        print('Error en scanResults stream: $e');
        _isScanning = false;
        notifyListeners();
      });
      
      // Asegurarse de cancelar la suscripción cuando el escaneo termine
      FlutterBluePlus.cancelWhenScanComplete(_scanSubscription!);
      
      // Usar el servicio para iniciar el escaneo según la plataforma
      await _bleService.startScan();
      
      // Timer de seguridad para detener el escaneo si se queda atascado
      Timer(const Duration(seconds: 20), () {
        if (_isScanning) {
          stopScan();
        }
      });
    } catch (e) {
      print('Error al escanear: $e');
      _isScanning = false;
      notifyListeners();
      rethrow;
    }
  }
  
  // Stop scanning
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      print('Error deteniendo escaneo: $e');
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }
  
  // Connect to a device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      print('🔄 Iniciando conexión a ${device.platformName} (${device.remoteId})...');
      
      // Establecer timeout adecuado según la plataforma
      Duration timeout = kIsWeb ? const Duration(seconds: 10) : const Duration(seconds: 15);
      
      // Intento de conexión
      print('📡 Conectando con timeout de ${timeout.inSeconds}s...');
      await device.connect(timeout: timeout);
      
      // Verificar que la conexión esté establecida y estable
      print('✅ Conexión establecida, verificando estado...');
      await Future.delayed(const Duration(milliseconds: 500)); // Dar tiempo al dispositivo
      
      // Verificar estado de conexión múltiples veces
      int attempts = 0;
      while (attempts < 5) {
        // Obtener el estado actual del stream
        BluetoothConnectionState currentState = await device.connectionState.first;
        print('🔍 Verificando conexión, intento ${attempts + 1}/5 - Estado: $currentState');
        
        if (currentState == BluetoothConnectionState.connected) {
          print('✅ Estado de conexión confirmado: CONNECTED');
          break;
        }
        attempts++;
        await Future.delayed(const Duration(milliseconds: 200));
      }
      
      // Verificación final del estado
      BluetoothConnectionState finalState = await device.connectionState.first;
      if (finalState != BluetoothConnectionState.connected) {
        throw Exception('El dispositivo no se conectó correctamente - Estado final: $finalState');
      }
      
      // Intentar un descubrimiento rápido de servicios para verificar que todo funciona
      try {
        print('🔍 Verificando servicios disponibles...');
        final services = await device.discoverServices();
        print('✅ Servicios encontrados: ${services.length}');
        
        // Log detallado de servicios para debug
        for (var service in services) {
          print('  📋 Servicio: ${service.uuid}');
          for (var char in service.characteristics) {
            print('    🔧 Característica: ${char.uuid} - Propiedades: R:${char.properties.read} W:${char.properties.write} N:${char.properties.notify}');
          }
        }
      } catch (e) {
        print('⚠️ Advertencia: Error en verificación de servicios: $e');
        // No fallar aquí, solo advertir
      }
      
      _connectedDevice = device;
      _isConnected = true;
      
      // Configuración del listener de estado de conexión
      // Solo para plataformas móviles porque es más confiable allí
      if (!kIsWeb) {
        final subscription = device.connectionState.listen((state) {
          print('📡 Cambio de estado de conexión: $state');
          if (state == BluetoothConnectionState.disconnected) {
            _isConnected = false;
            _connectedDevice = null;
            print("💔 Desconectado: ${device.disconnectReason?.code} ${device.disconnectReason?.description}");
            notifyListeners();
          }
        });
        
        // Cancelar suscripción cuando se desconecte
        device.cancelWhenDisconnected(subscription, delayed: true);
      }
      
      print('🎉 Dispositivo conectado y verificado exitosamente');
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Error al conectar: $e');
      _isConnected = false;
      _connectedDevice = null;
      notifyListeners();
      return false;
    }
  }
  
  // Disconnect from device
  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (e) {
        print('Error al desconectar: $e');
      }
      _connectedDevice = null;
      _isConnected = false;
      notifyListeners();
    }
  }
  
  // Get all services and characteristics for connected device
  Future<List<BluetoothService>> discoverServices() async {
    if (_connectedDevice == null) return [];
    try {
      final services = await _connectedDevice!.discoverServices();
      return services;
    } catch (e) {
      print('Error descubriendo servicios: $e');
      return [];
    }
  }
  
  // Método para leer RSSI
  Future<int> readRssi() async {
    if (_connectedDevice == null) return 0;
    
    try {
      return await _connectedDevice!.readRssi();
    } catch (e) {
      print('Error leyendo RSSI: $e');
      return 0;
    }
  }
  
  // Verificar que la conexión esté estable y lista para usar
  Future<bool> isConnectionStable(BluetoothDevice device) async {
    try {
      // Verificar estado básico
      if (device.state != BluetoothConnectionState.connected) {
        return false;
      }
      
      // Intentar una operación simple para verificar que funciona
      try {
        await device.discoverServices();
        return true;
      } catch (e) {
        print('Conexión no estable: $e');
        return false;
      }
    } catch (e) {
      print('Error verificando estabilidad de conexión: $e');
      return false;
    }
  }
  
  // Método de diagnóstico para debugging
  Future<Map<String, dynamic>> getDiagnosticInfo(BluetoothDevice device) async {
    Map<String, dynamic> info = {
      'device_name': device.platformName,
      'device_id': device.remoteId.toString(),
      'connection_state': 'unknown',
      'services_count': 0,
      'nordic_uart_found': false,
      'characteristics': [],
      'errors': [],
    };
    
    try {
      // Estado de conexión
      BluetoothConnectionState state = await device.connectionState.first;
      info['connection_state'] = state.toString();
      
      if (state != BluetoothConnectionState.connected) {
        info['errors'].add('Dispositivo no está conectado: $state');
        return info;
      }
      
      // Descubrir servicios
      List<BluetoothService> services = await device.discoverServices();
      info['services_count'] = services.length;
      
      // Buscar Nordic UART Service
      const String NORDIC_UART_SERVICE = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
      const String NORDIC_UART_TX = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";
      const String NORDIC_UART_RX = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";
      
      for (BluetoothService service in services) {
        Map<String, dynamic> serviceInfo = {
          'uuid': service.uuid.toString(),
          'is_nordic_uart': service.uuid.toString().toLowerCase() == NORDIC_UART_SERVICE.toLowerCase(),
          'characteristics': [],
        };
        
        if (serviceInfo['is_nordic_uart']) {
          info['nordic_uart_found'] = true;
        }
        
        for (BluetoothCharacteristic char in service.characteristics) {
          Map<String, dynamic> charInfo = {
            'uuid': char.uuid.toString(),
            'is_tx': char.uuid.toString().toLowerCase() == NORDIC_UART_TX.toLowerCase(),
            'is_rx': char.uuid.toString().toLowerCase() == NORDIC_UART_RX.toLowerCase(),
            'can_read': char.properties.read,
            'can_write': char.properties.write,
            'can_write_without_response': char.properties.writeWithoutResponse,
            'can_notify': char.properties.notify,
          };
          
          serviceInfo['characteristics'].add(charInfo);
        }
        
        info['characteristics'].add(serviceInfo);
      }
      
    } catch (e) {
      info['errors'].add('Error en diagnóstico: $e');
    }
    
    return info;
  }
  
  // Imprimir diagnóstico formateado
  Future<void> printDiagnostic(BluetoothDevice device) async {
    print('🔍 ===== DIAGNÓSTICO BLE =====');
    Map<String, dynamic> info = await getDiagnosticInfo(device);
    
    print('📱 Dispositivo: ${info['device_name']} (${info['device_id']})');
    print('🔗 Estado: ${info['connection_state']}');
    print('📋 Servicios: ${info['services_count']}');
    print('🎯 Nordic UART encontrado: ${info['nordic_uart_found']}');
    
    if (info['errors'].isNotEmpty) {
      print('❌ Errores:');
      for (String error in info['errors']) {
        print('   • $error');
      }
    }
    
    if (info['characteristics'].isNotEmpty) {
      print('🔧 Servicios y Características:');
      for (Map<String, dynamic> service in info['characteristics']) {
        print('   📋 ${service['uuid']} ${service['is_nordic_uart'] ? '(NORDIC UART)' : ''}');
        for (Map<String, dynamic> char in service['characteristics']) {
          String flags = '';
          if (char['is_tx']) flags += ' TX';
          if (char['is_rx']) flags += ' RX';
          if (char['can_write']) flags += ' W';
          if (char['can_write_without_response']) flags += ' WnR';
          if (char['can_read']) flags += ' R';
          if (char['can_notify']) flags += ' N';
          
          print('      🔧 ${char['uuid']}$flags');
        }
      }
    }
    
    print('🔍 ===== FIN DIAGNÓSTICO =====');
  }
  
  // LED Control
  BluetoothCharacteristic? _ledCharacteristic;
  bool _isLedOn = false;
  
  bool get isLedOn => _isLedOn;
  BluetoothCharacteristic? get ledCharacteristic => _ledCharacteristic;

  Future<bool> initializeLedCharacteristic() async {
    if (_connectedDevice == null) return false;
    
    try {
      List<BluetoothService> services = await _connectedDevice!.discoverServices();
      
      // Buscar el servicio Nordic UART
      for (BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() == "6e400001-b5a3-f393-e0a9-e50e24dcca9e") {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            // Nordic UART TX characteristic (for sending data)
            if (characteristic.uuid.toString().toLowerCase() == "6e400002-b5a3-f393-e0a9-e50e24dcca9e") {
              if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
                _ledCharacteristic = characteristic;
                print('✅ LED: Característica encontrada y configurada');
                notifyListeners();
                return true;
              }
            }
          }
        }
      }
      
      print('❌ LED: No se encontró característica LED válida');
      return false;
    } catch (e) {
      print('❌ LED: Error inicializando característica: $e');
      return false;
    }
  }

  Future<bool> toggleLed(bool turnOn) async {
    if (_ledCharacteristic == null) {
      print('❌ LED: Característica no inicializada');
      return false;
    }

    try {
      await _ledCharacteristic!.write([turnOn ? 1 : 0]);
      _isLedOn = turnOn;
      print('✅ LED: Comando enviado - ${turnOn ? 'ON' : 'OFF'}');
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ LED: Error enviando comando: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _adapterStateSubscription?.cancel();
    super.dispose();
  }
}