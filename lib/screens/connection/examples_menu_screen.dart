import 'package:flutter/material.dart';
import 'package:flutter_thingy_91x/screens/connection/device_scan_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:flutter_thingy_91x/screens/connection/mqtt_connection_screen.dart';
import 'package:flutter_thingy_91x/screens/connection/connected_examples_hub.dart';
import 'package:flutter_thingy_91x/providers/ble_provider.dart';
import 'package:flutter_thingy_91x/providers/mqtt_provider.dart';
import 'package:flutter_thingy_91x/l10n/app_localizations.dart';

/// Unified examples menu screen that works for both BLE and MQTT connections
class ExamplesMenuScreen extends StatelessWidget {
  final String connectionType; // 'BLE' or 'MQTT'

  const ExamplesMenuScreen({
    super.key,
    required this.connectionType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.examplesTitle(connectionType) ?? '$connectionType Examples'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(connectionType == 'BLE' ? Icons.bluetooth : Icons.cloud),
            onPressed: () => _showConnectionInfo(context),
            tooltip: 'Connection Information',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
              Theme.of(context).colorScheme.secondary.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)?.selectExample ?? 'Select an Example',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
                    const SizedBox(height: 16),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            connectionType == 'BLE' ? Icons.bluetooth_connected : Icons.cloud_queue,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child:                      Text(
                        AppLocalizations.of(context)?.examplesUsing(connectionType) ?? 'Examples using $connectionType connection',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 20),                      _ExampleCard(
                        title: AppLocalizations.of(context)?.blinkLed ?? 'Blink LED',
                        subtitle: AppLocalizations.of(context)?.blinkLedSubtitle ?? 'Control the onboard LED remotely',
                        icon: 'assets/animations/ble.json',
                        onTap: () => _navigateToExample(context, 'led'),
                      ),
                      const SizedBox(height: 24),
                      _ExampleCard(
                        title: AppLocalizations.of(context)?.bme68xSensors ?? 'BME68X Sensors',
                        subtitle: AppLocalizations.of(context)?.bme68xSensorsSubtitle ?? 'Monitor temperature, humidity, pressure and air quality',
                        icon: 'assets/animations/cloud.json',
                        onTap: () => _navigateToExample(context, 'sensors'),
                      ),
                      const SizedBox(height: 24),
                      _ExampleCard(
                        title: AppLocalizations.of(context)?.motionSensor ?? 'Motion Sensor',
                        subtitle: AppLocalizations.of(context)?.motionSensorSubtitle ?? 'View BMI270 accelerometer and gyroscope data',
                        icon: 'assets/animations/ble.json',
                        onTap: () => _navigateToExample(context, 'motion'),
                      ),
                      const SizedBox(height: 24),
                      _ExampleCard(
                        title: AppLocalizations.of(context)?.floorDetector ?? 'Floor Detector',
                        subtitle: AppLocalizations.of(context)?.floorDetectorSubtitle ?? 'Detect current floor using barometric pressure',
                        icon: 'assets/animations/mqtt.json',
                        onTap: () => _navigateToExample(context, 'floor'),
                      ),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToExample(BuildContext context, String exampleType) {
    if (connectionType == 'BLE') {
      // Check if there's already a BLE connection
      final bleProvider = Provider.of<BleProvider>(context, listen: false);
      
      if (bleProvider.isConnected && bleProvider.connectedDevice != null) {
        // If already connected, go directly to the examples hub
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConnectedExamplesHub(
              connectionType: 'BLE',
              connectedDevice: bleProvider.connectedDevice,
              initialExample: exampleType,
            ),
          ),
        );
      } else {
        // If not connected, navigate to device scan screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DeviceScanScreen(
              targetExample: exampleType,
            ),
          ),
        );
      }
    } else {
      // For MQTT, check if already connected
      final mqttProvider = Provider.of<MQTTProvider>(context, listen: false);
      
      if (mqttProvider.isConnected) {
        // If already connected, go directly to the examples hub
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConnectedExamplesHub(
              connectionType: 'MQTT',
              initialExample: exampleType,
            ),
          ),
        );
      } else {
        // If not connected, navigate to MQTT connection screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MQTTConnectionScreen(
              targetExample: exampleType,
            ),
          ),
        );
      }
    }
  }

  void _showConnectionInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$connectionType Connection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              connectionType == 'BLE' 
                ? 'Bluetooth Low Energy (BLE) provides:' 
                : 'MQTT (Message Queuing Telemetry Transport) provides:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (connectionType == 'BLE') ...[
              const Text('• Direct device connection'),
              const Text('• Low latency communication'),
              const Text('• No internet required'),
              const Text('• Perfect for real-time control'),
            ] else ...[
              const Text('• Cloud-based communication'),
              const Text('• Remote access capability'),
              const Text('• Reliable message delivery'),
              const Text('• Perfect for IoT applications'),
            ],
            const SizedBox(height: 16),
            Text(
              'Features available:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• LED control with visual feedback'),
            const Text('• Environmental sensor monitoring'),
            const Text('• Smart floor detection system'),
            const Text('• Real-time data visualization'),
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

class _ExampleCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String icon;
  final VoidCallback onTap;

  const _ExampleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  _ExampleCardState createState() => _ExampleCardState();
}

class _ExampleCardState extends State<_ExampleCard> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  @override
  void initState() {
    super.initState();
    // Optimizado: Animación más rápida y simple para mejor rendimiento en Android
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150), // Reducido de 300 a 150ms
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(_animController); // Sin CurvedAnimation para mejor rendimiento
    
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(_animController); // Sin CurvedAnimation para mejor rendimiento
  }
  
  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _animController.forward(),
      onExit: (_) => _animController.reverse(),
      child: GestureDetector(
        onTapDown: (_) => _animController.forward(),
        onTapUp: (_) {
          _animController.reverse();
          widget.onTap();
        },
        onTapCancel: () => _animController.reverse(),
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Material(
                  color: Colors.transparent,
                  child: _buildCardContent(context),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Lottie.asset(
              widget.icon,
              repeat: true,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_animController.value * -4, 0),
                child: const Icon(Icons.arrow_forward_ios),
              );
            },
          ),
        ],
      ),
    );
  }
}
