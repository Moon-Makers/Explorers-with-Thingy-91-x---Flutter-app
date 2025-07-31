import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../../providers/sensor_provider.dart';
import '../../providers/mqtt_provider.dart';
import '../../widgets/cards/sensor_card.dart';
import '../../widgets/cards/air_quality_indicator.dart';
import '../../widgets/charts/sensor_chart.dart';

/// Unified sensor dashboard that works with both BLE and MQTT connections
class UnifiedSensorDashboard extends StatefulWidget {
  final String connectionType; // 'BLE' or 'MQTT'
  final BluetoothDevice? connectedDevice; // For BLE connection
  
  const UnifiedSensorDashboard({
    super.key,
    required this.connectionType,
    this.connectedDevice,
  });

  @override
  State<UnifiedSensorDashboard> createState() => _UnifiedSensorDashboardState();
}

class _UnifiedSensorDashboardState extends State<UnifiedSensorDashboard> with SingleTickerProviderStateMixin {
  bool _isConnected = false;
  String _connectionStatus = 'Checking connection...';
  String _selectedSensor = 'temperature';
  bool _showChart = false;
  late TabController _tabController;

  final Map<String, Map<String, dynamic>> _sensorInfo = {
    'temperature': {
      'name': 'Temperature',
      'unit': '°C',
      'icon': Icons.thermostat,
      'color': Colors.red,
    },
    'humidity': {
      'name': 'Humidity',
      'unit': '%',
      'icon': Icons.water_drop,
      'color': Colors.blue,
    },
    'pressure': {
      'name': 'Pressure',
      'unit': 'hPa',
      'icon': Icons.compress,
      'color': Colors.green,
    },
    'iaq': {
      'name': 'Air Quality',
      'unit': 'IAQ',
      'icon': Icons.air,
      'color': Colors.orange,
    },
    'co2': {
      'name': 'CO2',
      'unit': 'ppm',
      'icon': Icons.cloud,
      'color': Colors.purple,
    },
    'voc': {
      'name': 'VOC',
      'unit': 'ppm',
      'icon': Icons.visibility,
      'color': Colors.teal,
    },
  };
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkConnectionStatus();
    if (widget.connectionType == 'BLE') {
      _initializeBleCharacteristics();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _checkConnectionStatus() {
    if (widget.connectionType == 'BLE' && widget.connectedDevice != null) {
      setState(() {
        _isConnected = true; // Assume connected if device is passed
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

  Future<void> _initializeBleCharacteristics() async {
    if (widget.connectionType == 'BLE' && widget.connectedDevice != null) {
      try {
        // Discover services for the connected BLE device
        final services = await widget.connectedDevice!.discoverServices();
        
        // Initialize sensor characteristics through SensorProvider
        final sensorProvider = Provider.of<SensorProvider>(context, listen: false);
        await sensorProvider.subscribeToSensors(services);
        
        // Update connection status
        setState(() {
          _connectionStatus = 'BLE Connected - Monitoring BME680 sensors';
        });
        
      } catch (e) {
        print('❌ UnifiedSensorDashboard: Error initializing BLE characteristics: $e');
        setState(() {
          _connectionStatus = 'BLE Error: ${e.toString()}';
        });
      }
    }
  }

  Widget _buildSensorData() {
    if (widget.connectionType == 'BLE') {
      return Consumer<SensorProvider>(
        builder: (context, sensorProvider, child) {
          // Debug reducido - solo resumen cada 20 actualizaciones para evitar saturación
          final totalReadings = sensorProvider.getSensorReadings('temperature').length + 
                               sensorProvider.getSensorReadings('humidity').length + 
                               sensorProvider.getSensorReadings('pressure').length;
          if (totalReadings > 0 && totalReadings % 20 == 1) {
            print('📊 Dashboard Summary: Total sensor readings: $totalReadings');
          }
          
          return _buildSensorCards(
            temperature: sensorProvider.getSensorReadings('temperature').isNotEmpty 
              ? sensorProvider.getSensorReadings('temperature').last.value : 0.0,
            humidity: sensorProvider.getSensorReadings('humidity').isNotEmpty 
              ? sensorProvider.getSensorReadings('humidity').last.value : 0.0,
            pressure: sensorProvider.getSensorReadings('pressure').isNotEmpty 
              ? sensorProvider.getSensorReadings('pressure').last.value : 0.0,
            airQuality: sensorProvider.getSensorReadings('iaq').isNotEmpty 
              ? sensorProvider.getSensorReadings('iaq').last.value : 0.0,
          );
        },
      );
    } else {
      return Consumer<MQTTProvider>(
        builder: (context, mqttProvider, child) {
          return _buildSensorCards(
            temperature: mqttProvider.getSensorValue('temp'),
            humidity: mqttProvider.getSensorValue('humidity'),
            pressure: mqttProvider.getSensorValue('press'),
            airQuality: mqttProvider.getSensorValue('iaq'),
          );
        },
      );
    }
  }

  Widget _buildSensorCards({
    required double temperature,
    required double humidity,
    required double pressure,
    required double airQuality,
  }) {
    return Column(
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
                        'BME68X Environmental Sensors',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.connectionType == 'BLE' && widget.connectedDevice != null)
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () => _showDeviceInfo(),
                    tooltip: 'Device Information',
                  ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Sensor Cards Grid - 6 sensores en grid optimizado 
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5, // Aumentado para evitar overflow
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: [
            SensorCard(
              title: 'Temp',
              value: temperature,
              unit: '°C',
              icon: Icons.thermostat,
              color: Colors.red,
            ),
            SensorCard(
              title: 'Humidity',
              value: humidity,
              unit: '%',
              icon: Icons.water_drop,
              color: Colors.blue,
            ),
            SensorCard(
              title: 'Pressure',
              value: pressure,
              unit: 'hPa',
              icon: Icons.speed,
              color: Colors.green,
            ),
            SensorCard(
              title: 'Air Quality',
              value: airQuality,
              unit: 'IAQ',
              icon: Icons.air,
              color: Colors.purple,
            ),
            // CO2 y VOC
            widget.connectionType == 'BLE' 
              ? Consumer<SensorProvider>(
                  builder: (context, sensorProvider, child) {
                    final co2Value = sensorProvider.getSensorReadings('co2').isNotEmpty 
                      ? sensorProvider.getSensorReadings('co2').last.value : 0.0;
                    return SensorCard(
                      title: 'CO2',
                      value: co2Value,
                      unit: 'ppm',
                      icon: Icons.cloud,
                      color: Colors.orange,
                    );
                  },
                )
              : Consumer<MQTTProvider>(
                  builder: (context, mqttProvider, child) {
                    return SensorCard(
                      title: 'CO2',
                      value: mqttProvider.getSensorValue('co2'),
                      unit: 'ppm',
                      icon: Icons.cloud,
                      color: Colors.orange,
                    );
                  },
                ),
            widget.connectionType == 'BLE' 
              ? Consumer<SensorProvider>(
                  builder: (context, sensorProvider, child) {
                    final vocValue = sensorProvider.getSensorReadings('voc').isNotEmpty 
                      ? sensorProvider.getSensorReadings('voc').last.value : 0.0;
                    return SensorCard(
                      title: 'VOC',
                      value: vocValue,
                      unit: 'ppm',
                      icon: Icons.visibility,
                      color: Colors.teal,
                    );
                  },
                )
              : Consumer<MQTTProvider>(
                  builder: (context, mqttProvider, child) {
                    return SensorCard(
                      title: 'VOC',
                      value: mqttProvider.getSensorValue('voc'),
                      unit: 'ppm',
                      icon: Icons.visibility,
                      color: Colors.teal,
                    );
                  },
                ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Air Quality Indicator
        if (airQuality > 0)
          AirQualityIndicator(iaqValue: airQuality),
        
        const SizedBox(height: 24),
        
        // Status Message
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Icon(
                  Icons.sensors,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Real-time Environmental Monitoring',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Monitoring temperature, humidity, pressure, air quality, CO2, and VOC via ${widget.connectionType}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove back button
        title: Text('Sensors (${widget.connectionType})'),
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
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.dashboard),
              text: 'Dashboard',
            ),
            Tab(
              icon: Icon(Icons.show_chart),
              text: 'Charts',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          _buildChartsTab(),
        ],
      ),
    );
  }

  void _showDeviceInfo() {
    if (widget.connectedDevice != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('BLE Device Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Device: ${widget.connectedDevice!.name}'),
              Text('Address: ${widget.connectedDevice!.id}'),
              const SizedBox(height: 16),
              const Text('Connected via Bluetooth Low Energy'),
              const Text('Using Nordic UART Service'),
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
            const Text('Monitoring:'),
            const SizedBox(height: 8),
            const Text('• Temperature sensor'),
            const Text('• Humidity sensor'),
            const Text('• Pressure sensor'),
            const Text('• Air quality sensor'),
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

  Widget _buildDashboardTab() {
    return Container(
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
          padding: const EdgeInsets.all(16),
          child: _buildSensorData(),
        ),
      ),
    );
  }

  Widget _buildChartsTab() {
    return Container(
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
        child: Column(
          children: [
            // Sensor Selector
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSensor,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down),
                  items: _sensorInfo.entries.map((entry) {
                    final sensorData = entry.value;
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Row(
                        children: [
                          Icon(
                            sensorData['icon'] as IconData,
                            color: sensorData['color'] as Color,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${sensorData['name']} (${sensorData['unit']})',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedSensor = newValue;
                      });
                    }
                  },
                ),
              ),
            ),
            
            // Chart
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildSelectedSensorChart(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedSensorChart() {
    if (widget.connectionType == 'BLE') {
      return Consumer<SensorProvider>(
        builder: (context, sensorProvider, child) {
          final readings = sensorProvider.getSensorReadings(_selectedSensor);
          if (readings.isEmpty) {
            return _buildNoDataWidget();
          }
          return SensorChart(
            sensorType: _selectedSensor,
            readings: readings,
          );
        },
      );
    } else {
      return Consumer<MQTTProvider>(
        builder: (context, mqttProvider, child) {
          // Para MQTT, necesitamos obtener los datos del SensorProvider
          return Consumer<SensorProvider>(
            builder: (context, sensorProvider, child) {
              final readings = sensorProvider.getSensorReadings(_selectedSensor);
              if (readings.isEmpty) {
                return _buildNoDataWidget();
              }
              return SensorChart(
                sensorType: _selectedSensor,
                readings: readings,
              );
            },
          );
        },
      );
    }
  }

  Widget _buildNoDataWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No data available for ${_sensorInfo[_selectedSensor]!['name']}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Wait for sensor readings to appear',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
