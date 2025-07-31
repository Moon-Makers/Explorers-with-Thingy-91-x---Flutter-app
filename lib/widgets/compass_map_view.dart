import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_thingy_91x/widgets/compass_widget.dart';

/// Widget that handles the map view with compass overlay
class CompassMapView extends StatelessWidget {
  final Position? currentPosition;
  final Set<Marker> markers;
  final double currentHeading;
  final int currentFloor;
  final MapType mapType;
  final Function(GoogleMapController) onMapCreated;
  final VoidCallback onCenterLocation;
  final VoidCallback onToggleMapType;

  const CompassMapView({
    super.key,
    required this.currentPosition,
    required this.markers,
    required this.currentHeading,
    required this.currentFloor,
    required this.mapType,
    required this.onMapCreated,
    required this.onCenterLocation,
    required this.onToggleMapType,
  });

  String _getLocalizedText(BuildContext context, String englishText, String spanishText) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode == 'es' ? spanishText : englishText;
  }

  @override
  Widget build(BuildContext context) {
    if (currentPosition == null) {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                _getLocalizedText(context, 'Loading map...', 'Cargando mapa...'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Google Map
        GoogleMap(
          onMapCreated: onMapCreated,
          initialCameraPosition: CameraPosition(
            target: LatLng(currentPosition!.latitude, currentPosition!.longitude),
            zoom: 16.0,
          ),
          markers: markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          compassEnabled: false,
          mapType: mapType,
        ),
        
        // Compass overlay
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: CompassWidget(
              bearing: currentHeading,
              size: 100,
              showBearing: true,
              animated: true,
              primaryColor: Colors.blue[600],
              backgroundColor: Colors.white,
            ),
          ),
        ),
        
        // Floor indicator
        Positioned(
          bottom: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  Colors.blue[50]!,
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.blue[200]!,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.layers,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_getLocalizedText(context, "Floor", "Piso")} $currentFloor',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Map controls in top right
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              // Map type toggle
              _MapControlButton(
                icon: Icons.layers,
                onTap: onToggleMapType,
              ),
              
              const SizedBox(height: 12),
              
              // My location button
              _MapControlButton(
                icon: Icons.my_location,
                onTap: onCenterLocation,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapControlButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              size: 24,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
