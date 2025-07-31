import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../../providers/mqtt_provider.dart';

/// Simple LED Control Screen - Only Control Section (WORKING VERSION)
/// Works with both BLE and MQTT connections
class UnifiedLedControlScreen extends StatefulWidget {
  final String connectionType; // 'BLE' or 'MQTT'
  final BluetoothDevice? connectedDevice; // For BLE connection

  const UnifiedLedControlScreen({
    super.key,
    required this.connectionType,
    this.connectedDevice,
  });

  @override
  State<UnifiedLedControlScreen> createState() => _UnifiedLedControlScreenState();
}

class _UnifiedLedControlScreenState extends State<UnifiedLedControlScreen> {
  bool _ledState = false;
  BluetoothCharacteristic? _writeCharacteristic;
  bool _isInitialized = false;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  bool _isInitializing = false;

  // Localization helper methods
  String _getLocalizedText(String englishText, String spanishText) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'es') {
      return spanishText;
    }
    return englishText;
  }

  @override
  void initState() {
    super.initState();
    if (widget.connectionType == 'BLE') {
      _initializeBleConnection();
      _startConnectionMonitoring();
    }
  }

  void _startConnectionMonitoring() {
    if (widget.connectedDevice == null) return;
    
    // Cancel any existing subscription
    _connectionSubscription?.cancel();
    
    // Monitor connection state
    _connectionSubscription = widget.connectedDevice!.connectionState.listen((state) {
      debugPrint('📡 LED: Estado de conexión cambió a: $state');
      
      if (state == BluetoothConnectionState.disconnected) {
        debugPrint('💔 LED: Dispositivo desconectado');
        if (mounted) {
          setState(() {
            _isInitialized = false;
            _writeCharacteristic = null;
          });
        }
      }
    });
    
    // Cancel subscription when disconnected
    widget.connectedDevice!.cancelWhenDisconnected(_connectionSubscription!);
  }

  Future<void> _initializeBleConnection() async {
    if (widget.connectedDevice == null) {
      debugPrint('❌ No connected device provided');
      return;
    }

    if (_isInitializing) {
      debugPrint('⚠️ LED: Initialization already in progress, skipping...');
      return;
    }

    _isInitializing = true;

    debugPrint('################################################');
    debugPrint('🔍 STARTING BLE LED CONTROL INITIALIZATION...');
    debugPrint('📱 Device: ${widget.connectedDevice!.platformName}');
    debugPrint('📍 Address: ${widget.connectedDevice!.remoteId}');
    debugPrint('################################################');

    if (mounted) {
      setState(() {
        _isInitialized = false;
      });
    }

    try {
      // Wait for connection to stabilize
      debugPrint('⏱️ LED: Esperando estabilización de conexión...');
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Verify connection with retries
      int connectionAttempts = 0;
      while (connectionAttempts < 3) {
        BluetoothConnectionState currentState = await widget.connectedDevice!.connectionState.first;
        debugPrint('🔍 LED: Verificando conexión, intento ${connectionAttempts + 1}/3 - Estado: $currentState');
        
        if (currentState == BluetoothConnectionState.connected) {
          debugPrint('✅ LED: Conexión confirmada');
          break;
        }
        connectionAttempts++;
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      BluetoothConnectionState finalState = await widget.connectedDevice!.connectionState.first;
      if (finalState != BluetoothConnectionState.connected) {
        throw Exception('Dispositivo no conectado después de verificaciones - Estado: $finalState');
      }

      // Discover services with retries
      List<BluetoothService> services = [];
      int serviceAttempts = 0;
      
      while (serviceAttempts < 3 && services.isEmpty) {
        try {
          debugPrint('🔍 LED: Intento ${serviceAttempts + 1}/3 de descubrimiento de servicios...');
          services = await widget.connectedDevice!.discoverServices();
          if (services.isNotEmpty) {
            debugPrint('✅ LED: ${services.length} servicios encontrados');
            break;
          }
        } catch (e) {
          debugPrint('❌ LED: Intento ${serviceAttempts + 1} falló: $e');
        }
        serviceAttempts++;
        if (serviceAttempts < 3) {
          await Future.delayed(const Duration(milliseconds: 1000));
        }
      }
      
      if (services.isEmpty) {
        throw Exception('No se pudieron descubrir servicios después de ${serviceAttempts} intentos');
      }

      bool foundLedCharacteristic = false;
      
      // Nordic UART Service UUIDs - EXACTLY as in your C code
      const String NORDIC_UART_SERVICE = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
      const String NORDIC_UART_TX = "6e400002-b5a3-f393-e0a9-e50e24dcca9e"; // TX (write from app)
      
      debugPrint('🔍 LED: Buscando Nordic UART Service ($NORDIC_UART_SERVICE)...');
      
      // Search for Nordic UART Service
      for (BluetoothService service in services) {
        debugPrint('📋 LED: Servicio encontrado: ${service.uuid}');
        
        if (service.uuid.toString().toLowerCase() == NORDIC_UART_SERVICE.toLowerCase()) {
          debugPrint('🎯 LED: ¡Nordic UART Service encontrado!');
          
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            String charUuid = characteristic.uuid.toString().toLowerCase();
            debugPrint('  🔧 LED: Característica: $charUuid');
            
            // Use TX characteristic to send LED commands
            if (charUuid == NORDIC_UART_TX.toLowerCase()) {
              debugPrint('  📝 LED: Propiedades - Write: ${characteristic.properties.write}, WriteWithoutResponse: ${characteristic.properties.writeWithoutResponse}');
              
              if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
                _writeCharacteristic = characteristic;
                foundLedCharacteristic = true;
                debugPrint('✅ LED: ¡Nordic UART TX encontrada para LED!');
                break;
              }
            }
          }
          
          if (foundLedCharacteristic) break;
        }
      }

      if (mounted) {
        setState(() {
          _isInitialized = foundLedCharacteristic;
        });
      }

      if (foundLedCharacteristic) {
        debugPrint('################################################');
        debugPrint('✅ BLE LED CONTROL INITIALIZATION SUCCESSFUL!');
        debugPrint('🎯 Ready to send LED commands ([1]=ON, [0]=OFF)');
        debugPrint('################################################');
        
        // Ensure LED starts OFF
        await _sendLedCommand(false);
      } else {
        debugPrint('❌ LED: No se encontró característica LED válida');
        throw Exception('Nordic UART Service o TX characteristic no encontrados');
      }

    } catch (e) {
      debugPrint('################################################');
      debugPrint('❌ CRITICAL ERROR in BLE LED initialization: $e');
      debugPrint('################################################');
      
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _sendLedCommand(bool turnOn) async {
    if (_writeCharacteristic == null) return;

    try {
      // Use the EXACT same logic that works in the working code
      await _writeCharacteristic!.write([turnOn ? 1 : 0]);
      
      debugPrint('Comando LED enviado: ${turnOn ? '[1]' : '[0]'}');

    } catch (e) {
      debugPrint('Error enviando comando LED: $e');
    }
  }

  Future<void> _toggleLed(bool newState) async {
    if (_writeCharacteristic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getLocalizedText(
            'LED control not available',
            'Control de LED no disponible'
          )),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (mounted) {
      setState(() {
        _ledState = newState;
      });
    }
    
    // Send BLE command or MQTT command
    if (widget.connectionType == 'BLE') {
      await _sendLedCommand(newState);
    } else if (widget.connectionType == 'MQTT') {
      final mqttProvider = Provider.of<MQTTProvider>(context, listen: false);
      mqttProvider.publishLedState(newState);
    }

    // Show feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_ledState 
            ? _getLocalizedText('LED turned on', 'LED encendido')
            : _getLocalizedText('LED turned off', 'LED apagado')),
          backgroundColor: _ledState ? Colors.green : Colors.grey,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getLocalizedText(
          'LED Control (${widget.connectionType})',
          'Control LED (${widget.connectionType})'
        )),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              widget.connectionType == 'BLE' 
                ? (_isInitialized ? Icons.bluetooth_connected : Icons.bluetooth_disabled)
                : Icons.cloud_queue,
              color: widget.connectionType == 'BLE' 
                ? (_isInitialized ? Colors.lightGreenAccent : Colors.redAccent)
                : Colors.lightGreenAccent,
            ),
            onPressed: () => _showConnectionInfo(),
            tooltip: _getLocalizedText('Connection Status', 'Estado de Conexión'),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Connection Status Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          widget.connectionType == 'BLE' 
                            ? Icons.bluetooth 
                            : Icons.cloud,
                          color: Colors.green,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getLocalizedText(
                                  '${widget.connectionType} Connected',
                                  '${widget.connectionType} Conectado'
                                ),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.connectionType == 'BLE' 
                                  ? (_isInitialized 
                                    ? _getLocalizedText('LED Control Ready', 'Control LED Listo')
                                    : _getLocalizedText('Initializing...', 'Inicializando...'))
                                  : _getLocalizedText('LED Control Ready', 'Control LED Listo'),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // LED Status Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Icon(
                          _ledState ? Icons.lightbulb : Icons.lightbulb_outline,
                          size: 120,
                          color: _ledState 
                            ? Colors.yellow.shade600 
                            : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _getLocalizedText('LED Status', 'Estado del LED'),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _ledState 
                            ? _getLocalizedText('ON', 'ENCENDIDO')
                            : _getLocalizedText('OFF', 'APAGADO'),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: _ledState ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Control Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Text(
                          _getLocalizedText('LED Control', 'Control LED'),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildControlButton(
                              icon: Icons.power_off,
                              label: _getLocalizedText('Turn OFF', 'Apagar'),
                              isSelected: _ledState,
                              onPressed: () => _toggleLed(false),
                              color: Colors.red,
                            ),
                            _buildControlButton(
                              icon: Icons.power,
                              label: _getLocalizedText('Turn ON', 'Encender'),
                              isSelected: !_ledState,
                              onPressed: () => _toggleLed(true),
                              color: Colors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ElevatedButton.icon(
          onPressed: widget.connectionType == 'BLE' 
            ? (_isInitialized ? onPressed : null)
            : onPressed,
          icon: Icon(icon),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? color : Colors.grey[300],
            foregroundColor: isSelected ? Colors.white : Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  void _showConnectionInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getLocalizedText(
          '${widget.connectionType} Connection',
          'Conexión ${widget.connectionType}'
        )),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  _getLocalizedText(
                    '${widget.connectionType} Connected',
                    '${widget.connectionType} Conectado'
                  ),
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(_getLocalizedText('LED Control:', 'Control LED:')),
            const SizedBox(height: 8),
            Text(_getLocalizedText('• Binary commands ([1]/[0])', '• Comandos binarios ([1]/[0])')),
            Text(_getLocalizedText('• Nordic UART Service', '• Servicio Nordic UART')),
            Text(_getLocalizedText('• Real-time control', '• Control en tiempo real')),
            Text(_getLocalizedText('• Status feedback', '• Retroalimentación de estado')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_getLocalizedText('OK', 'OK')),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Cancelar cualquier suscripción activa
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    
    // Marcar que ya no está inicializando para evitar setState() después de dispose
    _isInitializing = false;
    
    super.dispose();
  }
}
