import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'dart:io' show Platform;

class BleService {
  // Singleton pattern
  static final BleService _instance = BleService._internal();

  factory BleService() => _instance;

  BleService._internal();

  // Inicialización específica según plataforma
  Future<void> initialize() async {
    // Configurar la depuración
    FlutterBluePlus.setLogLevel(LogLevel.verbose, color: false);
    
    try {
      if (kIsWeb) {
        // Inicialización específica para web
        print('Inicializando BLE para Web');
      } else if (Platform.isIOS) {
        // iOS necesita tiempo para inicializar su estado
        print('Inicializando BLE para iOS');
        await _waitForBluetoothState();
      } else if (Platform.isAndroid) {
        // Android puede necesitar configuración adicional
        print('Inicializando BLE para Android');
      }
    } catch (e) {
      print('Error al inicializar BleService: $e');
    }
  }
  
  // Esperar a que el estado de Bluetooth se estabilice (especialmente importante para iOS)
  Future<void> _waitForBluetoothState() async {
    try {
      // Solo verificar soporte (esto inicializa el adaptador Bluetooth en iOS)
      await FlutterBluePlus.isSupported;
      
      // En iOS, esperar a que el estado se estabilice
      if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.unknown) {
        await Future.delayed(const Duration(seconds: 3));
      }
    } catch (e) {
      print('Error esperando el estado del adaptador Bluetooth: $e');
    }
  }

  // Gestión especial según la plataforma para escanear
  Future<void> startScan({Duration? timeout}) async {
    try {
      if (kIsWeb) {
        // En web, configuración simplificada
        await FlutterBluePlus.startScan(
          timeout: timeout ?? const Duration(seconds: 10),
        );
      } else {
        // En móviles, configuración más detallada
        await FlutterBluePlus.startScan(
          timeout: timeout ?? const Duration(seconds: 15),
          androidUsesFineLocation: false,
        );
      }
    } catch (e) {
      print('Error al iniciar escaneo: $e');
      rethrow;
    }
  }
  
}