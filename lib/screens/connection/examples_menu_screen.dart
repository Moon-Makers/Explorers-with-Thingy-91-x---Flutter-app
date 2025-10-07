import 'package:flutter/material.dart';
import 'package:flutter_thingy_91x/screens/connection/device_scan_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_thingy_91x/screens/connection/mqtt_connection_screen.dart';
import 'package:flutter_thingy_91x/screens/connection/connected_examples_hub.dart';
import 'package:flutter_thingy_91x/providers/ble_provider.dart';
import 'package:flutter_thingy_91x/providers/mqtt_provider.dart';
import 'package:flutter_thingy_91x/l10n/app_localizations.dart';

/// Unified examples menu screen that works for both BLE and MQTT connections
class ExamplesMenuScreen extends StatelessWidget {
  final String connectionType; // 'BLE' or 'MQTT'

  const ExamplesMenuScreen({super.key, required this.connectionType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 0),
      body: Container(
        decoration: BoxDecoration(color: Color(0xFFFAFAFA)),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    
                    // Stack para posicionar la imagen de forma relativa
                    SizedBox(
                      height: 80, // Altura ajustada para evitar superposición
                      child: Stack(
                        clipBehavior: Clip.none, // Permite que los elementos sobresalgan del Stack
                        children: [
                          // Contenedor principal (tarjeta azul)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA8D4E9),
                              borderRadius: BorderRadius.circular(27),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 60), // Aumentado para mover texto a la derecha
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(
                                          context,
                                        )?.examplesUsing(connectionType) ??
                                        'Examples using $connectionType connection',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Imagen posicionada hacia la izquierda sobresaliendo del contenedor
                          Positioned(
                            left: 10, // Posición desde la izquierda
                            top: -15,  // Posición para que sobresalga del contenedor
                            child: Image.asset(
                              connectionType == 'BLE' ? 'assets/images/BLE-image.png' : 'assets/images/MQTT-image.png',
                              width: 80,
                              height: 80,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 20),
                    _ExampleCard(
                      title:
                          AppLocalizations.of(context)?.blinkLed ?? 'Blink LED',
                      subtitle:
                          AppLocalizations.of(context)?.blinkLedSubtitle ??
                          'Control the onboard LED remotely',
                      icon: 'assets/animations/ble.json',
                      onTap: () => _navigateToExample(context, 'led'),
                    ),
                    const SizedBox(height: 24),
                    _ExampleCard(
                      title:
                          AppLocalizations.of(context)?.bme68xSensors ??
                          'BME68X Sensors',
                      subtitle:
                          AppLocalizations.of(context)?.bme68xSensorsSubtitle ??
                          'Monitor temperature, humidity, pressure and air quality',
                      icon: 'assets/animations/cloud.json',
                      onTap: () => _navigateToExample(context, 'sensors'),
                    ),
                    const SizedBox(height: 24),
                    _ExampleCard(
                      title:
                          AppLocalizations.of(context)?.motionSensor ??
                          'Motion Sensor',
                      subtitle:
                          AppLocalizations.of(context)?.motionSensorSubtitle ??
                          'View BMI270 accelerometer and gyroscope data',
                      icon: 'assets/animations/ble.json',
                      onTap: () => _navigateToExample(context, 'motion'),
                    ),
                    const SizedBox(height: 24),
                    _ExampleCard(
                      title:
                          AppLocalizations.of(context)?.floorDetector ??
                          'Floor Detector',
                      subtitle:
                          AppLocalizations.of(context)?.floorDetectorSubtitle ??
                          'Detect current floor using barometric pressure',
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
            builder:
                (_) => ConnectedExamplesHub(
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
            builder: (_) => DeviceScanScreen(targetExample: exampleType),
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
            builder:
                (_) => ConnectedExamplesHub(
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
            builder: (_) => MQTTConnectionScreen(targetExample: exampleType),
          ),
        );
      }
    }
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

class _ExampleCardState extends State<_ExampleCard>
    with SingleTickerProviderStateMixin {
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF82CDF2),
            // borderRadius: BorderRadius.circular(16),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(100),
              bottomLeft: Radius.circular(100),
              topRight: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: Row(
            children: [
              // SizedBox(
              //   width: 80,
              //   height: 80,
              //   child: Lottie.asset(widget.icon, repeat: true),
              // ),
              const SizedBox(width: 100, height: 80,),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.subtitle,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
