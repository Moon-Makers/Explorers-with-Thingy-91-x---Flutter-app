import 'package:flutter/material.dart';
import 'package:flutter_thingy_91x/screens/connection/examples_menu_screen.dart';
import 'package:flutter_thingy_91x/screens/compass/compass_connection_screen.dart';
import 'package:flutter_thingy_91x/l10n/app_localizations.dart';
import 'package:flutter_thingy_91x/widgets/language_dialog.dart';
import 'package:flutter_thingy_91x/widgets/connection_card.dart';

class ConnectionSelectionScreen extends StatefulWidget {
  const ConnectionSelectionScreen({super.key});

  @override
  State<ConnectionSelectionScreen> createState() =>
      _ConnectionSelectionScreenState();
}

class _ConnectionSelectionScreenState extends State<ConnectionSelectionScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: Stack(
          children: [
            // Language selector button
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: LanguageDialog(),
            ),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 48),
                    Text(
                    "Choose Your Mode",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 42,
                    ),
                    ),
                  const SizedBox(height: 22),
                  Text(
                    "KEEP YOUR DEVICE NEARBY",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 21,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ConnectionCard(
                            title: 'Bluetooth',
                            imagePath: "assets/images/BLE-image.png",
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => const ExamplesMenuScreen(
                                          connectionType: 'BLE',
                                        ),
                                  ),
                                ),
                          ),
                          const SizedBox(height: 24),
                          ConnectionCard(
                            title: 'MQTT',
                            imagePath: "assets/images/MQTT-image.png",
                            imageRight: 210,
                            imageTop: -25,
                            imageSize: 110,
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => const ExamplesMenuScreen(
                                          connectionType: 'MQTT',
                                        ),
                                  ),
                                ),
                          ),
                          const SizedBox(height: 24),
                          ConnectionCard(
                            title: 'Explore',
                            imagePath: "assets/images/explore-image.png",
                            imageTop: 50,
                            imageSize: 110,
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => const CompassConnectionScreen(),
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
