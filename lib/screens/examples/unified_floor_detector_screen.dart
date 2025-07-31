import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../../providers/sensor_provider.dart';
import '../../providers/mqtt_provider.dart';

/// Unified floor detector screen that works with both BLE and MQTT connections
class UnifiedFloorDetectorScreen extends StatefulWidget {
  final String connectionType; // 'BLE' or 'MQTT'
  final BluetoothDevice? connectedDevice; // For BLE connection
  
  const UnifiedFloorDetectorScreen({
    super.key,
    required this.connectionType,
    this.connectedDevice,
  });

  @override
  State<UnifiedFloorDetectorScreen> createState() => _UnifiedFloorDetectorScreenState();
}

class _UnifiedFloorDetectorScreenState extends State<UnifiedFloorDetectorScreen> 
    with SingleTickerProviderStateMixin {
  
  // Animation controller
  late AnimationController _animationController;
  
  // Floor detection variables
  double _baselinePressure = 0.0;
  int _currentFloor = 0;
  int _calibrationFloor = 0;
  bool _isCalibrated = false;
  double _pressurePerFloor = 40.0; // Default: 40 units per floor
  final TextEditingController _pressureController = TextEditingController(text: '40.0');
  final TextEditingController _floorNameController = TextEditingController();
  final Map<int, String> _floorNames = {};
  
  // Connection status
  bool _isConnected = false;
  String _connectionStatus = 'Checking connection...';
  double _currentPressure = 0.0;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeFloorNames();
    _setupPressureController();
    _checkConnectionStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pressureController.dispose();
    _floorNameController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    // Optimizado: Animación más rápida para mejor rendimiento en Android
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300), // Reducido de 500 a 300ms
      vsync: this,
    );
  }

  void _initializeFloorNames() {
    _floorNames[0] = "Ground Floor";
    _floorNames[1] = "First Floor";
    _floorNames[2] = "Second Floor";
    _floorNames[-1] = "Basement 1";
    _floorNames[-2] = "Basement 2";
  }

  void _setupPressureController() {
    _pressureController.addListener(() {
      final value = double.tryParse(_pressureController.text);
      if (value != null && value > 0) {
        setState(() {
          _pressurePerFloor = value;
          _updateCurrentFloor();
        });
      }
    });
  }

  void _checkConnectionStatus() {
    if (widget.connectionType == 'BLE' && widget.connectedDevice != null) {
      setState(() {
        _isConnected = true;
        _connectionStatus = 'BLE Connected';
      });
    } else if (widget.connectionType == 'MQTT') {
      final mqttProvider = Provider.of<MQTTProvider>(context, listen: false);
      setState(() {
        _isConnected = mqttProvider.isConnected;
        _connectionStatus = _isConnected ? 'MQTT Connected' : 'MQTT Disconnected';
      });
    }
  }

  void _updateCurrentFloor() {
    if (!_isCalibrated) return;
    
    final pressureDiff = _baselinePressure - _currentPressure;
    final floorChange = (pressureDiff / _pressurePerFloor).round();
    final newFloor = _calibrationFloor + floorChange;
    
    if (_currentFloor != newFloor) {
      setState(() {
        _currentFloor = newFloor;
      });
      _animationController.forward(from: 0.0);
    }
  }

  Widget _buildPressureData() {
    if (widget.connectionType == 'BLE') {
      return Consumer<SensorProvider>(
        builder: (context, sensorProvider, child) {
          final pressureReadings = sensorProvider.getSensorReadings('pressure');
          if (pressureReadings.isNotEmpty) {
            _currentPressure = pressureReadings.last.value;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _updateCurrentFloor();
            });
          }
          return _buildFloorDetectorContent();
        },
      );
    } else {
      return Consumer<MQTTProvider>(
        builder: (context, mqttProvider, child) {
          _currentPressure = mqttProvider.getSensorValue('press');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateCurrentFloor();
          });
          return _buildFloorDetectorContent();
        },
      );
    }
  }

  Widget _buildFloorDetectorContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  color: _isConnected ? Colors.green : Colors.red,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _connectionStatus,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: _isConnected ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Barometric Floor Detection',
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
        
        const SizedBox(height: 16),
        
        // Current Pressure Card
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Current Pressure',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_currentPressure.toStringAsFixed(1)} hPa',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isCalibrated) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Baseline: ${_baselinePressure.toStringAsFixed(1)} hPa',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Floor Display Card
        Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  if (_isCalibrated) ...[
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_animationController.value * 0.1),
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.layers,
                                  color: Colors.white,
                                  size: 40,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Floor',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '$_currentFloor',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _floorNames[_currentFloor] ?? (_currentFloor < 0 
                              ? 'Basement ${_currentFloor.abs()}' 
                              : 'Floor $_currentFloor'),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 16),
                          onPressed: () => _editFloorName(_currentFloor),
                          tooltip: 'Edit floor name',
                        ),
                      ],
                    ),
                  ] else ...[
                    Icon(
                      Icons.explore_off,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Not Calibrated',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please calibrate at a known floor to start detecting',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Controls
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isConnected ? () => _showCalibrationDialog() : null,
                icon: const Icon(Icons.tune),
                label: const Text('Calibrate'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showSettingsDialog(),
                icon: const Icon(Icons.settings),
                label: const Text('Settings'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        if (!_isConnected) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Connection required for pressure readings',
                    style: TextStyle(color: Colors.orange[800]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove back button
        title: Text('Floor Detector (${widget.connectionType})'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              widget.connectionType == 'BLE' 
                ? Icons.bluetooth_connected 
                : Icons.cloud_queue,
              color: _isConnected ? Colors.green : Colors.red,
            ),
            onPressed: () => _showConnectionInfo(),
            tooltip: 'Connection Status',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(),
            tooltip: 'Information',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: _buildPressureData(),
          ),
        ),
      ),
    );
  }

  void _showCalibrationDialog() {
    int selectedFloor = _currentFloor;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Calibrate at Current Location'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Select which floor you are currently on:'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        setDialogState(() {
                          selectedFloor--;
                        });
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        selectedFloor.toString(),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () {
                        setDialogState(() {
                          selectedFloor++;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _floorNames[selectedFloor] ?? (selectedFloor < 0 
                      ? 'Basement ${selectedFloor.abs()}' 
                      : 'Floor $selectedFloor'),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _calibrateAtFloor(selectedFloor);
              Navigator.pop(context);
            },
            child: const Text('Calibrate'),
          ),
        ],
      ),
    );
  }

  void _calibrateAtFloor(int floor) {
    if (_currentPressure > 0) {
      setState(() {
        _baselinePressure = _currentPressure;
        _isCalibrated = true;
        _calibrationFloor = floor;
        _currentFloor = floor;
      });
      
      _animationController.forward(from: 0.0);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Calibrated at floor $floor (${_currentPressure.toStringAsFixed(1)} hPa)'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _editFloorName(int floor) async {
    _floorNameController.text = _floorNames[floor] ?? '';
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Name for Floor $floor'),
        content: TextField(
          controller: _floorNameController,
          decoration: const InputDecoration(
            labelText: 'Floor name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _floorNames[floor] = _floorNameController.text;
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Floor Detection Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _pressureController,
              decoration: const InputDecoration(
                labelText: 'Pressure per floor (hPa)',
                border: OutlineInputBorder(),
                helperText: 'Typical value: 40 hPa per floor',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const Text(
              'Adjust this value based on your building\'s floor height. '
              'Taller floors require higher values.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showConnectionInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.connectionType} Connection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isConnected ? Icons.check_circle : Icons.error,
                  color: _isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  _connectionStatus,
                  style: TextStyle(
                    color: _isConnected ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Monitoring: Barometric pressure sensor'),
            if (widget.connectionType == 'BLE' && widget.connectedDevice != null) ...[
              const SizedBox(height: 8),
              Text('Device: ${widget.connectedDevice!.name}'),
              Text('Address: ${widget.connectedDevice!.id}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Floor Detector Information'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How it works:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Uses barometric pressure to detect floor changes'),
              Text('• Pressure decreases as altitude increases'),
              Text('• Calibrate at a known floor for accurate detection'),
              SizedBox(height: 16),
              Text(
                'Tips:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Calibrate on a floor you know well'),
              Text('• Adjust pressure per floor if needed'),
              Text('• Works best in buildings with consistent floor heights'),
              Text('• Weather changes can affect accuracy'),
              SizedBox(height: 16),
              Text(
                'Accuracy:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Typical accuracy: ±1 floor'),
              Text('• Best in stable weather conditions'),
              Text('• Regular recalibration recommended'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
