import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mqtt_provider.dart';
import '../providers/sensor_provider.dart';

class MQTTSensorAdapter extends StatefulWidget {
  const MQTTSensorAdapter({Key? key}) : super(key: key);

  @override
  State<MQTTSensorAdapter> createState() => _MQTTSensorAdapterState();
}

class _MQTTSensorAdapterState extends State<MQTTSensorAdapter> {
  Timer? _updateTimer;
  bool _isFirstBuild = true;

  @override
  void initState() {
    super.initState();
    
    // Configurar un timer para actualizar periódicamente los datos
    _updateTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        _updateSensorsIfConnected();
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  // Método para actualizar los sensores fuera del ciclo de construcción
  void _updateSensorsIfConnected() {
    if (!mounted) return;
    
    final mqttProvider = Provider.of<MQTTProvider>(context, listen: false);
    final sensorProvider = Provider.of<SensorProvider>(context, listen: false);

    if (mqttProvider.isConnected) {
      _updateSensorProvider(sensorProvider, mqttProvider);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Solo hacer la actualización inicial una vez después de que el widget se construya completamente
    if (_isFirstBuild) {
      _isFirstBuild = false;
      
      // Esta llamada se realiza después de la construcción inicial
      Future.microtask(() => _updateSensorsIfConnected());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Solo observar cambios, no actualizar aquí
    context.watch<MQTTProvider>().isConnected;
    
    return const SizedBox.shrink(); // Widget invisible
  }

  // Método para actualizar el SensorProvider con datos del MQTTProvider
  void _updateSensorProvider(SensorProvider sensorProvider, MQTTProvider mqttProvider) {
    // Mapeo de nombres de sensores de MQTT a SensorProvider
    final mappings = {
      'temp': 'temperature',
      'press': 'pressure',
      'humidity': 'humidity',
      'iaq': 'iaq',
      'co2': 'co2',
      'voc': 'voc'
    };

    // Crear nueva lectura para cada sensor si hay datos disponibles
    mappings.forEach((mqttKey, sensorKey) {
      final value = mqttProvider.getSensorValue(mqttKey);
      if (value > 0) {  // Asumimos que 0 es valor no inicializado
        sensorProvider.addSensorReading(
          sensorKey, 
          value,
          DateTime.now()
        );
      }
    });
  }
}
