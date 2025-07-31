library sensor_data;

class SensorData {
  final String name;
  final double value;
  final String unit;
  final DateTime timestamp;

  SensorData({
    required this.name,
    required this.value,
    required this.unit,
    required this.timestamp,
  });
}

class ThreeAxisData {
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;

  ThreeAxisData({
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
  });
}