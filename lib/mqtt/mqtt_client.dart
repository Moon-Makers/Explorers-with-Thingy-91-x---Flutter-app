import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';

// Importamos condicionalmente la implementación correcta
import 'mqtt_client_stub.dart' if (dart.library.html) 'mqtt_client_web.dart';

class MQTTClientWrapper {
  static MqttClient createClient(String server, String clientId, int port) {
    return createMqttClient(server, clientId, port);
  }

  static void configureClient(MqttClient client, {bool secure = false}) {
    if (!kIsWeb) {
      configureMqttClient(client, secure);
    }
  }
}