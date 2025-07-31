import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Thingy:91 X'**
  String get appTitle;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Thingy:91 X'**
  String get homeTitle;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to your Nordic Thingy:91 X device'**
  String get homeSubtitle;

  /// No description provided for @selectConnection.
  ///
  /// In en, this message translates to:
  /// **'Select Connection Type'**
  String get selectConnection;

  /// No description provided for @selectConnectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to connect to your device'**
  String get selectConnectionSubtitle;

  /// No description provided for @bluetoothConnection.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth (BLE)'**
  String get bluetoothConnection;

  /// No description provided for @bluetoothDescription.
  ///
  /// In en, this message translates to:
  /// **'Direct connection to your device'**
  String get bluetoothDescription;

  /// No description provided for @mqttConnection.
  ///
  /// In en, this message translates to:
  /// **'MQTT Connection'**
  String get mqttConnection;

  /// No description provided for @mqttDescription.
  ///
  /// In en, this message translates to:
  /// **'Connect via MQTT broker'**
  String get mqttDescription;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get spanish;

  /// No description provided for @examplesTitle.
  ///
  /// In en, this message translates to:
  /// **'{connectionType} Examples'**
  String examplesTitle(String connectionType);

  /// No description provided for @selectExample.
  ///
  /// In en, this message translates to:
  /// **'Select an Example'**
  String get selectExample;

  /// No description provided for @examplesUsing.
  ///
  /// In en, this message translates to:
  /// **'Examples using {connectionType} connection'**
  String examplesUsing(String connectionType);

  /// No description provided for @blinkLed.
  ///
  /// In en, this message translates to:
  /// **'Blink LED'**
  String get blinkLed;

  /// No description provided for @blinkLedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Control the onboard LED remotely'**
  String get blinkLedSubtitle;

  /// No description provided for @bme68xSensors.
  ///
  /// In en, this message translates to:
  /// **'BME68X Sensors'**
  String get bme68xSensors;

  /// No description provided for @bme68xSensorsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Monitor temperature, humidity, pressure and air quality'**
  String get bme68xSensorsSubtitle;

  /// No description provided for @motionSensor.
  ///
  /// In en, this message translates to:
  /// **'Motion Sensor'**
  String get motionSensor;

  /// No description provided for @motionSensorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View BMI270 accelerometer and gyroscope data'**
  String get motionSensorSubtitle;

  /// No description provided for @floorDetector.
  ///
  /// In en, this message translates to:
  /// **'Floor Detector'**
  String get floorDetector;

  /// No description provided for @floorDetectorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Detect current floor using barometric pressure'**
  String get floorDetectorSubtitle;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @startNavigation.
  ///
  /// In en, this message translates to:
  /// **'Start Navigation'**
  String get startNavigation;

  /// No description provided for @connectAndNavigate.
  ///
  /// In en, this message translates to:
  /// **'Connect & Navigate'**
  String get connectAndNavigate;

  /// No description provided for @connectingToMqtt.
  ///
  /// In en, this message translates to:
  /// **'Connecting to MQTT...'**
  String get connectingToMqtt;

  /// No description provided for @mqttConnected.
  ///
  /// In en, this message translates to:
  /// **'MQTT Connected Successfully'**
  String get mqttConnected;

  /// No description provided for @mqttConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect to MQTT'**
  String get mqttConnectionFailed;

  /// No description provided for @realTimeMap.
  ///
  /// In en, this message translates to:
  /// **'Real-time Map'**
  String get realTimeMap;

  /// No description provided for @yourPosition.
  ///
  /// In en, this message translates to:
  /// **'Your Position'**
  String get yourPosition;

  /// No description provided for @loadingMap.
  ///
  /// In en, this message translates to:
  /// **'Loading map...'**
  String get loadingMap;

  /// No description provided for @bleConnectionRequired.
  ///
  /// In en, this message translates to:
  /// **'BLE Connection Required'**
  String get bleConnectionRequired;

  /// No description provided for @bleConnectionRequiredDesc.
  ///
  /// In en, this message translates to:
  /// **'To change the device name, we need to connect via Bluetooth. Would you like to connect now?'**
  String get bleConnectionRequiredDesc;

  /// No description provided for @connectBle.
  ///
  /// In en, this message translates to:
  /// **'Connect BLE'**
  String get connectBle;

  /// No description provided for @editDeviceName.
  ///
  /// In en, this message translates to:
  /// **'Edit Device Name'**
  String get editDeviceName;

  /// No description provided for @bleConnected.
  ///
  /// In en, this message translates to:
  /// **'BLE Connected'**
  String get bleConnected;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @connectingToBle.
  ///
  /// In en, this message translates to:
  /// **'Connecting to BLE...'**
  String get connectingToBle;

  /// No description provided for @bleConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'BLE Connection Failed'**
  String get bleConnectionFailed;

  /// No description provided for @deviceNameUpdated.
  ///
  /// In en, this message translates to:
  /// **'Device name updated successfully'**
  String get deviceNameUpdated;

  /// No description provided for @ledControl.
  ///
  /// In en, this message translates to:
  /// **'LED Control'**
  String get ledControl;

  /// No description provided for @turnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn ON'**
  String get turnOn;

  /// No description provided for @turnOff.
  ///
  /// In en, this message translates to:
  /// **'Turn OFF'**
  String get turnOff;

  /// No description provided for @ledStatus.
  ///
  /// In en, this message translates to:
  /// **'LED Status'**
  String get ledStatus;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get on;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get off;

  /// No description provided for @sensorData.
  ///
  /// In en, this message translates to:
  /// **'Sensor Data'**
  String get sensorData;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @humidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidity;

  /// No description provided for @pressure.
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get pressure;

  /// No description provided for @airQuality.
  ///
  /// In en, this message translates to:
  /// **'Air Quality'**
  String get airQuality;

  /// No description provided for @co2.
  ///
  /// In en, this message translates to:
  /// **'CO2'**
  String get co2;

  /// No description provided for @voc.
  ///
  /// In en, this message translates to:
  /// **'VOC'**
  String get voc;

  /// No description provided for @timestamp.
  ///
  /// In en, this message translates to:
  /// **'Timestamp'**
  String get timestamp;

  /// No description provided for @motionData.
  ///
  /// In en, this message translates to:
  /// **'Motion Data'**
  String get motionData;

  /// No description provided for @accelerometer.
  ///
  /// In en, this message translates to:
  /// **'Accelerometer'**
  String get accelerometer;

  /// No description provided for @gyroscope.
  ///
  /// In en, this message translates to:
  /// **'Gyroscope'**
  String get gyroscope;

  /// No description provided for @requestData.
  ///
  /// In en, this message translates to:
  /// **'Request Data'**
  String get requestData;

  /// No description provided for @tapToRequest.
  ///
  /// In en, this message translates to:
  /// **'Tap the button to request motion sensor data'**
  String get tapToRequest;

  /// No description provided for @requestingData.
  ///
  /// In en, this message translates to:
  /// **'Requesting motion sensor data...'**
  String get requestingData;

  /// No description provided for @dataReceived.
  ///
  /// In en, this message translates to:
  /// **'Data received successfully!'**
  String get dataReceived;

  /// No description provided for @floorDetection.
  ///
  /// In en, this message translates to:
  /// **'Floor Detection'**
  String get floorDetection;

  /// No description provided for @currentFloor.
  ///
  /// In en, this message translates to:
  /// **'Current Floor'**
  String get currentFloor;

  /// No description provided for @detecting.
  ///
  /// In en, this message translates to:
  /// **'Detecting...'**
  String get detecting;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @noConnection.
  ///
  /// In en, this message translates to:
  /// **'No connection available'**
  String get noConnection;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get connectionFailed;

  /// No description provided for @dataParsingError.
  ///
  /// In en, this message translates to:
  /// **'Error parsing data'**
  String get dataParsingError;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @compassNavigation.
  ///
  /// In en, this message translates to:
  /// **'Compass Navigation'**
  String get compassNavigation;

  /// No description provided for @compassNavigationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Indoor navigation with compass and floor detection'**
  String get compassNavigationSubtitle;

  /// No description provided for @indoorNavigationSystem.
  ///
  /// In en, this message translates to:
  /// **'Indoor Navigation System'**
  String get indoorNavigationSystem;

  /// No description provided for @indoorNavigationDescription.
  ///
  /// In en, this message translates to:
  /// **'Navigate indoors with real-time compass and floor detection'**
  String get indoorNavigationDescription;

  /// No description provided for @features.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get features;

  /// No description provided for @interactiveMap.
  ///
  /// In en, this message translates to:
  /// **'Interactive Map'**
  String get interactiveMap;

  /// No description provided for @interactiveMapDescription.
  ///
  /// In en, this message translates to:
  /// **'Real-time location on indoor map'**
  String get interactiveMapDescription;

  /// No description provided for @compassDirection.
  ///
  /// In en, this message translates to:
  /// **'Compass Direction'**
  String get compassDirection;

  /// No description provided for @compassDirectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Real-time heading from device'**
  String get compassDirectionDescription;

  /// No description provided for @floorDetectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatic floor level calibration'**
  String get floorDetectionDescription;

  /// No description provided for @navigation.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get navigation;

  /// No description provided for @navigationDescription.
  ///
  /// In en, this message translates to:
  /// **'Find routes to other devices'**
  String get navigationDescription;

  /// No description provided for @chooseConnectionType.
  ///
  /// In en, this message translates to:
  /// **'Choose Connection Type'**
  String get chooseConnectionType;

  /// No description provided for @bleConnection.
  ///
  /// In en, this message translates to:
  /// **'BLE Connection'**
  String get bleConnection;

  /// No description provided for @deviceSettings.
  ///
  /// In en, this message translates to:
  /// **'Device Settings'**
  String get deviceSettings;

  /// No description provided for @floor.
  ///
  /// In en, this message translates to:
  /// **'Floor'**
  String get floor;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @devices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get devices;

  /// No description provided for @navigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigate;

  /// No description provided for @deviceName.
  ///
  /// In en, this message translates to:
  /// **'Device Name'**
  String get deviceName;

  /// No description provided for @currentHeading.
  ///
  /// In en, this message translates to:
  /// **'Current Heading'**
  String get currentHeading;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @calibrate.
  ///
  /// In en, this message translates to:
  /// **'Calibrate'**
  String get calibrate;

  /// No description provided for @connection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get connection;

  /// No description provided for @floorCalibrated.
  ///
  /// In en, this message translates to:
  /// **'Floor calibrated'**
  String get floorCalibrated;

  /// No description provided for @floorCalibrationDisabled.
  ///
  /// In en, this message translates to:
  /// **'Floor calibration disabled'**
  String get floorCalibrationDisabled;

  /// No description provided for @goUp.
  ///
  /// In en, this message translates to:
  /// **'Go up'**
  String get goUp;

  /// No description provided for @goDown.
  ///
  /// In en, this message translates to:
  /// **'Go down'**
  String get goDown;

  /// No description provided for @floors.
  ///
  /// In en, this message translates to:
  /// **'floor(s)'**
  String get floors;

  /// No description provided for @connectionStatus.
  ///
  /// In en, this message translates to:
  /// **'Connection Status'**
  String get connectionStatus;

  /// No description provided for @stopStream.
  ///
  /// In en, this message translates to:
  /// **'Stop Stream'**
  String get stopStream;

  /// No description provided for @startStream.
  ///
  /// In en, this message translates to:
  /// **'Start Stream'**
  String get startStream;

  /// No description provided for @resetOrientation.
  ///
  /// In en, this message translates to:
  /// **'Reset Orientation'**
  String get resetOrientation;

  /// No description provided for @clearData.
  ///
  /// In en, this message translates to:
  /// **'Clear Data'**
  String get clearData;

  /// No description provided for @generateTestData.
  ///
  /// In en, this message translates to:
  /// **'Generate Test Data'**
  String get generateTestData;

  /// No description provided for @startTestStream.
  ///
  /// In en, this message translates to:
  /// **'Start Test Stream'**
  String get startTestStream;

  /// No description provided for @stopTestStream.
  ///
  /// In en, this message translates to:
  /// **'Stop Test Stream'**
  String get stopTestStream;

  /// No description provided for @deviceInfo.
  ///
  /// In en, this message translates to:
  /// **'Device Info'**
  String get deviceInfo;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @model3d.
  ///
  /// In en, this message translates to:
  /// **'3D Model'**
  String get model3d;

  /// No description provided for @deviceInformation.
  ///
  /// In en, this message translates to:
  /// **'Device Information'**
  String get deviceInformation;

  /// No description provided for @disconnectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to disconnect from the device?'**
  String get disconnectConfirm;

  /// No description provided for @bearing.
  ///
  /// In en, this message translates to:
  /// **'Bearing'**
  String get bearing;

  /// No description provided for @degrees.
  ///
  /// In en, this message translates to:
  /// **'degrees'**
  String get degrees;

  /// No description provided for @north.
  ///
  /// In en, this message translates to:
  /// **'North'**
  String get north;

  /// No description provided for @south.
  ///
  /// In en, this message translates to:
  /// **'South'**
  String get south;

  /// No description provided for @east.
  ///
  /// In en, this message translates to:
  /// **'East'**
  String get east;

  /// No description provided for @west.
  ///
  /// In en, this message translates to:
  /// **'West'**
  String get west;

  /// No description provided for @northeast.
  ///
  /// In en, this message translates to:
  /// **'Northeast'**
  String get northeast;

  /// No description provided for @northwest.
  ///
  /// In en, this message translates to:
  /// **'Northwest'**
  String get northwest;

  /// No description provided for @southeast.
  ///
  /// In en, this message translates to:
  /// **'Southeast'**
  String get southeast;

  /// No description provided for @southwest.
  ///
  /// In en, this message translates to:
  /// **'Southwest'**
  String get southwest;

  /// No description provided for @compassReading.
  ///
  /// In en, this message translates to:
  /// **'Compass Reading'**
  String get compassReading;

  /// No description provided for @currentDirection.
  ///
  /// In en, this message translates to:
  /// **'Current Direction'**
  String get currentDirection;

  /// No description provided for @headingTo.
  ///
  /// In en, this message translates to:
  /// **'Heading to'**
  String get headingTo;

  /// No description provided for @calibrateCompass.
  ///
  /// In en, this message translates to:
  /// **'Calibrate Compass'**
  String get calibrateCompass;

  /// No description provided for @compassCalibration.
  ///
  /// In en, this message translates to:
  /// **'Compass Calibration'**
  String get compassCalibration;

  /// No description provided for @compassCalibrationDescription.
  ///
  /// In en, this message translates to:
  /// **'Rotate your device to calibrate the compass'**
  String get compassCalibrationDescription;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
