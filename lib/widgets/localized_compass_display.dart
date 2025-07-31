import 'package:flutter/material.dart';
import 'package:flutter_thingy_91x/l10n/app_localizations.dart';
import 'package:flutter_thingy_91x/widgets/compass_widget.dart';

/// Enhanced Compass Display with localized labels and controls
class LocalizedCompassDisplay extends StatefulWidget {
  final double bearing; // Current bearing in degrees
  final bool isConnected; // Connection status
  final VoidCallback? onCalibrate; // Calibration callback
  final String? deviceName; // Connected device name
  final bool showCalibration; // Whether to show calibration button
  final bool showDeviceInfo; // Whether to show device info

  const LocalizedCompassDisplay({
    Key? key,
    required this.bearing,
    this.isConnected = false,
    this.onCalibrate,
    this.deviceName,
    this.showCalibration = true,
    this.showDeviceInfo = true,
  }) : super(key: key);

  @override
  State<LocalizedCompassDisplay> createState() => _LocalizedCompassDisplayState();
}

class _LocalizedCompassDisplayState extends State<LocalizedCompassDisplay> {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.05),
            theme.colorScheme.secondary.withOpacity(0.05),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Header with connection status
            if (widget.showDeviceInfo)
              _buildConnectionHeader(localizations, theme),
            
            const SizedBox(height: 24),
            
            // Main compass widget
            _buildCompassSection(localizations, theme),
            
            const SizedBox(height: 32),
            
            // Bearing information card
            _buildBearingInfoCard(localizations, theme),
            
            const SizedBox(height: 24),
            
            // Calibration section
            if (widget.showCalibration)
              _buildCalibrationSection(localizations, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionHeader(AppLocalizations localizations, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Connection status indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isConnected ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          
          // Connection info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isConnected ? localizations.connected : localizations.disconnected,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.isConnected ? Colors.green[700] : Colors.red[700],
                  ),
                ),
                if (widget.deviceName != null && widget.isConnected)
                  Text(
                    widget.deviceName!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          
          // Compass icon
          Icon(
            Icons.explore,
            color: theme.colorScheme.primary,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildCompassSection(AppLocalizations localizations, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title
          Text(
            localizations.compassReading,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Compass widget
          CompassWidget(
            bearing: widget.bearing,
            size: 280,
            primaryColor: theme.colorScheme.primary,
            secondaryColor: theme.colorScheme.secondary,
            showBearing: true,
            animated: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBearingInfoCard(AppLocalizations localizations, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.8),
            theme.colorScheme.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Current direction
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.near_me,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                localizations.currentDirection,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Bearing and direction
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Bearing in degrees
              Column(
                children: [
                  Text(
                    '${widget.bearing.round()}°',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    localizations.bearing,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              
              // Vertical divider
              Container(
                height: 40,
                width: 1,
                color: Colors.white.withOpacity(0.3),
              ),
              
              // Cardinal direction
              Column(
                children: [
                  Text(
                    _getCardinalDirection(widget.bearing),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    localizations.compassDirection,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalibrationSection(AppLocalizations localizations, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Calibration info
          Row(
            children: [
              Icon(
                Icons.tune,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                localizations.compassCalibration,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            localizations.compassCalibrationDescription,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Calibration button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onCalibrate,
              icon: const Icon(Icons.rotate_right),
              label: Text(localizations.calibrateCompass),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCardinalDirection(double bearing) {
    final localizations = AppLocalizations.of(context)!;
    
    if (bearing >= 337.5 || bearing < 22.5) return localizations.north;
    if (bearing >= 22.5 && bearing < 67.5) return localizations.northeast;
    if (bearing >= 67.5 && bearing < 112.5) return localizations.east;
    if (bearing >= 112.5 && bearing < 157.5) return localizations.southeast;
    if (bearing >= 157.5 && bearing < 202.5) return localizations.south;
    if (bearing >= 202.5 && bearing < 247.5) return localizations.southwest;
    if (bearing >= 247.5 && bearing < 292.5) return localizations.west;
    if (bearing >= 292.5 && bearing < 337.5) return localizations.northwest;
    return localizations.north;
  }
}
