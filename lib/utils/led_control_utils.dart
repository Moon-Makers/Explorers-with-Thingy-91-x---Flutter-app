// LED Control Utilities for BLE Devices
// Este archivo contiene utilidades para controlar LEDs en diferentes tipos de dispositivos BLE

class LedCommands {
  // Comandos básicos binarios
  static const List<int> LED_ON_BINARY = [0x01];
  static const List<int> LED_OFF_BINARY = [0x00];
  
  // Comandos ASCII
  static const List<int> LED_ON_ASCII = [0x31]; // '1'
  static const List<int> LED_OFF_ASCII = [0x30]; // '0'
  
  // Comandos de texto
  static const List<int> LED_ON_TEXT = [0x4F, 0x4E]; // "ON"
  static const List<int> LED_OFF_TEXT = [0x4F, 0x46, 0x46]; // "OFF"
  
  // Comandos RGB (para LEDs que soportan colores)
  static const List<int> LED_RED = [0xFF, 0x00, 0x00];
  static const List<int> LED_GREEN = [0x00, 0xFF, 0x00];
  static const List<int> LED_BLUE = [0x00, 0x00, 0xFF];
  static const List<int> LED_WHITE = [0xFF, 0xFF, 0xFF];
  static const List<int> LED_OFF_RGB = [0x00, 0x00, 0x00];
  
  // Comandos específicos por dispositivo
  static const Map<String, Map<String, List<int>>> DEVICE_SPECIFIC_COMMANDS = {
    'nordic': {
      'on': [0x01],   // Comando específico para tu Nordic Thingy
      'off': [0x00],  // Comando específico para tu Nordic Thingy
    },
    'thingy': {
      'on': [0x01],   // Comando específico para tu Nordic Thingy
      'off': [0x00],  // Comando específico para tu Nordic Thingy
    },
    'arduino': {
      'on': [0x01],
      'off': [0x00],
    },
    'esp32': {
      'on': [0x31], // '1'
      'off': [0x30], // '0'
    },
  };
  
  // Obtener comando específico para un dispositivo
  static List<int>? getDeviceCommand(String deviceName, bool turnOn) {
    final normalizedName = deviceName.toLowerCase();
    
    // Prioridad específica para dispositivos Nordic/Thingy
    if (normalizedName.contains('nordic') || normalizedName.contains('thingy')) {
      return DEVICE_SPECIFIC_COMMANDS['nordic']![turnOn ? 'on' : 'off'];
    }
    
    // Otros dispositivos
    for (final deviceType in DEVICE_SPECIFIC_COMMANDS.keys) {
      if (normalizedName.contains(deviceType)) {
        return DEVICE_SPECIFIC_COMMANDS[deviceType]![turnOn ? 'on' : 'off'];
      }
    }
    
    return null; // Usar comandos por defecto
  }
  
  // Lista de todos los comandos para probar
  static List<List<int>> getAllTestCommands(bool turnOn) {
    return [
      turnOn ? LED_ON_BINARY : LED_OFF_BINARY,
      turnOn ? LED_ON_ASCII : LED_OFF_ASCII,
      turnOn ? LED_ON_TEXT : LED_OFF_TEXT,
      turnOn ? [0xFF] : [0x00],
      turnOn ? LED_WHITE : LED_OFF_RGB,
      turnOn ? LED_RED : LED_OFF_RGB,
      turnOn ? LED_GREEN : LED_OFF_RGB,
      turnOn ? LED_BLUE : LED_OFF_RGB,
      turnOn ? [0x01, 0x01] : [0x00, 0x00],
      turnOn ? [0x01, 0x00, 0x01] : [0x00, 0x00, 0x00],
    ];
  }
}

// UUIDs comunes para diferentes servicios BLE
class BleUuids {
  // Servicios estándar
  static const String DEVICE_INFORMATION = "0000180a-0000-1000-8000-00805f9b34fb";
  static const String BATTERY_SERVICE = "0000180f-0000-1000-8000-00805f9b34fb";
  static const String HEART_RATE = "0000180d-0000-1000-8000-00805f9b34fb";
  
  // Nordic UART Service (muy común)
  static const String NORDIC_UART_SERVICE = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
  static const String NORDIC_UART_TX = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";
  static const String NORDIC_UART_RX = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";
  
  // Servicios personalizados comunes
  static const String CUSTOM_LED_SERVICE = "000000ff-0000-1000-8000-00805f9b34fb";
  static const String CUSTOM_LED_CHAR = "0000ff01-0000-1000-8000-00805f9b34fb";
  
  // Nordic Thingy:91 X específicos (basado en tu código C)
  static const String NORDIC_THINGY_LED_SERVICE = "12345678-1234-1234-1234-123456789abc";
  static const String NORDIC_THINGY_LED_CHAR = "12345678-1234-1234-1234-123456789abd";
  
  // Thingy:91 estándar
  static const String THINGY_LED_SERVICE = "ef680300-9b35-4933-9b10-52ffa9740042";
  static const String THINGY_LED_CHAR = "ef680301-9b35-4933-9b10-52ffa9740042";
  
  // Lista de servicios que pueden contener control de LED (ordenada por prioridad)
  static const List<String> POTENTIAL_LED_SERVICES = [
    NORDIC_THINGY_LED_SERVICE,  // Tu dispositivo específico - PRIORIDAD ALTA
    THINGY_LED_SERVICE,
    NORDIC_UART_SERVICE,
    CUSTOM_LED_SERVICE,
    DEVICE_INFORMATION,
  ];
  
  // Lista de características que pueden ser para LED (ordenada por prioridad)
  static const List<String> POTENTIAL_LED_CHARACTERISTICS = [
    NORDIC_THINGY_LED_CHAR,     // Tu dispositivo específico - PRIORIDAD ALTA
    THINGY_LED_CHAR,
    NORDIC_UART_TX,
    NORDIC_UART_RX,
    CUSTOM_LED_CHAR,
  ];
}

// Utilidades para identificar dispositivos
class LedDeviceIdentifier {
  static bool isArduino(String name) {
    return name.toLowerCase().contains('arduino');
  }
  
  static bool isESP32(String name) {
    return name.toLowerCase().contains('esp');
  }
  
  static bool isThingy(String name) {
    return name.toLowerCase().contains('thingy');
  }
  
  static bool isNordic(String name) {
    return name.toLowerCase().contains('nordic');
  }
  
  static bool hasLedInName(String name) {
    return name.toLowerCase().contains('led');
  }
  
  // Método específico para detectar tu dispositivo Nordic personalizado
  static bool isNordicThingyCustom(String name) {
    final normalized = name.toLowerCase();
    return normalized.contains('nordic') && normalized.contains('thingy') ||
           normalized.contains('nrf91') ||
           normalized.contains('91x') ||
           normalized.contains('bridge'); // Si usas "bridge" como parte del nombre
  }
  
  static bool isLikelyLedDevice(String name) {
    return isArduino(name) || isESP32(name) || isThingy(name) || 
           isNordic(name) || hasLedInName(name) || isNordicThingyCustom(name);
  }
  
  static String getDeviceType(String name) {
    if (isNordicThingyCustom(name)) return 'Nordic Thingy Custom';
    if (isThingy(name)) return 'Thingy';
    if (isNordic(name)) return 'Nordic';
    if (isArduino(name)) return 'Arduino';
    if (isESP32(name)) return 'ESP32';
    if (hasLedInName(name)) return 'LED Device';
    return 'Unknown';
  }
  
  // Método para obtener prioridad de conexión (mayor número = mayor prioridad)
  static int getConnectionPriority(String name) {
    if (isNordicThingyCustom(name)) return 100; // Máxima prioridad para tu dispositivo
    if (isThingy(name)) return 90;
    if (isNordic(name)) return 80;
    if (isArduino(name)) return 70;
    if (isESP32(name)) return 60;
    if (hasLedInName(name)) return 50;
    return 10; // Prioridad baja para otros dispositivos
  }
}
