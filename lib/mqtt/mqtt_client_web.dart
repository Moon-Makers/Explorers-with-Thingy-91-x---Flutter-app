import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

MqttClient createMqttClient(String server, String clientId, int port) {
  final client = MqttBrowserClient('ws://$server:9001', clientId);
  return client;
}

void configureMqttClient(MqttClient client, bool secure) {
  // Web client configuration if needed
  if (client is MqttBrowserClient) {
    // Configure for web
  }
}