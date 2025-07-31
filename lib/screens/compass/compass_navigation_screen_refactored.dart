import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_thingy_91x/l10n/app_localizations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_thingy_91x/widgets/compass_map_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Simulated sensor events
class MagnetometerEvent {
  final double x, y, z;
  MagnetometerEvent(this.x, this.y, this.z);
}

class AccelerometerEvent {
  final double x, y, z;
  AccelerometerEvent(this.x, this.y, this.z);
}

// Helper classes
class DeviceLocation {
  final String id;
  String name; // Changed to mutable for renaming
  final Position position;
  final int floor;
  final double heading;
  final bool isOnline;

  DeviceLocation({
    required this.id,
    required this.name,
    required this.position,
    required this.floor,
    required this.heading,
    required this.isOnline,
  });
  
  // Add copyWith method for easy renaming
  DeviceLocation copyWith({
    String? id,
    String? name,
    Position? position,
    int? floor,
    double? heading,
    bool? isOnline,
  }) {
    return DeviceLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      floor: floor ?? this.floor,
      heading: heading ?? this.heading,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

class NavigationStep {
  final String instruction;
  final double distance;
  final double bearing;
  final int floor;

  NavigationStep({
    required this.instruction,
    required this.distance,
    required this.bearing,
    required this.floor,
  });
}

/// Compass Navigation Screen with map, device configuration and indoor navigation
/// Refactored to use modular widgets for better maintainability
class CompassNavigationScreen extends StatefulWidget {
  final String connectionType; // 'BLE' or 'MQTT'
  final BluetoothDevice? connectedDevice; // For BLE connection

  const CompassNavigationScreen({
    super.key,
    required this.connectionType,
    this.connectedDevice,
  });

  @override
  State<CompassNavigationScreen> createState() => _CompassNavigationScreenState();
}

class _CompassNavigationScreenState extends State<CompassNavigationScreen>
    with TickerProviderStateMixin {
  
  // Google Maps controller
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  
  // Location and compass data
  Position? _currentPosition;
  final double _currentHeading = 0.0;
  final int _currentFloor = 1;
  
  // Navigation data
  List<DeviceLocation> _nearbyDevices = [];
  
  // Sensors and timers
  StreamSubscription<Position>? _positionStream;
  Timer? _updateTimer;
  
  // Animation controllers
  late AnimationController _compassAnimController;
  late AnimationController _pulseAnimController;
  
  // UI state
  MapType _currentMapType = MapType.terrain; // Mapa estilo antiguo por defecto

  // Device naming functionality
  Map<String, String> _deviceCustomNames = {};
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _compassAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseAnimController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    // Initialize location and sensors
    _initializeLocationAndSensors();
    
    // Initialize MQTT connection
    _initializeMqttConnection();
    
    // Load custom device names
    _loadDeviceNames();
    
    // Start update timer
    _updateTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _compassAnimController.dispose();
    _pulseAnimController.dispose();
    _positionStream?.cancel();
    _updateTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeLocationAndSensors() async {
    try {
      await _tryRealLocation();
    } catch (e) {
      debugPrint('❌ Error with real location, using simulated: $e');
      _useSimulatedLocation();
    }
  }

  Future<void> _tryRealLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied forever');
    }
    
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    
    setState(() {
      _currentPosition = position;
    });
    
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).listen((Position position) {
      setState(() {
        _currentPosition = position;
      });
    });
    
    _simulateNearbyDevices();
  }

  void _useSimulatedLocation() {
    // Use a default location (Madrid, Spain)
    setState(() {
      _currentPosition = Position(
        latitude: 40.4168,
        longitude: -3.7038,
        timestamp: DateTime.now(),
        accuracy: 1.0,
        altitude: 0.0,
        altitudeAccuracy: 1.0,
        heading: 0.0,
        headingAccuracy: 1.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    });
    
    _simulateNearbyDevices();
  }

  Future<void> _initializeMqttConnection() async {
    // Simulated MQTT connection
    await Future.delayed(const Duration(seconds: 2));
  }

  void _simulateNearbyDevices() {
    if (_currentPosition == null) return;
    
    setState(() {
      _nearbyDevices = [
        DeviceLocation(
          id: 'device_1',
          name: 'Thingy:91X #1',
          position: Position(
            latitude: _currentPosition!.latitude + 0.0001,
            longitude: _currentPosition!.longitude + 0.0002,
            timestamp: DateTime.now(),
            accuracy: 1.0,
            altitude: 0.0,
            altitudeAccuracy: 1.0,
            heading: 0.0,
            headingAccuracy: 1.0,
            speed: 0.0,
            speedAccuracy: 0.0,
          ),
          floor: 1,
          heading: 45.0,
          isOnline: true,
        ),
        DeviceLocation(
          id: 'device_2',
          name: 'Thingy:91X #2',
          position: Position(
            latitude: _currentPosition!.latitude + 0.0002,
            longitude: _currentPosition!.longitude - 0.0001,
            timestamp: DateTime.now(),
            accuracy: 1.0,
            altitude: 0.0,
            altitudeAccuracy: 1.0,
            heading: 0.0,
            headingAccuracy: 1.0,
            speed: 0.0,
            speedAccuracy: 0.0,
          ),
          floor: 2,
          heading: 180.0,
          isOnline: true,
        ),
      ];
      _updateMapMarkers();
    });
  }

  void _updateMapMarkers() {
    Set<Marker> newMarkers = {};
    
    // Add current position marker
    if (_currentPosition != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('current_position'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }
    
    // Add device markers
    for (final device in _nearbyDevices) {
      newMarkers.add(
        Marker(
          markerId: MarkerId(device.id),
          position: LatLng(device.position.latitude, device.position.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            device.isOnline ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: device.name,
            snippet: 'Floor ${device.floor}',
          ),
        ),
      );
    }
    
    setState(() {
      _markers = newMarkers;
    });
  }

  void _centerOnCurrentLocation() async {
    if (_currentPosition != null && _mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 18.0,
            bearing: _currentHeading,
          ),
        ),
      );
    }
  }

  void _toggleMapType() {
    // Mostrar un dialog con opciones de mapa
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar Estilo de Mapa'),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MapTypeOption(
                  title: 'Mapa Antiguo',
                  description: 'Estilo pergamino vintage',
                  icon: Icons.auto_stories,
                  isSelected: _currentMapType == MapType.terrain,
                  onTap: () {
                    setState(() => _currentMapType = MapType.terrain);
                    Navigator.pop(context);
                  },
                ),
                _MapTypeOption(
                  title: 'Normal',
                  description: 'Vista estándar del mapa',
                  icon: Icons.map,
                  isSelected: _currentMapType == MapType.normal,
                  onTap: () {
                    setState(() => _currentMapType = MapType.normal);
                    Navigator.pop(context);
                  },
                ),
                _MapTypeOption(
                  title: 'Satélite',
                  description: 'Vista satelital',
                  icon: Icons.satellite_alt,
                  isSelected: _currentMapType == MapType.satellite,
                  onTap: () {
                    setState(() => _currentMapType = MapType.satellite);
                    Navigator.pop(context);
                  },
                ),
                _MapTypeOption(
                  title: 'Híbrido',
                  description: 'Satélite con etiquetas',
                  icon: Icons.layers,
                  isSelected: _currentMapType == MapType.hybrid,
                  onTap: () {
                    setState(() => _currentMapType = MapType.hybrid);
                    Navigator.pop(context);
                  },
                ),
                _MapTypeOption(
                  title: 'Terreno',
                  description: 'Vista topográfica',
                  icon: Icons.terrain,
                  isSelected: _currentMapType == MapType.terrain,
                  onTap: () {
                    setState(() => _currentMapType = MapType.terrain);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Device naming functionality
  Future<void> _loadDeviceNames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final namesString = prefs.getString('device_custom_names');
      if (namesString != null) {
        // Simple JSON-like parsing for device names
        final parts = namesString.split('|');
        for (final part in parts) {
          if (part.isNotEmpty) {
            final keyValue = part.split('=');
            if (keyValue.length == 2) {
              _deviceCustomNames[keyValue[0]] = keyValue[1];
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading device names: $e');
    }
  }
  
  Future<void> _saveDeviceNames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final namesString = _deviceCustomNames.entries
          .map((e) => '${e.key}=${e.value}')
          .join('|');
      await prefs.setString('device_custom_names', namesString);
    } catch (e) {
      debugPrint('Error saving device names: $e');
    }
  }
  
  Future<void> _renameDevice(String deviceId, String newName) async {
    _deviceCustomNames[deviceId] = newName;
    await _saveDeviceNames();
    
    // Update the device in nearbyDevices if it exists
    final deviceIndex = _nearbyDevices.indexWhere((device) => device.id == deviceId);
    if (deviceIndex != -1) {
      _nearbyDevices[deviceIndex] = _nearbyDevices[deviceIndex].copyWith(name: newName);
      setState(() {});
    }
  }
  
  String _getDeviceName(String deviceId, String originalName) {
    return _deviceCustomNames[deviceId] ?? originalName;
  }

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
      body: Stack(
        children: [
          // Map area using CompassMapView widget with bottom padding
          Padding(
            padding: const EdgeInsets.only(bottom: 90), // Aumentado de 70 a 90
            child: CompassMapView(
              currentPosition: _currentPosition,
              markers: _markers,
              currentHeading: _currentHeading,
              currentFloor: _currentFloor,
              mapType: _currentMapType,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              onCenterLocation: _centerOnCurrentLocation,
              onToggleMapType: _toggleMapType,
            ),
          ),
          
          // Fixed bottom menu
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 90, // Aumentado de 70 a 90
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false, // No aplicar SafeArea en la parte superior
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _BottomMenuButton(
                      icon: Icons.info_outline,
                      label: 'Info',
                      onTap: () => _navigateToInfoPage(),
                    ),
                    _BottomMenuButton(
                      icon: Icons.devices,
                      label: 'Devices',
                      onTap: () => _navigateToDevicesPage(),
                    ),
                    _BottomMenuButton(
                      icon: Icons.navigation,
                      label: 'Navigation',
                      onTap: () => _navigateToNavigationPage(),
                    ),
                    _BottomMenuButton(
                      icon: Icons.map,
                      label: 'Map Style',
                      onTap: _toggleMapType,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Navegación a páginas completas
  void _navigateToInfoPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _InfoPage(
          currentHeading: _currentHeading,
          currentFloor: _currentFloor,
          currentPosition: _currentPosition,
          nearbyDevices: _nearbyDevices,
          connectionType: widget.connectionType,
          connectedDevice: widget.connectedDevice,
        ),
      ),
    );
  }

  void _navigateToDevicesPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _DevicesPage(
          nearbyDevices: _nearbyDevices,
          connectionType: widget.connectionType,
          connectedDevice: widget.connectedDevice,
          onDeviceRenamed: (deviceId, newName) async {
            // Aquí se implementaría la lógica para renombrar dispositivos BLE
            final prefs = await SharedPreferences.getInstance();
            // Guardar el nuevo nombre en SharedPreferences
            await prefs.setString(deviceId, newName);
            
            setState(() {
              // Actualizar el nombre del dispositivo en la lista
              final deviceIndex = _nearbyDevices.indexWhere((d) => d.id == deviceId);
              if (deviceIndex != -1) {
                _nearbyDevices[deviceIndex] = _nearbyDevices[deviceIndex].copyWith(name: newName);
              }
            });
          },
        ),
      ),
    );
  }

  void _navigateToNavigationPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _NavigationPage(
          currentPosition: _currentPosition,
          nearbyDevices: _nearbyDevices,
          onCenterLocation: _centerOnCurrentLocation,
        ),
      ),
    );
  }
}

// Página de información completa
class _InfoPage extends StatelessWidget {
  final double currentHeading;
  final int currentFloor;
  final Position? currentPosition;
  final List<DeviceLocation> nearbyDevices;
  final String connectionType;
  final BluetoothDevice? connectedDevice;

  const _InfoPage({
    required this.currentHeading,
    required this.currentFloor,
    required this.currentPosition,
    required this.nearbyDevices,
    required this.connectionType,
    required this.connectedDevice,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Información del Sistema'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoCard(
              title: 'Brújula Digital',
              icon: Icons.explore,
              children: [
                _InfoRow('Dirección', '${currentHeading.toStringAsFixed(1)}°'),
                _InfoRow('Cardinal', _getCardinalDirection(currentHeading)),
                _InfoRow('Piso Actual', '$currentFloor'),
              ],
            ),
            const SizedBox(height: 16),
            _InfoCard(
              title: 'Ubicación GPS',
              icon: Icons.location_on,
              children: [
                if (currentPosition != null) ...[
                  _InfoRow('Latitud', currentPosition!.latitude.toStringAsFixed(6)),
                  _InfoRow('Longitud', currentPosition!.longitude.toStringAsFixed(6)),
                  _InfoRow('Precisión', '${currentPosition!.accuracy.toStringAsFixed(1)}m'),
                  _InfoRow('Velocidad', '${currentPosition!.speed.toStringAsFixed(1)} m/s'),
                ] else
                  const Text('GPS no disponible'),
              ],
            ),
            const SizedBox(height: 16),
            _InfoCard(
              title: 'Conexión',
              icon: Icons.settings_bluetooth,
              children: [
                _InfoRow('Tipo', connectionType),
                if (connectedDevice != null) ...[
                  _InfoRow('Dispositivo', connectedDevice!.platformName),
                  _InfoRow('Estado', 'Conectado'),
                ] else
                  _InfoRow('Estado', 'No conectado'),
                _InfoRow('Dispositivos Cercanos', '${nearbyDevices.length}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getCardinalDirection(double heading) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    int index = ((heading + 22.5) / 45).floor() % 8;
    return directions[index];
  }
}

// Página de dispositivos con funcionalidad de renombrado
class _DevicesPage extends StatefulWidget {
  final List<DeviceLocation> nearbyDevices;
  final String connectionType;
  final BluetoothDevice? connectedDevice;
  final Function(String deviceId, String newName) onDeviceRenamed;

  const _DevicesPage({
    required this.nearbyDevices,
    required this.connectionType,
    required this.connectedDevice,
    required this.onDeviceRenamed,
  });

  @override
  State<_DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<_DevicesPage> {
  void _showRenameDialog(DeviceLocation device) {
    final controller = TextEditingController(text: device.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renombrar Dispositivo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Dispositivo: ${device.id}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Nuevo nombre',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                // Guardar el nuevo nombre en SharedPreferences
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString(device.id, controller.text);
                
                widget.onDeviceRenamed(device.id, controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Dispositivo renombrado a "${controller.text}"')),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispositivos Cercanos'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoCard(
              title: 'Información de Conexión',
              icon: Icons.info,
              children: [
                _InfoRow('Tipo de Conexión', widget.connectionType),
                if (widget.connectedDevice != null)
                  _InfoRow('Dispositivo Conectado', widget.connectedDevice!.platformName)
                else
                  _InfoRow('Estado', 'No conectado'),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Dispositivos Encontrados (${widget.nearbyDevices.length})',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: widget.nearbyDevices.length,
                itemBuilder: (context, index) {
                  final device = widget.nearbyDevices[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: device.isOnline ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.device_hub,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(device.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ID: ${device.id}'),
                          Text('Piso: ${device.floor}'),
                          Text('Estado: ${device.isOnline ? "Online" : "Offline"}'),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'rename') {
                            _showRenameDialog(device);
                          } else if (value == 'navigate') {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Navegando a ${device.name}')),
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'rename',
                            child: Row(
                              children: [
                                Icon(Icons.edit),
                                SizedBox(width: 8),
                                Text('Renombrar'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'navigate',
                            child: Row(
                              children: [
                                Icon(Icons.navigation),
                                SizedBox(width: 8),
                                Text('Navegar'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Página de navegación
class _NavigationPage extends StatelessWidget {
  final Position? currentPosition;
  final List<DeviceLocation> nearbyDevices;
  final VoidCallback onCenterLocation;

  const _NavigationPage({
    required this.currentPosition,
    required this.nearbyDevices,
    required this.onCenterLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navegación'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoCard(
              title: 'Controles de Navegación',
              icon: Icons.navigation,
              children: [
                const Text('Utiliza estos controles para navegar por el mapa'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      onCenterLocation();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.my_location),
                    label: const Text('Centrar en mi ubicación'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Destinos Disponibles',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: nearbyDevices.length,
                itemBuilder: (context, index) {
                  final device = nearbyDevices[index];
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.location_pin,
                        color: device.isOnline ? Colors.green : Colors.red,
                      ),
                      title: Text(device.name),
                      subtitle: Text('Piso ${device.floor}'),
                      trailing: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Navegando a ${device.name}')),
                          );
                        },
                        child: const Text('Ir'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget helper para tarjetas de información
class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

// Widget helper para filas de información
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }


}

// Widget para las opciones del mapa
class _MapTypeOption extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _MapTypeOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : null,
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Theme.of(context).colorScheme.primary : null,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}

// Widget para los botones del menú inferior
class _BottomMenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomMenuButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), // Reducido padding
        constraints: const BoxConstraints(minHeight: 50), // Altura mínima fija
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20, // Reducido de 24 a 20
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 2), // Reducido de 4 a 2
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10, // Reducido de 12 a 10
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
