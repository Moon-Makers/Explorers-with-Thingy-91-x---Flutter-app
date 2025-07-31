import 'package:flutter/material.dart';
import 'package:flutter_thingy_91x/l10n/app_localizations.dart';
import 'package:flutter_thingy_91x/widgets/localized_compass_display.dart';

/// Widget that shows device information and compass data
class CompassInfoPanel extends StatelessWidget {
  final double currentHeading;
  final bool isConnected;
  final String deviceName;
  final String connectionStatus;
  final String? currentPosition;
  final int currentFloor;
  final bool isFloorCalibrated;
  final VoidCallback onCalibrate;

  const CompassInfoPanel({
    super.key,
    required this.currentHeading,
    required this.isConnected,
    required this.deviceName,
    required this.connectionStatus,
    required this.currentPosition,
    required this.currentFloor,
    required this.isFloorCalibrated,
    required this.onCalibrate,
  });

  String _getLocalizedText(BuildContext context, String englishText, String spanishText) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      final locale = Localizations.localeOf(context);
      return locale.languageCode == 'es' ? spanishText : englishText;
    }
    
    // Map common strings to proper localization keys
    switch (englishText) {
      case 'Device Name':
        return localizations.deviceName;
      case 'Current Heading':
        return localizations.currentHeading;
      case 'Location':
        return localizations.location;
      case 'Unknown':
        return localizations.unknown;
      case 'Current Floor':
        return localizations.currentFloor;
      case 'Calibrate':
        return localizations.calibrate;
      case 'Connection':
        return localizations.connection;
      default:
        final locale = Localizations.localeOf(context);
        return locale.languageCode == 'es' ? spanishText : englishText;
    }
  }

  String _getCardinalDirection(BuildContext context, double bearing) {
    if (bearing >= 337.5 || bearing < 22.5) return _getLocalizedText(context, 'North', 'Norte');
    if (bearing >= 22.5 && bearing < 67.5) return _getLocalizedText(context, 'Northeast', 'Noreste');
    if (bearing >= 67.5 && bearing < 112.5) return _getLocalizedText(context, 'East', 'Este');
    if (bearing >= 112.5 && bearing < 157.5) return _getLocalizedText(context, 'Southeast', 'Sureste');
    if (bearing >= 157.5 && bearing < 202.5) return _getLocalizedText(context, 'South', 'Sur');
    if (bearing >= 202.5 && bearing < 247.5) return _getLocalizedText(context, 'Southwest', 'Suroeste');
    if (bearing >= 247.5 && bearing < 292.5) return _getLocalizedText(context, 'West', 'Oeste');
    if (bearing >= 292.5 && bearing < 337.5) return _getLocalizedText(context, 'Northwest', 'Noroeste');
    return _getLocalizedText(context, 'Unknown', 'Desconocido');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Advanced compass display widget
          LocalizedCompassDisplay(
            bearing: currentHeading,
            isConnected: isConnected,
            deviceName: deviceName,
            onCalibrate: onCalibrate,
            showCalibration: true,
            showDeviceInfo: true,
          ),
          
          const SizedBox(height: 24),
          
          _InfoItem(
            icon: Icons.device_hub,
            title: _getLocalizedText(context, 'Device Name', 'Nombre del Dispositivo'),
            value: deviceName,
          ),
          _InfoItem(
            icon: Icons.explore,
            title: _getLocalizedText(context, 'Current Heading', 'Dirección Actual'),
            value: '${currentHeading.toStringAsFixed(1)}° (${_getCardinalDirection(context, currentHeading)})',
          ),
          _InfoItem(
            icon: Icons.location_on,
            title: _getLocalizedText(context, 'Location', 'Ubicación'),
            value: currentPosition ?? _getLocalizedText(context, 'Unknown', 'Desconocida'),
          ),
          _InfoItem(
            icon: Icons.layers,
            title: _getLocalizedText(context, 'Current Floor', 'Piso Actual'),
            value: '$currentFloor',
            action: TextButton(
              onPressed: onCalibrate,
              child: Text(_getLocalizedText(context, 'Calibrate', 'Calibrar')),
            ),
          ),
          _InfoItem(
            icon: Icons.signal_cellular_alt,
            title: _getLocalizedText(context, 'Connection', 'Conexión'),
            value: connectionStatus,
            color: isConnected ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 80), // Extra space at bottom for scrolling
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? color;
  final Widget? action;

  const _InfoItem({
    required this.icon,
    required this.title,
    required this.value,
    this.color,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.grey[600]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
