// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Thingy:91 X';

  @override
  String get homeTitle => 'Bienvenido a Thingy:91 X';

  @override
  String get homeSubtitle => 'Conéctate a tu dispositivo Nordic Thingy:91 X';

  @override
  String get selectConnection => 'Seleccionar Tipo de Conexión';

  @override
  String get selectConnectionSubtitle =>
      'Elige cómo quieres conectarte a tu dispositivo';

  @override
  String get bluetoothConnection => 'Bluetooth (BLE)';

  @override
  String get bluetoothDescription => 'Conexión directa a tu dispositivo';

  @override
  String get mqttConnection => 'Conexión MQTT';

  @override
  String get mqttDescription => 'Conectar vía broker MQTT';

  @override
  String get selectLanguage => 'Idioma';

  @override
  String get english => 'English';

  @override
  String get spanish => 'Español';

  @override
  String examplesTitle(String connectionType) {
    return 'Ejemplos $connectionType';
  }

  @override
  String get selectExample => 'Seleccionar un Ejemplo';

  @override
  String examplesUsing(String connectionType) {
    return 'Ejemplos usando conexión $connectionType';
  }

  @override
  String get blinkLed => 'Parpadeo LED';

  @override
  String get blinkLedSubtitle => 'Controla el LED integrado remotamente';

  @override
  String get bme68xSensors => 'Sensores BME68X';

  @override
  String get bme68xSensorsSubtitle =>
      'Monitorea temperatura, humedad, presión y calidad del aire';

  @override
  String get motionSensor => 'Sensor de Movimiento';

  @override
  String get motionSensorSubtitle =>
      'Ver datos del acelerómetro y giroscopio BMI270';

  @override
  String get floorDetector => 'Detector de Piso';

  @override
  String get floorDetectorSubtitle =>
      'Detectar piso actual usando presión barométrica';

  @override
  String get connecting => 'Conectando...';

  @override
  String get connected => 'Conectado';

  @override
  String get disconnected => 'Desconectado';

  @override
  String get disconnect => 'Desconectar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get startNavigation => 'Iniciar Navegación';

  @override
  String get connectAndNavigate => 'Conectar y Navegar';

  @override
  String get connectingToMqtt => 'Conectando a MQTT...';

  @override
  String get mqttConnected => 'MQTT Conectado Exitosamente';

  @override
  String get mqttConnectionFailed => 'Falló la conexión a MQTT';

  @override
  String get realTimeMap => 'Mapa en Tiempo Real';

  @override
  String get yourPosition => 'Tu Posición';

  @override
  String get loadingMap => 'Cargando mapa...';

  @override
  String get bleConnectionRequired => 'Conexión BLE Requerida';

  @override
  String get bleConnectionRequiredDesc =>
      'Para cambiar el nombre del dispositivo, necesitamos conectarnos vía Bluetooth. ¿Te gustaría conectarte ahora?';

  @override
  String get connectBle => 'Conectar BLE';

  @override
  String get editDeviceName => 'Editar Nombre del Dispositivo';

  @override
  String get bleConnected => 'BLE Conectado';

  @override
  String get save => 'Guardar';

  @override
  String get connectingToBle => 'Conectando a BLE...';

  @override
  String get bleConnectionFailed => 'Falló la Conexión BLE';

  @override
  String get deviceNameUpdated =>
      'Nombre del dispositivo actualizado exitosamente';

  @override
  String get ledControl => 'Control LED';

  @override
  String get turnOn => 'Encender';

  @override
  String get turnOff => 'Apagar';

  @override
  String get ledStatus => 'Estado LED';

  @override
  String get on => 'ENCENDIDO';

  @override
  String get off => 'APAGADO';

  @override
  String get sensorData => 'Datos del Sensor';

  @override
  String get temperature => 'Temperatura';

  @override
  String get humidity => 'Humedad';

  @override
  String get pressure => 'Presión';

  @override
  String get airQuality => 'Calidad del Aire';

  @override
  String get co2 => 'CO2';

  @override
  String get voc => 'COV';

  @override
  String get timestamp => 'Marca de Tiempo';

  @override
  String get motionData => 'Datos de Movimiento';

  @override
  String get accelerometer => 'Acelerómetro';

  @override
  String get gyroscope => 'Giroscopio';

  @override
  String get requestData => 'Solicitar Datos';

  @override
  String get tapToRequest =>
      'Toca el botón para solicitar datos del sensor de movimiento';

  @override
  String get requestingData => 'Solicitando datos del sensor de movimiento...';

  @override
  String get dataReceived => '¡Datos recibidos exitosamente!';

  @override
  String get floorDetection => 'Detección de Piso';

  @override
  String get currentFloor => 'Piso Actual';

  @override
  String get detecting => 'Detectando...';

  @override
  String get error => 'Error';

  @override
  String get noConnection => 'No hay conexión disponible';

  @override
  String get connectionFailed => 'Falló la conexión';

  @override
  String get dataParsingError => 'Error al analizar datos';

  @override
  String get back => 'Atrás';

  @override
  String get retry => 'Reintentar';

  @override
  String get settings => 'Configuración';

  @override
  String get compassNavigation => 'Navegación Brújula';

  @override
  String get compassNavigationSubtitle =>
      'Navegación interior con brújula y detección de piso';

  @override
  String get indoorNavigationSystem => 'Sistema de Navegación Interior';

  @override
  String get indoorNavigationDescription =>
      'Navegue en interiores con brújula en tiempo real y detección de piso';

  @override
  String get features => 'Características';

  @override
  String get interactiveMap => 'Mapa Interactivo';

  @override
  String get interactiveMapDescription =>
      'Ubicación en tiempo real en mapa interior';

  @override
  String get compassDirection => 'Dirección Brújula';

  @override
  String get compassDirectionDescription =>
      'Dirección en tiempo real del dispositivo';

  @override
  String get floorDetectionDescription =>
      'Calibración automática del nivel de piso';

  @override
  String get navigation => 'Navegación';

  @override
  String get navigationDescription => 'Encuentra rutas a otros dispositivos';

  @override
  String get chooseConnectionType => 'Elige el Tipo de Conexión';

  @override
  String get bleConnection => 'Conexión BLE';

  @override
  String get deviceSettings => 'Configuración del Dispositivo';

  @override
  String get floor => 'Piso';

  @override
  String get info => 'Info';

  @override
  String get devices => 'Dispositivos';

  @override
  String get navigate => 'Navegar';

  @override
  String get deviceName => 'Nombre del Dispositivo';

  @override
  String get currentHeading => 'Dirección Actual';

  @override
  String get location => 'Ubicación';

  @override
  String get unknown => 'Desconocida';

  @override
  String get calibrate => 'Calibrar';

  @override
  String get connection => 'Conexión';

  @override
  String get floorCalibrated => 'Piso calibrado';

  @override
  String get floorCalibrationDisabled => 'Calibración de piso deshabilitada';

  @override
  String get goUp => 'Subir';

  @override
  String get goDown => 'Bajar';

  @override
  String get floors => 'piso(s)';

  @override
  String get connectionStatus => 'Estado de Conexión';

  @override
  String get stopStream => 'Detener Stream';

  @override
  String get startStream => 'Iniciar Stream';

  @override
  String get resetOrientation => 'Resetear Orientación';

  @override
  String get clearData => 'Limpiar Datos';

  @override
  String get generateTestData => 'Generar Datos de Prueba';

  @override
  String get startTestStream => 'Iniciar Stream de Prueba';

  @override
  String get stopTestStream => 'Detener Stream de Prueba';

  @override
  String get deviceInfo => 'Info del Dispositivo';

  @override
  String get dashboard => 'Panel';

  @override
  String get model3d => 'Modelo 3D';

  @override
  String get deviceInformation => 'Información del Dispositivo';

  @override
  String get disconnectConfirm =>
      '¿Estás seguro de que quieres desconectar del dispositivo?';

  @override
  String get bearing => 'Rumbo';

  @override
  String get degrees => 'grados';

  @override
  String get north => 'Norte';

  @override
  String get south => 'Sur';

  @override
  String get east => 'Este';

  @override
  String get west => 'Oeste';

  @override
  String get northeast => 'Noreste';

  @override
  String get northwest => 'Noroeste';

  @override
  String get southeast => 'Sureste';

  @override
  String get southwest => 'Suroeste';

  @override
  String get compassReading => 'Lectura de Brújula';

  @override
  String get currentDirection => 'Dirección Actual';

  @override
  String get headingTo => 'Dirigiéndose hacia';

  @override
  String get calibrateCompass => 'Calibrar Brújula';

  @override
  String get compassCalibration => 'Calibración de Brújula';

  @override
  String get compassCalibrationDescription =>
      'Rota tu dispositivo para calibrar la brújula';
}
