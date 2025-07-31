import 'package:flutter/material.dart';
import 'package:flutter_thingy_91x/l10n/app_localizations.dart';

/// Widget that shows nearby devices list
class CompassDevicesPanel extends StatelessWidget {
  final List<dynamic> nearbyDevices; // Using dynamic to avoid type conflicts
  final void Function(dynamic) onNavigateToDevice;

  const CompassDevicesPanel({
    super.key,
    required this.nearbyDevices,
    required this.onNavigateToDevice,
  });

  String _getLocalizedText(BuildContext context, String englishText, String spanishText) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      final locale = Localizations.localeOf(context);
      return locale.languageCode == 'es' ? spanishText : englishText;
    }
    
    // Map common strings to proper localization keys
    switch (englishText) {
      case 'Floor':
        return localizations.floor;
      case 'Navigate':
        return localizations.navigate;
      case 'Online':
        return 'En línea'; // Fallback since not in localizations
      case 'Offline':
        return 'Desconectado'; // Fallback since not in localizations
      default:
        final locale = Localizations.localeOf(context);
        return locale.languageCode == 'es' ? spanishText : englishText;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (nearbyDevices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.devices,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _getLocalizedText(context, 'No devices found', 'No se encontraron dispositivos'),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: nearbyDevices.length,
      itemBuilder: (context, index) {
        final device = nearbyDevices[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 2,
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: device.isOnline ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.device_hub,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              device.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getLocalizedText(context, "Floor", "Piso")} ${device.floor} • ${device.heading.toStringAsFixed(0)}°'
                ),
                const SizedBox(height: 2),
                Text(
                  device.isOnline 
                    ? _getLocalizedText(context, 'Online', 'En línea')
                    : _getLocalizedText(context, 'Offline', 'Desconectado'),
                  style: TextStyle(
                    color: device.isOnline ? Colors.green : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () => onNavigateToDevice(device),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(80, 32),
              ),
              child: Text(
                _getLocalizedText(context, 'Navigate', 'Navegar'),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        );
      },
    );
  }
}
