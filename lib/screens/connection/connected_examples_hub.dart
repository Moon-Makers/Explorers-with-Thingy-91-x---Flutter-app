import 'package:flutter/material.dart';
import 'package:flutter_thingy_91x/screens/examples/unified_led_control_screen_working.dart';
import 'package:flutter_thingy_91x/screens/examples/unified_motion_sensor_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../providers/ble_provider.dart';
import '../../providers/mqtt_provider.dart';
import '../../providers/sensor_provider.dart';
import '../examples/unified_sensor_dashboard.dart';
import '../examples/unified_floor_detector_screen.dart';
import '../../widgets/mqtt_sensor_adapter.dart';

/// Hub principal que mantiene la conexión activa y navega entre ejemplos
class ConnectedExamplesHub extends StatefulWidget {
  final String connectionType; // 'BLE' or 'MQTT'
  final BluetoothDevice? connectedDevice; // For BLE connection
  final String? initialExample; // 'led', 'sensors', or 'floor'

  const ConnectedExamplesHub({
    super.key,
    required this.connectionType,
    this.connectedDevice,
    this.initialExample,
  });

  @override
  State<ConnectedExamplesHub> createState() => _ConnectedExamplesHubState();
}

class _ConnectedExamplesHubState extends State<ConnectedExamplesHub> {
  int _currentIndex = 0;
  bool _isInitialized = false;

  final List<_ExampleTab> _tabs = [
    _ExampleTab(
      title: 'LED Control',
      titleEs: 'Control LED',
      icon: Icons.lightbulb_outline,
      color: Colors.orange,
    ),
    _ExampleTab(
      title: 'Sensors',
      titleEs: 'Sensores',
      icon: Icons.sensors,
      color: Colors.blue,
    ),
    _ExampleTab(
      title: 'Motion',
      titleEs: 'Movimiento',
      icon: Icons.fitness_center,
      color: Colors.purple,
    ),
    _ExampleTab(
      title: 'Floor Detector',
      titleEs: 'Detector de Piso',
      icon: Icons.stairs,
      color: Colors.green,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Establecer el índice inicial basado en el ejemplo seleccionado
    _currentIndex = _getInitialIndex();
    _initializeConnection();
  }

  int _getInitialIndex() {
    switch (widget.initialExample) {
      case 'led':
        return 0; // LED Control (ahora es el primero)
      case 'sensors':
        return 1; // Sensors (ahora es el segundo)
      case 'motion':
        return 2; // Motion Sensor (ahora es el tercero)
      case 'floor':
        return 3; // Floor Detector (ahora es el cuarto)
      default:
        return 0; // LED Control (nuevo default)
    }
  }

  Future<void> _initializeConnection() async {
    if (widget.connectionType == 'BLE' && widget.connectedDevice != null) {
      // Inicializar BLE characteristics para sensores
      try {
        final sensorProvider = Provider.of<SensorProvider>(context, listen: false);
        final services = await widget.connectedDevice!.discoverServices();
        await sensorProvider.subscribeToSensors(services);
        
        // Inicializar LED characteristic
        final bleProvider = Provider.of<BleProvider>(context, listen: false);
        await bleProvider.initializeLedCharacteristic();
        
        setState(() {
          _isInitialized = true;
        });
      } catch (e) {
        print('Error initializing BLE: $e');
      }
    } else if (widget.connectionType == 'MQTT') {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent automatic back navigation
      onPopInvoked: (didPop) async {
        if (!didPop) {
          _navigateBackToExamplesMenu();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_getLocalizedAppBarTitle()),
          backgroundColor: _tabs[_currentIndex].color,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            _buildConnectionStatus(),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _showDisconnectDialog,
              tooltip: _getLocalizedText('Disconnect', 'Desconectar'),
            ),
          ],
        ),
        body: Stack(
          children: [
            // MQTT Sensor Adapter (invisible widget for MQTT data sync)
            if (widget.connectionType == 'MQTT')
              const MQTTSensorAdapter(),
            
            // Main content
            _isInitialized ? _buildCurrentExample() : _buildLoadingScreen(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: _tabs[_currentIndex].color,
          unselectedItemColor: Colors.grey,
          items: _tabs.map((tab) => BottomNavigationBarItem(
            icon: Icon(tab.icon),
            label: tab.getLocalizedTitle(context),
          )).toList(),
        ),
      ),
    );
  }

  String _getLocalizedAppBarTitle() {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'es') {
      return 'Ejemplos ${widget.connectionType}';
    }
    return '${widget.connectionType} Examples';
  }

  String _getLocalizedText(String englishText, String spanishText) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'es') {
      return spanishText;
    }
    return englishText;
  }

  Widget _buildConnectionStatus() {
    if (widget.connectionType == 'BLE') {
      return Consumer<BleProvider>(
        builder: (context, bleProvider, child) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: bleProvider.isConnected ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bluetooth, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  bleProvider.isConnected 
                    ? _getLocalizedText('Connected', 'Conectado')
                    : _getLocalizedText('Disconnected', 'Desconectado'),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          );
        },
      );
    } else {
      return Consumer<MQTTProvider>(
        builder: (context, mqttProvider, child) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: mqttProvider.isConnected ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  mqttProvider.isConnected 
                    ? _getLocalizedText('Connected', 'Conectado')
                    : _getLocalizedText('Disconnected', 'Desconectado'),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  Widget _buildLoadingScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _tabs[_currentIndex].color.withOpacity(0.8),
            _tabs[_currentIndex].color.withOpacity(0.6),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              _getLocalizedText(
                'Initializing ${widget.connectionType} connection...',
                'Inicializando conexión ${widget.connectionType}...'
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentExample() {
    switch (_currentIndex) {
      case 0: // LED Control (primero)
        return UnifiedLedControlScreen(
          connectionType: widget.connectionType,
          connectedDevice: widget.connectedDevice,
        );
      case 1: // Sensors (segundo)
        return UnifiedSensorDashboard(
          connectionType: widget.connectionType,
          connectedDevice: widget.connectedDevice,
        );
      case 2: // Motion (tercero)
        return UnifiedMotionSensorScreen(
          connectionType: widget.connectionType,
          connectedDevice: widget.connectedDevice,
        );
      case 3: // Floor Detector (cuarto)
        return UnifiedFloorDetectorScreen(
          connectionType: widget.connectionType,
          connectedDevice: widget.connectedDevice,
        );
      default:
        return UnifiedLedControlScreen(
          connectionType: widget.connectionType,
          connectedDevice: widget.connectedDevice,
        );
    }
  }

  void _navigateBackToExamplesMenu() {
    // Navigate back to examples menu without disconnecting
    Navigator.of(context).pop();
  }

  void _showDisconnectDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_getLocalizedText('Disconnect', 'Desconectar')),
          content: Text(_getLocalizedText(
            'Do you want to disconnect from ${widget.connectionType}?',
            '¿Quieres desconectarte de ${widget.connectionType}?'
          )),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_getLocalizedText('Cancel', 'Cancelar')),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _disconnect();
              },
              child: Text(_getLocalizedText('Disconnect', 'Desconectar')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _disconnect() async {
    if (widget.connectionType == 'BLE') {
      final bleProvider = Provider.of<BleProvider>(context, listen: false);
      final sensorProvider = Provider.of<SensorProvider>(context, listen: false);
      
      // Limpiar suscripciones del sensor provider
      await sensorProvider.dispose();
      await bleProvider.disconnect();
    } else {
      final mqttProvider = Provider.of<MQTTProvider>(context, listen: false);
      mqttProvider.disconnect();
    }

    // Navigate back to connection selection
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

class _ExampleTab {
  final String title;
  final String? titleEs;
  final IconData icon;
  final Color color;

  _ExampleTab({
    required this.title,
    this.titleEs,
    required this.icon,
    required this.color,
  });

  String getLocalizedTitle(BuildContext context) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'es' && titleEs != null) {
      return titleEs!;
    }
    return title;
  }
}
