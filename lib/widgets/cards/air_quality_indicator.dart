import 'package:flutter/material.dart';

class AirQualityIndicator extends StatelessWidget {
  final double iaqValue;
  
  const AirQualityIndicator({
    Key? key, 
    required this.iaqValue
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getIAQColor(iaqValue).withOpacity(0.1),
            _getIAQColor(iaqValue).withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getIAQColor(iaqValue)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calidad del Aire',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Índice IAQ: ${iaqValue.toInt()}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getIAQColor(iaqValue),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getAirQualityText(iaqValue),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _normalizeIAQ(iaqValue),
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(_getIAQColor(iaqValue)),
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Excelente',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                'Buena', 
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                'Moderada', 
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                'Pobre', 
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                'Peligrosa', 
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getAirQualityDescription(iaqValue),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getIAQColor(double value) {
    if (value <= 50) return Colors.green;
    if (value <= 100) return Colors.lightGreen;
    if (value <= 150) return Colors.yellow;
    if (value <= 200) return Colors.orange;
    if (value <= 300) return Colors.red;
    return Colors.purple;
  }
  
  String _getAirQualityText(double value) {
    if (value <= 50) return 'Excelente';
    if (value <= 100) return 'Buena';
    if (value <= 150) return 'Moderada';
    if (value <= 200) return 'Pobre';
    if (value <= 300) return 'Muy Pobre';
    return 'Peligrosa';
  }
  
  double _normalizeIAQ(double value) {
    if (value >= 500) return 1.0;
    return value / 500;
  }
  
  String _getAirQualityDescription(double value) {
    if (value <= 50) {
      return 'Calidad del aire óptima. Ideal para actividades en ambientes interiores y exteriores.';
    } else if (value <= 100) {
      return 'Buena calidad del aire. Aceptable para la mayoría de las personas.';
    } else if (value <= 150) {
      return 'Calidad moderada. Considere ventilar la habitación.';
    } else if (value <= 200) {
      return 'Calidad del aire pobre. Se recomienda una mejor ventilación.';
    } else if (value <= 300) {
      return 'Calidad del aire muy pobre. Se recomienda evitar la exposición prolongada.';
    } else {
      return 'Calidad del aire peligrosa. Ventile inmediatamente y considere abandonar el área.';
    }
  }
}