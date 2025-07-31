import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

MqttClient createMqttClient(String server, String clientId, int port) {
  return MqttServerClient(server, clientId)..port = port;
}

void configureMqttClient(MqttClient client, bool secure) {
  if (client is MqttServerClient) {
    client.secure = secure;
    client.useWebSocket = false;
  }
}