// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Thingy:91 X';

  @override
  String get homeTitle => 'Welcome to Thingy:91 X';

  @override
  String get homeSubtitle => 'Connect to your Nordic Thingy:91 X device';

  @override
  String get selectConnection => 'Select Connection Type';

  @override
  String get selectConnectionSubtitle =>
      'Choose how you want to connect to your device';

  @override
  String get bluetoothConnection => 'Bluetooth (BLE)';

  @override
  String get bluetoothDescription => 'Direct connection to your device';

  @override
  String get mqttConnection => 'MQTT Connection';

  @override
  String get mqttDescription => 'Connect via MQTT broker';

  @override
  String get selectLanguage => 'Language';

  @override
  String get english => 'English';

  @override
  String get spanish => 'Español';

  @override
  String examplesTitle(String connectionType) {
    return '$connectionType Examples';
  }

  @override
  String get selectExample => 'Select an Example';

  @override
  String examplesUsing(String connectionType) {
    return 'Examples using $connectionType connection';
  }

  @override
  String get blinkLed => 'Blink LED';

  @override
  String get blinkLedSubtitle => 'Control the onboard LED remotely';

  @override
  String get bme68xSensors => 'BME68X Sensors';

  @override
  String get bme68xSensorsSubtitle =>
      'Monitor temperature, humidity, pressure and air quality';

  @override
  String get motionSensor => 'Motion Sensor';

  @override
  String get motionSensorSubtitle =>
      'View BMI270 accelerometer and gyroscope data';

  @override
  String get floorDetector => 'Floor Detector';

  @override
  String get floorDetectorSubtitle =>
      'Detect current floor using barometric pressure';

  @override
  String get connecting => 'Connecting...';

  @override
  String get connected => 'Connected';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get cancel => 'Cancel';

  @override
  String get startNavigation => 'Start Navigation';

  @override
  String get connectAndNavigate => 'Connect & Navigate';

  @override
  String get connectingToMqtt => 'Connecting to MQTT...';

  @override
  String get mqttConnected => 'MQTT Connected Successfully';

  @override
  String get mqttConnectionFailed => 'Failed to connect to MQTT';

  @override
  String get realTimeMap => 'Real-time Map';

  @override
  String get yourPosition => 'Your Position';

  @override
  String get loadingMap => 'Loading map...';

  @override
  String get bleConnectionRequired => 'BLE Connection Required';

  @override
  String get bleConnectionRequiredDesc =>
      'To change the device name, we need to connect via Bluetooth. Would you like to connect now?';

  @override
  String get connectBle => 'Connect BLE';

  @override
  String get editDeviceName => 'Edit Device Name';

  @override
  String get bleConnected => 'BLE Connected';

  @override
  String get save => 'Save';

  @override
  String get connectingToBle => 'Connecting to BLE...';

  @override
  String get bleConnectionFailed => 'BLE Connection Failed';

  @override
  String get deviceNameUpdated => 'Device name updated successfully';

  @override
  String get ledControl => 'LED Control';

  @override
  String get turnOn => 'Turn ON';

  @override
  String get turnOff => 'Turn OFF';

  @override
  String get ledStatus => 'LED Status';

  @override
  String get on => 'ON';

  @override
  String get off => 'OFF';

  @override
  String get sensorData => 'Sensor Data';

  @override
  String get temperature => 'Temperature';

  @override
  String get humidity => 'Humidity';

  @override
  String get pressure => 'Pressure';

  @override
  String get airQuality => 'Air Quality';

  @override
  String get co2 => 'CO2';

  @override
  String get voc => 'VOC';

  @override
  String get timestamp => 'Timestamp';

  @override
  String get motionData => 'Motion Data';

  @override
  String get accelerometer => 'Accelerometer';

  @override
  String get gyroscope => 'Gyroscope';

  @override
  String get requestData => 'Request Data';

  @override
  String get tapToRequest => 'Tap the button to request motion sensor data';

  @override
  String get requestingData => 'Requesting motion sensor data...';

  @override
  String get dataReceived => 'Data received successfully!';

  @override
  String get floorDetection => 'Floor Detection';

  @override
  String get currentFloor => 'Current Floor';

  @override
  String get detecting => 'Detecting...';

  @override
  String get error => 'Error';

  @override
  String get noConnection => 'No connection available';

  @override
  String get connectionFailed => 'Connection failed';

  @override
  String get dataParsingError => 'Error parsing data';

  @override
  String get back => 'Back';

  @override
  String get retry => 'Retry';

  @override
  String get settings => 'Settings';

  @override
  String get compassNavigation => 'Compass Navigation';

  @override
  String get compassNavigationSubtitle =>
      'Indoor navigation with compass and floor detection';

  @override
  String get indoorNavigationSystem => 'Indoor Navigation System';

  @override
  String get indoorNavigationDescription =>
      'Navigate indoors with real-time compass and floor detection';

  @override
  String get features => 'Features';

  @override
  String get interactiveMap => 'Interactive Map';

  @override
  String get interactiveMapDescription => 'Real-time location on indoor map';

  @override
  String get compassDirection => 'Compass Direction';

  @override
  String get compassDirectionDescription => 'Real-time heading from device';

  @override
  String get floorDetectionDescription => 'Automatic floor level calibration';

  @override
  String get navigation => 'Navigation';

  @override
  String get navigationDescription => 'Find routes to other devices';

  @override
  String get chooseConnectionType => 'Choose Connection Type';

  @override
  String get bleConnection => 'BLE Connection';

  @override
  String get deviceSettings => 'Device Settings';

  @override
  String get floor => 'Floor';

  @override
  String get info => 'Info';

  @override
  String get devices => 'Devices';

  @override
  String get navigate => 'Navigate';

  @override
  String get deviceName => 'Device Name';

  @override
  String get currentHeading => 'Current Heading';

  @override
  String get location => 'Location';

  @override
  String get unknown => 'Unknown';

  @override
  String get calibrate => 'Calibrate';

  @override
  String get connection => 'Connection';

  @override
  String get floorCalibrated => 'Floor calibrated';

  @override
  String get floorCalibrationDisabled => 'Floor calibration disabled';

  @override
  String get goUp => 'Go up';

  @override
  String get goDown => 'Go down';

  @override
  String get floors => 'floor(s)';

  @override
  String get connectionStatus => 'Connection Status';

  @override
  String get stopStream => 'Stop Stream';

  @override
  String get startStream => 'Start Stream';

  @override
  String get resetOrientation => 'Reset Orientation';

  @override
  String get clearData => 'Clear Data';

  @override
  String get generateTestData => 'Generate Test Data';

  @override
  String get startTestStream => 'Start Test Stream';

  @override
  String get stopTestStream => 'Stop Test Stream';

  @override
  String get deviceInfo => 'Device Info';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get model3d => '3D Model';

  @override
  String get deviceInformation => 'Device Information';

  @override
  String get disconnectConfirm =>
      'Are you sure you want to disconnect from the device?';

  @override
  String get bearing => 'Bearing';

  @override
  String get degrees => 'degrees';

  @override
  String get north => 'North';

  @override
  String get south => 'South';

  @override
  String get east => 'East';

  @override
  String get west => 'West';

  @override
  String get northeast => 'Northeast';

  @override
  String get northwest => 'Northwest';

  @override
  String get southeast => 'Southeast';

  @override
  String get southwest => 'Southwest';

  @override
  String get compassReading => 'Compass Reading';

  @override
  String get currentDirection => 'Current Direction';

  @override
  String get headingTo => 'Heading to';

  @override
  String get calibrateCompass => 'Calibrate Compass';

  @override
  String get compassCalibration => 'Compass Calibration';

  @override
  String get compassCalibrationDescription =>
      'Rotate your device to calibrate the compass';
}
