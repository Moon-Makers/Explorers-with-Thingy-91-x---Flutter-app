import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_thingy_91x/models/sensor_data.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class SensorChart extends StatelessWidget {
  final String sensorType;
  final List<SensorData> readings;

  const SensorChart({
    super.key, 
    required this.sensorType, 
    required this.readings,
  });

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const Center(
        child: Text(
          'Sin datos disponibles',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final maxY = readings.map((e) => e.value).reduce(max) * 1.1;
    final minY = readings.map((e) => e.value).reduce(min) * 0.9;

    // Calcular el valor promedio
    final avgValue = readings.map((e) => e.value).reduce((a, b) => a + b) / readings.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título y estadísticas
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _getSensorTitle(sensorType),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            _buildTrend(readings),
          ],
        ),
        const SizedBox(height: 4),
        
        // Fila de estadísticas
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Valor actual
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Actual',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  '${readings.last.value.toStringAsFixed(1)} ${readings.last.unit}',
                  style: const TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
            
            // Valor promedio
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Promedio',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  '${avgValue.toStringAsFixed(1)} ${readings.last.unit}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            
            // Valor mínimo
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mín',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  '${minY.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            
            // Valor máximo
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Máx',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  '${maxY.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Timestamp de última lectura
        Text(
          DateFormat('HH:mm:ss dd/MM/yyyy').format(readings.last.timestamp),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        
        const SizedBox(height: 16),
        
        // Gráfica principal
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.3),
                    strokeWidth: 1,
                  );
                },
                getDrawingVerticalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.3),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: readings.length > 5 ? (readings.length / 5).floor().toDouble() : 1,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= readings.length || value.toInt() < 0) {
                        return const SizedBox.shrink();
                      }
                      final timestamp = readings[value.toInt()].timestamp;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat('HH:mm').format(timestamp),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              minX: 0,
              maxX: (readings.length - 1).toDouble(),
              minY: minY,
              maxY: maxY,
              lineBarsData: [
                // Línea principal de datos
                LineChartBarData(
                  spots: _getSpots(),
                  isCurved: true,
                  color: _getSensorColor(sensorType),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: readings.length < 15,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: _getSensorColor(sensorType),
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        _getSensorColor(sensorType).withOpacity(0.4),
                        _getSensorColor(sensorType).withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                
                // Línea de valor promedio
                LineChartBarData(
                  spots: [
                    FlSpot(0, avgValue),
                    FlSpot((readings.length - 1).toDouble(), avgValue),
                  ],
                  isCurved: false,
                  color: Colors.grey.withOpacity(0.5),
                  barWidth: 1.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                  dashArray: [5, 5],
                ),
              ],
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: Colors.black.withOpacity(0.8),
                  tooltipRoundedRadius: 8,
                  fitInsideHorizontally: true,
                  getTooltipItems: (List<LineBarSpot> touchedSpots) {
                    return touchedSpots.map((LineBarSpot touchedSpot) {
                      if (touchedSpot.barIndex == 0) { // Solo para la línea principal
                        final index = touchedSpot.x.toInt();
                        if (index >= 0 && index < readings.length) {
                          final data = readings[index];
                          return LineTooltipItem(
                            '${data.value.toStringAsFixed(2)} ${data.unit}\n${DateFormat('HH:mm:ss').format(data.timestamp)}',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }
                      }
                      return null;
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<FlSpot> _getSpots() {
    final spots = <FlSpot>[];
    for (int i = 0; i < readings.length; i++) {
      spots.add(FlSpot(i.toDouble(), readings[i].value));
    }
    return spots;
  }

  String _getSensorTitle(String type) {
    switch (type) {
      case 'temperature':
        return 'Temperatura';
      case 'humidity':
        return 'Humedad';
      case 'pressure':
        return 'Presión Atmosférica';
      case 'iaq':
        return 'Calidad del Aire (IAQ)';
      case 'co2':
        return 'CO₂';
      case 'voc':
        return 'Compuestos Orgánicos Volátiles';
      default:
        return 'Sensor';
    }
  }

  Color _getSensorColor(String type) {
    switch (type) {
      case 'temperature':
        return Colors.orangeAccent;
      case 'humidity':
        return Colors.blueAccent;
      case 'pressure':
        return Colors.purpleAccent;
      case 'iaq':
        return Colors.greenAccent;
      case 'co2':
        return Colors.brown;
      case 'voc':
        return Colors.tealAccent;
      default:
        return Colors.grey;
    }
  }
  
  // Mostrar indicador de tendencia
  Widget _buildTrend(List<SensorData> data) {
    if (data.length < 3) return const SizedBox.shrink();
    
    // Calcular tendencia con las últimas 3 lecturas
    final lastValue = data.last.value;
    final prevValue = data[data.length - 3].value;
    final diff = lastValue - prevValue;
    
    // Determinar dirección y color
    IconData icon;
    Color color;
    String text;
    
    final absDiff = diff.abs();
    final percentChange = (absDiff / prevValue * 100).toStringAsFixed(1);
    
    if (absDiff < 0.3) {
      // Estable
      icon = Icons.trending_flat;
      color = Colors.grey;
      text = 'Estable';
    } else if (diff > 0) {
      // Subiendo
      icon = Icons.trending_up;
      color = _getTrendColor(data, true);
      text = '+$percentChange%';
    } else {
      // Bajando
      icon = Icons.trending_down;
      color = _getTrendColor(data, false);
      text = '-$percentChange%';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  // Determinar color para tendencia según el tipo de sensor
  Color _getTrendColor(List<SensorData> data, bool isIncreasing) {
    final sensorName = data.first.name;
    
    // Para estos sensores, aumentar es malo
    if (sensorName == 'temperature' || sensorName == 'co2' || sensorName == 'voc' || sensorName == 'iaq') {
      return isIncreasing ? Colors.red : Colors.green;
    }
    
    // Para humedad, desviarse del rango ideal es malo
    if (sensorName == 'humidity') {
      final value = data.last.value;
      final isTowardIdeal = value > 30 && value < 60;
      return isTowardIdeal ? Colors.green : Colors.amber;
    }
    
    // Para presión, es simplemente informativo
    if (sensorName == 'pressure') {
      return isIncreasing ? Colors.blue : Colors.orange;
    }
    
    // Por defecto
    return isIncreasing ? Colors.green : Colors.red;
  }
}