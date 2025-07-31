import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_thingy_91x/models/sensor_data.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:provider/provider.dart';
import '../../providers/mqtt_provider.dart';

/// Unified Motion Sensor Screen for BMI270 sensor data visualization
/// Supports both BLE and MQTT connections with modern UI design
class UnifiedMotionSensorScreen extends StatefulWidget {
  final String connectionType; // 'BLE' or 'MQTT'
  final BluetoothDevice? connectedDevice; // For BLE connection

  const UnifiedMotionSensorScreen({
    super.key,
    required this.connectionType,
    this.connectedDevice,
  });

  @override
  State<UnifiedMotionSensorScreen> createState() =>
      _UnifiedMotionSensorScreenState();
}

class _UnifiedMotionSensorScreenState extends State<UnifiedMotionSensorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isConnected = false;
  String _connectionStatus = 'Checking connection...';
  bool _isInitialized = false;
  bool _isStreamingMotion = false;
  bool _isLoading = false;
  
  // BLE Motion sensor characteristics
  BluetoothCharacteristic? _motionRequestCharacteristic;
  BluetoothCharacteristic? _motionControlCharacteristic;
  
  // Motion data
  ThreeAxisData? _accelerometerData;
  ThreeAxisData? _gyroscopeData;
  DateTime? _lastUpdateTime;
  int _dataUpdateCount = 0;
  Timer? _updateTimer;
  
  // Data timing management for irregular sensor updates (500ms - 10s)
  DateTime? _lastDataReceived;
  Timer? _dataTimeoutTimer;
  bool _isDataFresh = false;
  static const Duration _dataTimeoutDuration = Duration(seconds: 15); // Consider data stale after 15s
  static const Duration _fastUpdateThreshold = Duration(seconds: 1); // Fast updates under 1s
  static const Duration _slowUpdateThreshold = Duration(seconds: 5); // Slow updates over 5s
  
  // Connection health monitoring
  String _dataTimingStatus = 'Waiting for data...';
  Color _dataTimingColor = Colors.grey;
  DateTime? _lastBme680NotificationTime;
  
  // 3D Model orientation
  double _xRotation = 0;
  double _yRotation = 0;
  double _zRotation = 0;
  DateTime? _lastOrientationUpdate;
  
  // Data history for visualization
  final List<ThreeAxisData> _accelerometerHistory = [];
  final List<ThreeAxisData> _gyroscopeHistory = [];
  static const int _maxHistoryLength = 50;
  
  // Buffer for accumulating incoming data
  String _dataBuffer = '';
  
  // Localization helper methods
  String _getLocalizedText(String englishText, String spanishText) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'es') {
      return spanishText;
    }
    return englishText;
  }
  
  // BMI270 Service UUIDs (from C firmware analysis)
  static const String BMI270_SERVICE_UUID = "12345678-1234-5678-1234-56789abcdef2";
  static const String BMI270_REQUEST_CHAR_UUID = "12345678-1234-5678-1234-56789abcdef3";
  static const String BMI270_DATA_CHAR_UUID = "12345678-1234-5678-1234-56789abcdef4";
  static const String BMI270_CONTROL_CHAR_UUID = "12345678-1234-5678-1234-56789abcdef5";

  // Nordic UART Service UUIDs (actual service from device logs)
  static const String NORDIC_UART_SERVICE_UUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
  static const String NORDIC_UART_TX_CHAR_UUID = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";
  static const String NORDIC_UART_RX_CHAR_UUID = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";

  Timer? _testDataTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkConnectionStatus();
    
    // Initialize based on connection type
    if (widget.connectionType == 'BLE') {
      _initializeBleMotionSensor();
    } else if (widget.connectionType == 'MQTT') {
      _initializeMqttConnection();
    }
    
    // Auto-start BMI270 streaming when widget is entered
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _isInitialized) {
        _sendBMI270StartCommand();
      }
    });
  }

  @override
  void dispose() {
    _stopMotionStream();
    _updateTimer?.cancel();
    _testDataTimer?.cancel();
    _dataTimeoutTimer?.cancel(); // Cancel data timeout timer
    _tabController.dispose();
    super.dispose();
  }

  // Data timing management methods for irregular sensor updates
  void _onNewDataReceived() {
    final now = DateTime.now();
    final previousDataTime = _lastDataReceived;
    _lastDataReceived = now;
    _isDataFresh = true;

    // Calculate time since last data
    if (previousDataTime != null) {
      final timeSinceLastData = now.difference(previousDataTime);
      _updateDataTimingStatus(timeSinceLastData);
    } else {
      _updateDataTimingStatus(Duration.zero);
    }

    // Reset data timeout timer
    _startDataTimeoutTimer();
  }

  void _updateDataTimingStatus(Duration timeSinceLastData) {
    if (mounted) {
      setState(() {
        if (timeSinceLastData <= _fastUpdateThreshold) {
          _dataTimingStatus = _getLocalizedText(
            'Fast updates (${timeSinceLastData.inMilliseconds}ms)',
            'Actualizaciones rápidas (${timeSinceLastData.inMilliseconds}ms)'
          );
          _dataTimingColor = Colors.green;
        } else if (timeSinceLastData <= _slowUpdateThreshold) {
          _dataTimingStatus = _getLocalizedText(
            'Normal updates (${timeSinceLastData.inSeconds}s)',
            'Actualizaciones normales (${timeSinceLastData.inSeconds}s)'
          );
          _dataTimingColor = Colors.orange;
        } else {
          _dataTimingStatus = _getLocalizedText(
            'Slow updates (${timeSinceLastData.inSeconds}s)',
            'Actualizaciones lentas (${timeSinceLastData.inSeconds}s)'
          );
          _dataTimingColor = Colors.red;
        }
      });
    }
  }

  void _startDataTimeoutTimer() {
    _dataTimeoutTimer?.cancel();
    _dataTimeoutTimer = Timer(_dataTimeoutDuration, () {
      if (mounted) {
        setState(() {
          _isDataFresh = false;
          _dataTimingStatus = _getLocalizedText(
            'Data timeout (>15s)',
            'Datos sin actualizar (>15s)'
          );
          _dataTimingColor = Colors.grey;
        });
      }
    });
  }

  void _checkConnectionStatus() {
    if (widget.connectionType == 'BLE' && widget.connectedDevice != null) {
      setState(() {
        _isConnected = true;
        _connectionStatus = 'BLE Connected to ${widget.connectedDevice!.platformName}';
      });
    } else if (widget.connectionType == 'MQTT') {
      final mqttProvider = Provider.of<MQTTProvider>(context, listen: false);
      setState(() {
        _isConnected = mqttProvider.isConnected;
        _connectionStatus = _isConnected ? 'MQTT Connected' : 'MQTT Disconnected';
      });
    } else {
      setState(() {
        _isConnected = false;
        _connectionStatus = 'No connection available';
      });
    }
  }

  Future<void> _initializeMqttConnection() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _connectionStatus = 'Connecting to MQTT motion sensor...';
      });
    }
    
    try {
      // Verificar conexión MQTT
      final mqttProvider = Provider.of<MQTTProvider>(context, listen: false);
      if (!mqttProvider.isConnected) {
        throw Exception('MQTT not connected');
      }
      
      // Configurar callback para datos del BMI270
      mqttProvider.setBMI270DataCallback((String data) {
        debugPrint('📡 MQTT BMI270 data received: $data');
        _onMqttMotionDataReceived(data);
      });
      
      if (mounted) {
        setState(() {
          _connectionStatus = 'MQTT motion sensor connected';
          _isConnected = true;
          _isInitialized = true;
          _isLoading = false;
        });
      }
      
      // Auto-start motion streaming
      _startMotionStream();
      
    } catch (e) {
      debugPrint('❌ Error initializing MQTT: $e');
      if (mounted) {
        setState(() {
          _connectionStatus = 'MQTT connection failed: ${e.toString()}';
          _isConnected = false;
          _isLoading = false;
        });
      }
      _showSnackBar('MQTT connection error: ${e.toString()}', Colors.red);
    }
  }
  
  void _onMqttMotionDataReceived(String data) {
    debugPrint('📡 Processing MQTT motion data: $data');
    
    // Process each line directly (MQTT usually sends complete messages)
    List<String> lines = data.split('\n');
    for (String line in lines) {
      if (line.trim().isNotEmpty) {
        _parseNordicLogData(line.trim());
      }
    }
  }

  Future<void> _initializeBleMotionSensor() async {
    if (widget.connectedDevice == null) {
      if (mounted) {
        setState(() {
          _connectionStatus = 'No BLE device provided';
          _isConnected = false;
        });
      }
      _showSnackBar('No BLE device available', Colors.red);
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _connectionStatus = 'Initializing BMI270 sensor...';
      });
    }

    debugPrint('################################################');
    debugPrint('🚀 INITIALIZING BMI270 MOTION SENSOR');
    debugPrint('📱 Device: ${widget.connectedDevice!.platformName}');
    debugPrint('🔗 Address: ${widget.connectedDevice!.remoteId}');
    debugPrint('################################################');

    try {
      // Check if device is still connected
      final connectionState = await widget.connectedDevice!.connectionState.first;
      if (connectionState != BluetoothConnectionState.connected) {
        throw Exception('Device is not connected');
      }

      // Wait for connection to stabilize
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Verificar si el widget sigue montado antes de continuar
      if (!mounted) return;
      
      // Discover services with timeout
      List<BluetoothService> services = await widget.connectedDevice!
          .discoverServices()
          .timeout(const Duration(seconds: 10));
      
      debugPrint('✅ Discovered ${services.length} services');
      
      bool foundMotionService = false;
      
      // Search for both Nordic UART Service and BMI270 Service
      bool foundUartService = false;
      
      for (BluetoothService service in services) {
        // Verificar si el widget sigue montado en cada iteración
        if (!mounted) return;
        
        String serviceUuid = service.uuid.toString().toLowerCase();
        debugPrint('📋 Checking service: $serviceUuid');
        
        if (serviceUuid == NORDIC_UART_SERVICE_UUID.toLowerCase()) {
          debugPrint('🎯 Nordic UART Service found! This is where sensor data comes from.');
          foundUartService = await _setupUartCharacteristics(service);
        } else if (serviceUuid == BMI270_SERVICE_UUID.toLowerCase()) {
          debugPrint('🎯 BMI270 Motion Service found!');
          await _setupMotionCharacteristics(service); // Setup but don't depend on this service
        }
      }
      
      // We need at least UART service for data reception
      foundMotionService = foundUartService;

      if (mounted) {
        setState(() {
          _isInitialized = foundMotionService;
          _isLoading = false;
          _connectionStatus = foundMotionService 
              ? 'Nordic UART Ready - BMI270 data via UART stream'
              : 'Compatible UART service not found';
        });
      }

      if (foundMotionService) {
        debugPrint('################################################');
        debugPrint('✅ NORDIC UART SERVICE INITIALIZATION COMPLETE!');
        debugPrint('🎯 Ready to receive BMI270 data via UART stream');
        debugPrint('📡 Data arrives automatically - no commands needed');
        debugPrint('################################################');
        _showSnackBar('Nordic UART connected - BMI270 data incoming', Colors.green);
        
        // Auto-start motion streaming after successful initialization
        debugPrint('🚀 Auto-starting motion data stream...');
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _isInitialized) {
            _startMotionStream();
          }
        });
        
      } else {
        debugPrint('❌ Nordic UART Service not found on device');
        _showSnackBar('Compatible UART service not available on this device', Colors.orange);
      }

    } catch (e) {
      debugPrint('################################################');
      debugPrint('❌ CRITICAL ERROR in BMI270 initialization: $e');
      debugPrint('################################################');
      
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _isLoading = false;
          _connectionStatus = 'Initialization failed: ${e.toString()}';
        });
      }
      
      _showSnackBar('Failed to initialize motion sensor: ${e.toString()}', Colors.red);
    }
  }

  Future<bool> _setupMotionCharacteristics(BluetoothService service) async {
    try {
      bool hasRequestChar = false;
      bool hasDataChar = false;
      bool hasControlChar = false;
      
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        // Verificar si el widget sigue montado
        if (!mounted) return false;
        
        String charUuid = characteristic.uuid.toString().toLowerCase();
        debugPrint('  🔧 Found characteristic: $charUuid');
        
        if (charUuid == BMI270_REQUEST_CHAR_UUID.toLowerCase()) {
          _motionRequestCharacteristic = characteristic;
          hasRequestChar = true;
          debugPrint('  ✅ Request characteristic configured');
          
        } else if (charUuid == BMI270_DATA_CHAR_UUID.toLowerCase()) {
          hasDataChar = true;
          debugPrint('  ✅ Data characteristic found');
          
          // Subscribe to notifications if supported
          if (characteristic.properties.notify) {
            await characteristic.setNotifyValue(true);
            characteristic.lastValueStream.listen(_onMotionDataReceived);
            debugPrint('  📡 Subscribed to motion data notifications');
          } else {
            debugPrint('  ⚠️ Data characteristic does not support notifications');
          }
          
        } else if (charUuid == BMI270_CONTROL_CHAR_UUID.toLowerCase()) {
          _motionControlCharacteristic = characteristic;
          hasControlChar = true;
          debugPrint('  ✅ Control characteristic configured');
        }
      }
      
      bool success = hasRequestChar && hasDataChar && hasControlChar;
      debugPrint('  📊 Characteristics setup: Request=$hasRequestChar, Data=$hasDataChar, Control=$hasControlChar');
      
      return success;
      
    } catch (e) {
      debugPrint('  ❌ Error setting up characteristics: $e');
      return false;
    }
  }

  Future<bool> _setupUartCharacteristics(BluetoothService service) async {
    try {
      bool hasRxChar = false;
      bool hasTxChar = false;
      
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        // Verificar si el widget sigue montado
        if (!mounted) return false;
        
        String charUuid = characteristic.uuid.toString().toLowerCase();
        debugPrint('  🔧 Found UART characteristic: $charUuid');
        
        if (charUuid == NORDIC_UART_RX_CHAR_UUID.toLowerCase()) {
          hasRxChar = true;
          debugPrint('  ✅ UART RX characteristic found (this is where BMI270 data comes from)');
          
          // Subscribe to notifications if supported
          if (characteristic.properties.notify) {
            await characteristic.setNotifyValue(true);
            characteristic.lastValueStream.listen(_onMotionDataReceived);
            debugPrint('  📡 Subscribed to UART RX notifications for BMI270 data');
          } else {
            debugPrint('  ⚠️ UART RX characteristic does not support notifications');
          }
          
        } else if (charUuid == NORDIC_UART_TX_CHAR_UUID.toLowerCase()) {
          _motionRequestCharacteristic = characteristic;
          _motionControlCharacteristic = characteristic; // Use TX for commands
          hasTxChar = true;
          debugPrint('  ✅ UART TX characteristic configured for commands');
        }
      }
      
      bool success = hasRxChar; // We at least need RX for data
      debugPrint('  📊 UART characteristics setup: RX=$hasRxChar, TX=$hasTxChar');
      
      return success;
      
    } catch (e) {
      debugPrint('  ❌ Error setting up UART characteristics: $e');
      return false;
    }
  }

  void _onMotionDataReceived(List<int> data) {
    try {
      String rawString = String.fromCharCodes(data);
      debugPrint('📡 Raw motion data received (${data.length} bytes): "$rawString"');
      
      // Add to buffer to handle fragmented data
      _dataBuffer += rawString;
      
      // Process complete lines in the buffer
      List<String> lines = _dataBuffer.split('\n');
      
      // Keep the last incomplete line in the buffer
      if (lines.isNotEmpty && !_dataBuffer.endsWith('\n')) {
        _dataBuffer = lines.removeLast();
      } else {
        _dataBuffer = '';
      }
      
      // Process each complete line
      for (String line in lines) {
        if (line.trim().isNotEmpty) {
          debugPrint('📝 Processing line: "$line"');
          _parseNordicLogData(line);
        }
      }
      
      // Notify new data reception
      _onNewDataReceived();
      
    } catch (e) {
      debugPrint('❌ Error parsing motion data: $e');
      debugPrint('📝 Raw data bytes: $data');
      _showSnackBar('Error parsing motion data: ${e.toString()}', Colors.red);
    }
  }

  void _parseNordicLogData(String logData) {
    try {
      // Remove ANSI escape sequences and clean the log data
      String cleanedData = logData.replaceAll(RegExp(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])'), '');
      cleanedData = cleanedData.replaceAll(RegExp(r'[\^]\[\[.*?\]'), ''); // Remove Nordic log prefixes
      cleanedData = cleanedData.replaceAll(RegExp(r'\[.*?\]'), ''); // Remove timestamps and log levels
      cleanedData = cleanedData.trim();
      
      debugPrint('🧹 Cleaned log data: "$cleanedData"');
      
      // Look for BMI270 ACCEL data pattern with more flexible regex
      // Examples: "BMI270 ACCEL: X=0.026, Y=-0.107, Z=9.904 m/s²"
      //           "-> BMI270 ACCEL: X=0.280130, Y=0.-122108, Z=9.888354 m/s²"
      RegExp accelRegex = RegExp(r'BMI270 ACCEL:\s*X=([^,]+),\s*Y=([^,]+),\s*Z=([^\s,m]+)', caseSensitive: false);
      RegExp gyroRegex = RegExp(r'BMI270 GYRO:\s*X=([^,]+),\s*Y=([^,]+),\s*Z=([^\s,r]+)', caseSensitive: false);
      
      // Also check for BME680 data (temperature sensor) to provide feedback
      RegExp bme680Regex = RegExp(r'BME680 TEMP:\s*([^°]+)°C,\s*HUMID:\s*([^%]+)%RH', caseSensitive: false);
      
      var accelMatch = accelRegex.firstMatch(cleanedData);
      var gyroMatch = gyroRegex.firstMatch(cleanedData);
      var bme680Match = bme680Regex.firstMatch(cleanedData);
      
      // Handle BME680 data (provide user feedback)
      if (bme680Match != null) {
        String temp = bme680Match.group(1)!.trim();
        String humid = bme680Match.group(2)!.trim();
        debugPrint('🌡️ BME680 data detected: TEMP=${temp}°C, HUMID=${humid}%RH');
        
        // Update connection status to show that we're getting data but not motion data
        if (mounted) {
          setState(() {
            _connectionStatus = 'Connected - Receiving BME680 data (Temp: ${temp}°C, Humid: ${humid}%)';
            _lastUpdateTime = DateTime.now();
          });
        }
        
        // Show user feedback every 10 seconds to avoid spam
        if (_lastBme680NotificationTime == null || 
            DateTime.now().difference(_lastBme680NotificationTime!) > const Duration(seconds: 10)) {
          _lastBme680NotificationTime = DateTime.now();
          _showSnackBar('BME680 data received. Try sending motion commands to activate BMI270.', Colors.blue);
        }
        return; // Exit early for BME680 data
      }
      
      if (accelMatch != null || gyroMatch != null) {
        debugPrint('🎯 Found BMI270 sensor data in cleaned log: $cleanedData');
        
        Map<String, dynamic> motionData = {
          'sensor': 'BMI270',
          'accel': null,
          'gyro': null,
        };
        
        // Extract accelerometer data if present
        if (accelMatch != null) {
          try {
            String xStr = _cleanNumberString(accelMatch.group(1)!);
            String yStr = _cleanNumberString(accelMatch.group(2)!);
            String zStr = _cleanNumberString(accelMatch.group(3)!);
            
            double accelX = double.parse(xStr);
            double accelY = double.parse(yStr);
            double accelZ = double.parse(zStr);
            
            motionData['accel'] = {
              'x': accelX,
              'y': accelY,
              'z': accelZ,
            };
            
            debugPrint('📊 Parsed ACCEL: X=$accelX, Y=$accelY, Z=$accelZ');
          } catch (e) {
            debugPrint('❌ Error parsing accel values: $e');
            debugPrint('Raw accel groups: X="${accelMatch.group(1)}", Y="${accelMatch.group(2)}", Z="${accelMatch.group(3)}"');
          }
        }
        
        // Extract gyroscope data if present
        if (gyroMatch != null) {
          try {
            String xStr = _cleanNumberString(gyroMatch.group(1)!);
            String yStr = _cleanNumberString(gyroMatch.group(2)!);
            String zStr = _cleanNumberString(gyroMatch.group(3)!);
            
            double gyroX = double.parse(xStr);
            double gyroY = double.parse(yStr);
            double gyroZ = double.parse(zStr);
            
            motionData['gyro'] = {
              'x': gyroX,
              'y': gyroY,
              'z': gyroZ,
            };
            
            debugPrint('🔄 Parsed GYRO: X=$gyroX, Y=$gyroY, Z=$gyroZ');
          } catch (e) {
            debugPrint('❌ Error parsing gyro values: $e');
            debugPrint('Raw gyro groups: X="${gyroMatch.group(1)}", Y="${gyroMatch.group(2)}", Z="${gyroMatch.group(3)}"');
          }
        }
        
        // Process the data (even if only accel or gyro is present)
        if (motionData['accel'] != null || motionData['gyro'] != null) {
          _processPartialMotionData(motionData);
        }
        
      } else {
        // Only log if the line seems to contain BMI270 data but wasn't parsed
        if (cleanedData.toUpperCase().contains('BMI270')) {
          debugPrint('⚠️ BMI270 data found but not parsed: "$cleanedData"');
        }
      }
      
    } catch (e) {
      debugPrint('❌ Error parsing Nordic log data: $e');
      debugPrint('📝 Original log data: $logData');
    }
  }

  String _cleanNumberString(String value) {
    // Clean up malformed number strings like "0.-122108" -> "-0.122108"
    value = value.trim();
    
    debugPrint('🧹 Cleaning number string: "$value"');
    
    // Fix numbers like "0.-123" to "-0.123"
    if (value.contains('0.-')) {
      String cleanValue = value.replaceAll('0.-', '-0.');
      debugPrint('🔧 Fixed "0.-" pattern: "$value" -> "$cleanValue"');
      value = cleanValue;
    }
    
    // Fix other malformed patterns
    value = value.replaceAll(RegExp(r'^0\.(-\d+)'), r'-0.$1');
    
    // Remove any trailing non-numeric characters (like units)
    value = value.replaceAll(RegExp(r'[^\d\.\-\+eE].*$'), '');
    
    debugPrint('🧹 Cleaned number: "$value"');
    return value;
  }

  void _processPartialMotionData(Map<String, dynamic> motionData) {
    try {
      // Verificar si el widget sigue montado antes de procesar los datos
      if (!mounted) {
        debugPrint('⚠️ Widget not mounted, skipping data update');
        return;
      }
      
      debugPrint('🔍 Processing partial motion data: accel=${motionData['accel'] != null}, gyro=${motionData['gyro'] != null}');
      
      DateTime now = DateTime.now();
      bool shouldUpdate = false;
      
      // Track when new data arrives for timing analysis
      _onNewDataReceived();
      
      // Update accelerometer data if present
      if (motionData['accel'] != null) {
        Map<String, dynamic> accel = motionData['accel'];
        _accelerometerData = ThreeAxisData(
          x: (accel['x'] as num).toDouble(),
          y: (accel['y'] as num).toDouble(),
          z: (accel['z'] as num).toDouble(),
          timestamp: now,
        );
        shouldUpdate = true;
        debugPrint('📊 Updated accel data: X=${_accelerometerData!.x}, Y=${_accelerometerData!.y}, Z=${_accelerometerData!.z}');
      }
      
      // Update gyroscope data if present
      if (motionData['gyro'] != null) {
        Map<String, dynamic> gyro = motionData['gyro'];
        _gyroscopeData = ThreeAxisData(
          x: (gyro['x'] as num).toDouble(),
          y: (gyro['y'] as num).toDouble(),
          z: (gyro['z'] as num).toDouble(),
          timestamp: now,
        );
        shouldUpdate = true;
        debugPrint('🔄 Updated gyro data: X=${_gyroscopeData!.x}, Y=${_gyroscopeData!.y}, Z=${_gyroscopeData!.z}');
      }
      
      if (shouldUpdate && mounted) {
        debugPrint('🔄 Calling setState to update UI...');
        setState(() {
          _lastUpdateTime = now;
          _dataUpdateCount++;
          
          // Add to history for visualization
          if (_accelerometerData != null) {
            _accelerometerHistory.add(_accelerometerData!);
            if (_accelerometerHistory.length > _maxHistoryLength) {
              _accelerometerHistory.removeAt(0);
            }
          }
          
          if (_gyroscopeData != null) {
            _gyroscopeHistory.add(_gyroscopeData!);
            if (_gyroscopeHistory.length > _maxHistoryLength) {
              _gyroscopeHistory.removeAt(0);
            }
          }
        });
        
        debugPrint('✅ UI updated with motion data (count: $_dataUpdateCount)');
        debugPrint('📊 Current data state: Accel=${_accelerometerData != null ? "✓" : "✗"}, Gyro=${_gyroscopeData != null ? "✓" : "✗"}');
        _updateModel3DOrientation();
      } else if (!shouldUpdate) {
        debugPrint('⚠️ No data to update');
      } else if (!mounted) {
        debugPrint('⚠️ Widget not mounted during setState');
      }
      
      // Log periodically to avoid spam
      if (_dataUpdateCount % 5 == 0) {
        debugPrint('📈 Motion data stats: ${_dataUpdateCount} total updates, accel points: ${_accelerometerHistory.length}, gyro points: ${_gyroscopeHistory.length}');
      }
      
    } catch (e) {
      debugPrint('❌ Error processing partial motion data: $e');
      debugPrint('📝 Motion data: $motionData');
    }
  }

  void _updateModel3DOrientation() {
    if (_gyroscopeData == null) return;
    
    final now = DateTime.now();
    final dt = _lastOrientationUpdate != null
        ? now.difference(_lastOrientationUpdate!).inMilliseconds / 1000.0
        : 0.016; // Default to ~60fps
    
    // Handle variable timing: 500ms to 10s between updates
    // Clamp dt to reasonable bounds to avoid orientation jumps
    double clampedDt = dt;
    if (dt > 10.0) {
      // If more than 10 seconds, assume sensor was offline - don't integrate
      debugPrint('⚠️ Large time gap detected (${dt.toStringAsFixed(1)}s) - skipping orientation update');
      _lastOrientationUpdate = now;
      return;
    } else if (dt > 1.0) {
      // For gaps > 1s, use smaller integration steps to avoid jumps
      clampedDt = 1.0;
      debugPrint('🔄 Large time delta (${dt.toStringAsFixed(1)}s) - clamping to 1s for stability');
    }
    
    if (clampedDt > 0 && clampedDt <= 1.0) {
      // Integrate gyroscope data to get orientation (convert rad/s to deg/s)
      const double radToDeg = 57.2958;
      
      // Adaptive smoothing factor based on timing
      double smoothingFactor;
      if (dt <= 1.0) {
        // Fast updates: normal smoothing
        smoothingFactor = 0.8;
      } else if (dt <= 5.0) {
        // Medium updates: more smoothing
        smoothingFactor = 0.6;
      } else {
        // Slow updates: heavy smoothing
        smoothingFactor = 0.4;
      }
      
      double deltaX = _gyroscopeData!.x * clampedDt * radToDeg * smoothingFactor;
      double deltaY = _gyroscopeData!.y * clampedDt * radToDeg * smoothingFactor;
      double deltaZ = _gyroscopeData!.z * clampedDt * radToDeg * smoothingFactor;
      
      _xRotation += deltaX;
      _yRotation += deltaY;
      _zRotation += deltaZ;
      
      // Keep angles in reasonable range [-180, 180] for better visualization
      _xRotation = (_xRotation + 180) % 360 - 180;
      _yRotation = (_yRotation + 180) % 360 - 180;
      _zRotation = (_zRotation + 180) % 360 - 180;
      
      // Trigger UI update - for slow updates, always update to show new data
      bool shouldUpdateUI = dt > 1.0 || // Always update for slow data
                          (deltaX.abs() > 0.1) || (deltaY.abs() > 0.1) || (deltaZ.abs() > 0.1);
      
      if (shouldUpdateUI && mounted) {
        setState(() {}); // Trigger rebuild to update ModelViewer
      }
    }
    
    _lastOrientationUpdate = now;
  }

  Future<void> _requestSingleReading() async {
    if (!_isInitialized) {
      _showSnackBar('Motion sensor not initialized', Colors.red);
      return;
    }
    
    if (widget.connectionType == 'BLE' && _motionRequestCharacteristic == null) {
      _showSnackBar('BLE characteristic not available', Colors.red);
      return;
    }

    try {
      if (mounted) {
        setState(() => _isLoading = true);
      }
      
      if (widget.connectionType == 'BLE') {
        debugPrint('📖 Requesting single BMI270 reading via BLE...');
        String command = 'bmi270\n';
        await _motionRequestCharacteristic!.write(command.codeUnits);
        _showSnackBar('BMI270 data requested', Colors.blue);
      } else if (widget.connectionType == 'MQTT') {
        // For MQTT, we would typically send a command via the MQTT provider
        debugPrint('📖 Requesting single motion reading via MQTT...');
        _showSnackBar('MQTT single read requested', Colors.blue);
      }
      
    } catch (e) {
      debugPrint('❌ Error requesting motion data: $e');
      _showSnackBar('Error requesting data: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _startMotionStream() async {
    if (!_isInitialized) {
      _showSnackBar('Motion sensor not initialized', Colors.red);
      return;
    }

    try {
      if (mounted) {
        setState(() => _isLoading = true);
      }
      
      if (widget.connectionType == 'BLE') {
        debugPrint('🚀 Starting motion data stream via BLE (UART)...');
        
        // For Nordic UART, try sending different BMI270 commands
        if (_motionControlCharacteristic != null) {
          try {
            // Try multiple command variations to activate BMI270
            List<String> commands = [
              'bmi270\n',
              'motion\n',
              'accel\n',
              'imu\n',
              'sensor motion\n',
              'start bmi270\n'
            ];
            
            debugPrint('🚀 Trying multiple BMI270 activation commands...');
            for (String command in commands) {
              debugPrint('  📤 Sending: "$command"');
              await _motionControlCharacteristic!.write(command.codeUnits);
              await Future.delayed(const Duration(milliseconds: 200)); // Small delay between commands
            }
            debugPrint('✅ All BMI270 activation commands sent');
          } catch (e) {
            debugPrint('⚠️ Could not send BMI270 commands (data might come automatically): $e');
          }
        }
        
        // Start update timer for real-time updates
        _updateTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
          if (mounted) setState(() {}); // Trigger UI updates
        });
        
      } else if (widget.connectionType == 'MQTT') {
        debugPrint('🚀 Starting motion data stream via MQTT...');
        // For MQTT, we would typically start listening to motion topics
      }
      
      if (mounted) {
        setState(() {
          _isStreamingMotion = true;
          _dataUpdateCount = 0; // Reset counter
        });
      }
      
      _showSnackBar('Motion streaming started - data should arrive automatically', Colors.green);
      
    } catch (e) {
      debugPrint('❌ Error starting motion stream: $e');
      _showSnackBar('Error starting stream: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Sends the BMI270 start command (0x01) to begin sensor streaming
  Future<void> _sendBMI270StartCommand() async {
    if (widget.connectionType != 'BLE') {
      debugPrint('⚠️ BMI270 start command only supported for BLE connections');
      return;
    }

    if (!_isConnected || !_isInitialized) {
      debugPrint('⚠️ Cannot send BMI270 command: device not connected or initialized');
      return;
    }

    try {
      if (_motionControlCharacteristic != null) {
        // Try multiple command variations to activate BMI270
        List<String> commands = [
          'bmi270\n',
          'motion\n',
          'accel\n',
          'imu\n',
          'sensor motion\n',
          'start bmi270\n'
        ];
        
        debugPrint('🚀 Sending multiple BMI270 activation commands to nRF53...');
        for (String command in commands) {
          debugPrint('  📤 Sending: "$command"');
          await _motionControlCharacteristic!.write(command.codeUnits);
          await Future.delayed(const Duration(milliseconds: 200)); // Small delay between commands
        }
        debugPrint('✅ All BMI270 activation commands sent successfully');
        _showSnackBar(_getLocalizedText(
          'BMI270 activation commands sent', 
          'Comandos de activación BMI270 enviados'
        ), Colors.green);
      } else {
        debugPrint('❌ Motion control characteristic not available');
        _showSnackBar(_getLocalizedText(
          'BMI270 control not available', 
          'Control BMI270 no disponible'
        ), Colors.orange);
      }
    } catch (e) {
      debugPrint('❌ Error sending BMI270 start commands: $e');
      _showSnackBar(_getLocalizedText(
        'Failed to start BMI270: ${e.toString()}',
        'Error al iniciar BMI270: ${e.toString()}'
      ), Colors.red);
    }
  }

  Future<void> _stopMotionStream() async {
    try {
      if (widget.connectionType == 'BLE' && _motionControlCharacteristic != null) {
        debugPrint('🛑 Stopping motion data stream via BLE...');
        await _motionControlCharacteristic!.write([0x00]); // STOP
      } else if (widget.connectionType == 'MQTT') {
        debugPrint('🛑 Stopping motion data stream via MQTT...');
        // For MQTT, we would stop listening to motion topics
      }
      
      _updateTimer?.cancel();
      _updateTimer = null;
      
      if (mounted) {
        setState(() {
          _isStreamingMotion = false;
        });
      }
      
      _showSnackBar('Motion streaming stopped', Colors.orange);
      
    } catch (e) {
      debugPrint('❌ Error stopping motion stream: $e');
      _showSnackBar('Error stopping stream', Colors.red);
    }
  }

  void _resetOrientation() {
    if (mounted) {
      setState(() {
        _xRotation = 0;
        _yRotation = 0;
        _zRotation = 0;
        _lastOrientationUpdate = null;
      });
    }
    _showSnackBar('3D model orientation reset', Colors.blue);
  }

  void _clearData() {
    if (mounted) {
      setState(() {
        _accelerometerData = null;
        _gyroscopeData = null;
        _lastUpdateTime = null;
        _dataUpdateCount = 0;
        _accelerometerHistory.clear();
        _gyroscopeHistory.clear();
      });
    }
    _showSnackBar('Motion data cleared', Colors.blue);
  }

  /// Método para generar datos de prueba y verificar que la UI funciona
  void _generateTestData() {
    debugPrint('🧪 Generating test motion data...');
    
    // Simular datos reales que estás recibiendo
    String testAccelData = "[00:00:27.655,609] <inf> nrf9151_led: -> BMI270 ACCEL: X=0.026, Y=-0.107, Z=9.904 m/s²";
    String testGyroData = "[00:00:27.155,578] <inf> nrf9151_led: -> BMI270 GYRO: X=-0.002, Y=0.007, Z=0.001 rad/s";
    
    debugPrint('🧪 Processing test accel data: $testAccelData');
    _parseNordicLogData(testAccelData);
    
    debugPrint('🧪 Processing test gyro data: $testGyroData');
    _parseNordicLogData(testGyroData);
    
    _showSnackBar('Test data generated', Colors.blue);
  }

  /// Iniciar generación continua de datos de prueba
  void _startTestDataStream() {
    if (_testDataTimer != null) return; // Ya está corriendo
    
    debugPrint('🧪 Starting continuous test data stream with realistic BMI270 data...');
    
    int counter = 0;
    _testDataTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        counter++;
        
        // Generar datos realistas similares a los que estás recibiendo
        double accelX = 0.026 + (counter % 10 - 5) * 0.001;
        double accelY = -0.107 + (counter % 7 - 3) * 0.002;
        double accelZ = 9.904 + (counter % 5 - 2) * 0.01;
        
        double gyroX = -0.002 + (counter % 8 - 4) * 0.0005;
        double gyroY = 0.007 + (counter % 6 - 3) * 0.001;
        double gyroZ = 0.001 + (counter % 4 - 2) * 0.0002;
        
        String testAccelData = "[00:00:${(counter % 60).toString().padLeft(2, '0')}.${(counter * 155 % 1000).toString().padLeft(3, '0')},578] <inf> nrf9151_led: -> BMI270 ACCEL: X=${accelX.toStringAsFixed(3)}, Y=${accelY.toStringAsFixed(3)}, Z=${accelZ.toStringAsFixed(3)} m/s²";
        String testGyroData = "[00:00:${(counter % 60).toString().padLeft(2, '0')}.${(counter * 255 % 1000).toString().padLeft(3, '0')},609] <inf> nrf9151_led: -> BMI270 GYRO: X=${gyroX.toStringAsFixed(3)}, Y=${gyroY.toStringAsFixed(3)}, Z=${gyroZ.toStringAsFixed(3)} rad/s";
        
        _parseNordicLogData(testAccelData);
        _parseNordicLogData(testGyroData);
      } else {
        timer.cancel();
      }
    });
    
    _showSnackBar('Test data stream started (realistic BMI270 data)', Colors.blue);
  }

  /// Detener generación de datos de prueba
  void _stopTestDataStream() {
    if (_testDataTimer != null) {
      _testDataTimer!.cancel();
      _testDataTimer = null;
      debugPrint('🧪 Test data stream stopped');
      _showSnackBar('Test data stream stopped', Colors.orange);
    }
  }

  void _showSnackBar(String message, Color color) {
    // Verificar que el widget esté montado y el contexto sea válido
    if (mounted && context.mounted) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: color,
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e) {
        // Si hay error al mostrar el snackbar, solo lo registramos en debug
        debugPrint('⚠️ Error showing snackbar: $e');
      }
    } else {
      // Si el widget no está montado, solo mostramos el mensaje en debug
      debugPrint('📱 SnackBar message (widget unmounted): $message');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(
              Icons.sensors,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _getLocalizedText(
                  'Motion Sensors (${widget.connectionType})',
                  'Sensores de Movimiento (${widget.connectionType})'
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          // Connection status indicator
          IconButton(
            icon: Icon(
              widget.connectionType == 'BLE' 
                ? (_isInitialized ? Icons.bluetooth_connected : Icons.bluetooth_disabled)
                : (_isConnected ? Icons.cloud_done : Icons.cloud_off),
              color: _isInitialized && _isConnected 
                ? Colors.lightGreenAccent 
                : Colors.redAccent,
            ),
            onPressed: _showConnectionInfo,
            tooltip: _getLocalizedText('Connection Status', 'Estado de Conexión'),
          ),
          
          // Stream control (BLE only)
          if (widget.connectionType == 'BLE' && _isInitialized) ...[
            IconButton(
              icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    _isStreamingMotion ? Icons.stop : Icons.play_arrow,
                    color: _isStreamingMotion ? Colors.orange : Colors.green,
                  ),
              onPressed: _isLoading 
                ? null 
                : (_isStreamingMotion ? _stopMotionStream : _startMotionStream),
              tooltip: _isStreamingMotion 
                ? _getLocalizedText('Stop Stream', 'Detener Stream')
                : _getLocalizedText('Start Stream', 'Iniciar Stream'),
            ),
            // BMI270 Activation Button
            IconButton(
              icon: const Icon(Icons.sensors, color: Colors.cyan),
              onPressed: _sendBMI270StartCommand,
              tooltip: _getLocalizedText('Activate BMI270', 'Activar BMI270'),
            ),
          ],
          
          // Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'reset':
                  _resetOrientation();
                  break;
                case 'clear':
                  _clearData();
                  break;
                case 'test':
                  _generateTestData();
                  break;
                case 'start_test_stream':
                  _startTestDataStream();
                  break;
                case 'stop_test_stream':
                  _stopTestDataStream();
                  break;
                case 'info':
                  _showDeviceInfo();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text(_getLocalizedText('Reset Orientation', 'Resetear Orientación')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, size: 20),
                    SizedBox(width: 8),
                    Text(_getLocalizedText('Clear Data', 'Limpiar Datos')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'test',
                child: Row(
                  children: [
                    Icon(Icons.science, size: 20),
                    SizedBox(width: 8),
                    Text(_getLocalizedText('Generate Test Data', 'Generar Datos de Prueba')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _testDataTimer == null ? 'start_test_stream' : 'stop_test_stream',
                child: Row(
                  children: [
                    Icon(_testDataTimer == null ? Icons.play_arrow : Icons.stop, size: 20),
                    SizedBox(width: 8),
                    Text(_testDataTimer == null 
                      ? _getLocalizedText('Start Test Stream', 'Iniciar Stream de Prueba')
                      : _getLocalizedText('Stop Test Stream', 'Detener Stream de Prueba')),
                  ],
                ),
              ),
              if (widget.connectionType == 'BLE')
                PopupMenuItem(
                  value: 'info',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 20),
                      SizedBox(width: 8),
                      Text(_getLocalizedText('Device Info', 'Info del Dispositivo')),
                    ],
                  ),
                ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              icon: Icon(Icons.dashboard),
              text: _getLocalizedText('Dashboard', 'Panel'),
            ),
            Tab(
              icon: Icon(Icons.threed_rotation),
              text: _getLocalizedText('3D Model', 'Modelo 3D'),
            ),
          ],
        ),
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
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildDashboardView(),
            _build3DModelView(),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardView() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          if (widget.connectionType == 'BLE') {
            await _requestSingleReading();
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Connection Status Card
            _buildConnectionStatusCard(),
            
            const SizedBox(height: 16),
            
            // Control Panel (BLE only)
            // if (widget.connectionType == 'BLE' && _isInitialized) ...[
            //   _buildControlPanel(),
            //   const SizedBox(height: 16),
            // ],
            
            // Motion Data Cards
            Row(
              children: [
                Expanded(
                  child: _buildMotionSensorCard(
                    'Accelerometer',
                    _accelerometerData,
                    'm/s²',
                    Icons.speed,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMotionSensorCard(
                    'Gyroscope',
                    _gyroscopeData,
                    'rad/s',
                    Icons.rotate_right,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Statistics Card
            _buildStatisticsCard(),
            
            const SizedBox(height: 16),
            
            // Data History Visualization (if available)
            if (_accelerometerHistory.isNotEmpty || _gyroscopeHistory.isNotEmpty)
              _buildDataHistoryCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              _isConnected && _isInitialized 
                ? Colors.green.withValues(alpha: 0.1) 
                : Colors.red.withValues(alpha: 0.1),
              Colors.transparent,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isConnected && _isInitialized 
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.red.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.connectionType == 'BLE' 
                    ? Icons.bluetooth 
                    : Icons.cloud,
                  color: _isConnected && _isInitialized ? Colors.green : Colors.red,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _connectionStatus,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _isConnected && _isInitialized ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'BMI270 Motion Sensor',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    if (_isStreamingMotion) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Streaming active',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (_isLoading)
                const CircularProgressIndicator(strokeWidth: 2)
              else if (widget.connectionType == 'BLE' && widget.connectedDevice != null)
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: _showDeviceInfo,
                  tooltip: _getLocalizedText('Device Information', 'Información del Dispositivo'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.control_camera,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Motion Control',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _requestSingleReading,
                    icon: _isLoading 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                    label: const Text('Single Read'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading 
                      ? null 
                      : (_isStreamingMotion ? _stopMotionStream : _startMotionStream),
                    icon: _isLoading 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(_isStreamingMotion ? Icons.stop : Icons.play_arrow),
                    label: Text(_isStreamingMotion ? 'Stop' : 'Start'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isStreamingMotion ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotionSensorCard(String title, ThreeAxisData? data, String unit, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              Colors.transparent,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (data == null)
                Container(
                  height: 80,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sensors_off, color: Colors.grey[400], size: 32),
                        const SizedBox(height: 8),
                        Text(
                          'No data',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    _buildAxisValue('X', data.x, unit, Colors.red),
                    const SizedBox(height: 8),
                    _buildAxisValue('Y', data.y, unit, Colors.green),
                    const SizedBox(height: 8),
                    _buildAxisValue('Z', data.z, unit, Colors.blue),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAxisValue(String axis, double value, String unit, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            axis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            '${value.toStringAsFixed(3)} $unit',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Statistics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Updates',
                    _dataUpdateCount.toString(),
                    Icons.update,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'History',
                    '${_accelerometerHistory.length}',
                    Icons.history,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Last Update',
                    _lastUpdateTime != null 
                      ? '${DateTime.now().difference(_lastUpdateTime!).inSeconds}s ago'
                      : 'Never',
                    Icons.access_time,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Data timing status
            Row(
              children: [
                Icon(
                  Icons.timer,
                  color: _dataTimingColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _dataTimingStatus,
                  style: TextStyle(
                    color: _dataTimingColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDataHistoryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timeline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Data History',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 120,
              child: Row(
                children: [
                  // Simple visualization placeholder
                  // In a real implementation, you could use a charting library
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'Motion data visualization\nwould appear here',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Show current data status and timing information
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Accel history: ${_accelerometerHistory.length}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Gyro history: ${_gyroscopeHistory.length}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Data timing status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _dataTimingColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _dataTimingColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    _isDataFresh ? Icons.timer : Icons.timer_off,
                    color: _dataTimingColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _dataTimingStatus,
                      style: TextStyle(
                        color: _dataTimingColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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

  Widget _build3DModelView() {
    return SafeArea(
      child: Column(
        children: [
          // Control Panel
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.threed_rotation,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '3D Model Orientation',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildOrientationValue('X', _xRotation, Colors.red),
                        _buildOrientationValue('Y', _yRotation, Colors.green),
                        _buildOrientationValue('Z', _zRotation, Colors.blue),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Data activity indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _dataUpdateCount > 0 ? Icons.sensors : Icons.sensors_off,
                          color: _dataUpdateCount > 0 ? Colors.green : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getLocalizedText(
                            'Data updates: $_dataUpdateCount',
                            'Actualizaciones: $_dataUpdateCount'
                          ),
                          style: TextStyle(
                            color: _dataUpdateCount > 0 ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Data timing status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _dataTimingColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _dataTimingColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isDataFresh ? Icons.schedule : Icons.schedule_outlined,
                            color: _dataTimingColor,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _dataTimingStatus,
                            style: TextStyle(
                              color: _dataTimingColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _resetOrientation,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset Orientation'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // 3D Model with overlay
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // 3D Model Viewer - Only controlled by sensor data
                    ModelViewer(
                      src: 'assets/3d/example/example.glb',
                      alt: 'A 3D model of the Thingy:91X device showing real-time orientation',
                      ar: false,
                      autoRotate: false,
                      autoPlay: false,
                      cameraControls: false, // Disable user interaction - only sensor control
                      disableZoom: true, // Disable zoom to prevent user interaction
                      backgroundColor: const Color(0xFF000000),
                      // Use cameraOrbit to control model rotation from sensor data
                      // Convert gyroscope angles to camera rotation
                      cameraOrbit: '${_yRotation.toStringAsFixed(1)}deg ${(90 - _xRotation).toStringAsFixed(1)}deg ${_zRotation.toStringAsFixed(1)}m',
                      // Disable automatic animations - only sensor-driven movement
                      animationName: '',
                    ),
                    // Data activity indicator overlay
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _dataUpdateCount > 0 
                              ? Colors.green.withValues(alpha: 0.8)
                              : Colors.grey.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _dataUpdateCount > 0 ? Icons.sensors : Icons.sensors_off,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getLocalizedText('LIVE', 'EN VIVO'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Orientation info overlay
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getLocalizedText('Orientation:', 'Orientación:'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'X: ${_xRotation.toStringAsFixed(1)}°',
                              style: const TextStyle(color: Colors.red, fontSize: 11, fontFamily: 'monospace'),
                            ),
                            Text(
                              'Y: ${_yRotation.toStringAsFixed(1)}°',
                              style: const TextStyle(color: Colors.green, fontSize: 11, fontFamily: 'monospace'),
                            ),
                            Text(
                              'Z: ${_zRotation.toStringAsFixed(1)}°',
                              style: const TextStyle(color: Colors.blue, fontSize: 11, fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildOrientationValue(String axis, double value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            axis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${value.toStringAsFixed(1)}°',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
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
              Text('Device: ${widget.connectedDevice!.platformName}'),
              Text('Address: ${widget.connectedDevice!.remoteId}'),
              const SizedBox(height: 16),
              const Text('BMI270 Motion Sensor:'),
              const Text('• Accelerometer (m/s²)'),
              const Text('• Gyroscope (rad/s)'),
              const Text('• Real-time 3D visualization'),
              if (_dataUpdateCount > 0) ...[
                const SizedBox(height: 8),
                Text('Data updates: $_dataUpdateCount'),
              ],
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
    String sensorStatus = 'Unknown';
    Color sensorStatusColor = Colors.grey;
    
    if (_accelerometerData != null || _gyroscopeData != null) {
      sensorStatus = 'BMI270 Motion Data Active';
      sensorStatusColor = Colors.green;
    } else if (_connectionStatus.contains('BME680')) {
      sensorStatus = 'BME680 Temperature Data Only';
      sensorStatusColor = Colors.orange;
    } else {
      sensorStatus = 'Waiting for Sensor Data';
      sensorStatusColor = Colors.grey;
    }
    
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
                Expanded(
                  child: Text(
                    _connectionStatus,
                    style: TextStyle(
                      color: _isConnected ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.sensors, color: sensorStatusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sensorStatus,
                    style: TextStyle(
                      color: sensorStatusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Expected Motion Sensor Features:'),
            const SizedBox(height: 8),
            const Text('• 3-axis accelerometer (BMI270)'),
            const Text('• 3-axis gyroscope (BMI270)'),
            const Text('• Real-time data streaming'),
            const Text('• 3D model visualization'),
            if (widget.connectionType == 'BLE') ...[
              const SizedBox(height: 8),
              const Text('BLE Commands Available:'),
              const Text('• Single read: Request one reading'),
              const Text('• Start/Stop: Control data streaming'),
              const Text('• BMI270 Activation: Send motion commands'),
            ],
            if (_dataUpdateCount > 0) ...[
              const SizedBox(height: 8),
              Text('Total updates: $_dataUpdateCount'),
              if (_isStreamingMotion) 
                const Text('Status: Streaming active'),
            ],
            if (_connectionStatus.contains('BME680')) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ℹ️ Note: Receiving BME680 data instead of BMI270',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text('Try pressing the BMI270 activation button to switch to motion data.'),
                  ],
                ),
              ),
            ],
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
