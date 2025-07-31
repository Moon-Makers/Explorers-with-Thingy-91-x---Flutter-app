import 'package:flutter/material.dart';
import 'package:flutter_thingy_91x/l10n/app_localizations.dart';
import 'package:flutter_thingy_91x/screens/compass/compass_navigation_screen_refactored.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Screen to select connection type for Compass Navigation
/// Allows user to choose between BLE or MQTT connection for indoor navigation
class CompassConnectionScreen extends StatefulWidget {
  const CompassConnectionScreen({super.key});

  @override
  State<CompassConnectionScreen> createState() => _CompassConnectionScreenState();
}

class _CompassConnectionScreenState extends State<CompassConnectionScreen> {
  
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.compassNavigation,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
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
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with compass icon
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Compass SVG
                      Container(
                        width: 140,
                        height: 140,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: SvgPicture.asset(
                          'assets/images/compass_card.svg',
                          width: 120,
                          height: 120,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        localizations.indoorNavigationSystem,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        localizations.indoorNavigationDescription,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
              
                // Connection button
                Text(
                  localizations.startNavigation,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Connect to Navigation button
                ElevatedButton.icon(
                  onPressed: () => _connectToNavigation(),
                  icon: const Icon(Icons.navigation),
                  label: Text(localizations.connectAndNavigate),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                ),
                
                const SizedBox(height: 32), // Extra spacing at bottom for better scroll

                 // Features list
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.features,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _FeatureItem(
                        icon: Icons.map,
                        title: localizations.interactiveMap,
                        description: localizations.interactiveMapDescription,
                      ),
                      _FeatureItem(
                        icon: Icons.explore,
                        title: localizations.compassDirection,
                        description: localizations.compassDirectionDescription,
                      ),
                      _FeatureItem(
                        icon: Icons.layers,
                        title: localizations.floorDetection,
                        description: localizations.floorDetectionDescription,
                      ),
                      _FeatureItem(
                        icon: Icons.navigation,
                        title: localizations.navigation,
                        description: localizations.navigationDescription,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Future<void> _connectToNavigation() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.connectingToMqtt),
          ],
        ),
      ),
    );
    
    try {
      // Simulate MQTT connection
      await Future.delayed(const Duration(seconds: 2));
      
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      // Show success and navigate
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.mqttConnected),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate to compass navigation with MQTT connection
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const CompassNavigationScreen(connectionType: 'MQTT'),
        ),
      );
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.mqttConnectionFailed),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
