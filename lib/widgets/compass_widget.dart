import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Custom Compass Widget that shows direction and bearing
class CompassWidget extends StatefulWidget {
  final double bearing; // Bearing in degrees (0-360)
  final double size; // Size of the compass
  final Color? primaryColor;
  final Color? secondaryColor;
  final Color? backgroundColor;
  final bool showBearing; // Whether to show bearing text
  final bool animated; // Whether to animate compass needle

  const CompassWidget({
    Key? key,
    required this.bearing,
    this.size = 200.0,
    this.primaryColor,
    this.secondaryColor,
    this.backgroundColor,
    this.showBearing = true,
    this.animated = true,
  }) : super(key: key);

  @override
  State<CompassWidget> createState() => _CompassWidgetState();
}

class _CompassWidgetState extends State<CompassWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _bearingAnimation;
  double _currentBearing = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _bearingAnimation = Tween<double>(
      begin: 0,
      end: widget.bearing,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _currentBearing = widget.bearing;
    
    if (widget.animated) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(CompassWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bearing != widget.bearing && widget.animated) {
      _bearingAnimation = Tween<double>(
        begin: _currentBearing,
        end: widget.bearing,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
      _currentBearing = widget.bearing;
      _animationController.forward(from: 0);
    } else if (!widget.animated) {
      _currentBearing = widget.bearing;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.primaryColor ?? theme.colorScheme.primary;
    final secondaryColor = widget.secondaryColor ?? theme.colorScheme.secondary;
    final backgroundColor = widget.backgroundColor ?? Colors.white;

    // Fixed size container to prevent overflow
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Compass Circle
          Expanded(
            child: Container(
              width: widget.size * 0.8,
              child: Stack(
              alignment: Alignment.center,
              children: [
                // Compass Background
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: backgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: primaryColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                ),
                
                // Compass Rose (Cardinal Directions)
                CustomPaint(
                  size: Size(widget.size * 0.8, widget.size * 0.8),
                  painter: CompassRosePainter(
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor,
                  ),
                ),
                
                // Compass Needle
                AnimatedBuilder(
                  animation: widget.animated ? _bearingAnimation : 
                    AlwaysStoppedAnimation(_currentBearing),
                  builder: (context, child) {
                    final bearing = widget.animated ? 
                      _bearingAnimation.value : _currentBearing;
                    return Transform.rotate(
                      angle: bearing * math.pi / 180,
                      child: CustomPaint(
                        size: Size(widget.size * 0.6, widget.size * 0.6),
                        painter: CompassNeedlePainter(
                          primaryColor: primaryColor,
                          secondaryColor: secondaryColor,
                        ),
                      ),
                    );
                  },
                ),
                
                // Center dot
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ],
            ),
            ),
          ),
          
          // Bearing Text (simplified to fit in available space)
          if (widget.showBearing)
            Container(
              margin: const EdgeInsets.only(top: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: AnimatedBuilder(
                      animation: widget.animated ? _bearingAnimation : 
                        AlwaysStoppedAnimation(_currentBearing),
                      builder: (context, child) {
                        final bearing = widget.animated ? 
                          _bearingAnimation.value : _currentBearing;
                        return Text(
                          '${bearing.round()}°',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Painter for the compass rose (cardinal directions)
class CompassRosePainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  CompassRosePainter({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    final paint = Paint()
      ..color = primaryColor.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Draw cardinal direction marks
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      final startRadius = radius * 0.85;
      final endRadius = radius * 0.95;
      
      final start = Offset(
        center.dx + startRadius * math.cos(angle - math.pi / 2),
        center.dy + startRadius * math.sin(angle - math.pi / 2),
      );
      final end = Offset(
        center.dx + endRadius * math.cos(angle - math.pi / 2),
        center.dy + endRadius * math.sin(angle - math.pi / 2),
      );
      
      // Draw major marks
      canvas.drawLine(start, end, paint..strokeWidth = 3);
      
      // Draw cardinal letters
      final letters = ['N', 'E', 'S', 'W'];
      textPainter.text = TextSpan(
        text: letters[i],
        style: TextStyle(
          color: primaryColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      
      final textRadius = radius * 0.75;
      final textOffset = Offset(
        center.dx + textRadius * math.cos(angle - math.pi / 2) - textPainter.width / 2,
        center.dy + textRadius * math.sin(angle - math.pi / 2) - textPainter.height / 2,
      );
      
      textPainter.paint(canvas, textOffset);
    }

    // Draw minor marks
    paint
      ..strokeWidth = 1
      ..color = secondaryColor.withOpacity(0.4);
    
    for (int i = 0; i < 8; i++) {
      if (i % 2 == 1) { // Skip cardinal directions
        final angle = i * math.pi / 4;
        final startRadius = radius * 0.9;
        final endRadius = radius * 0.95;
        
        final start = Offset(
          center.dx + startRadius * math.cos(angle - math.pi / 2),
          center.dy + startRadius * math.sin(angle - math.pi / 2),
        );
        final end = Offset(
          center.dx + endRadius * math.cos(angle - math.pi / 2),
          center.dy + endRadius * math.sin(angle - math.pi / 2),
        );
        
        canvas.drawLine(start, end, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter for the compass needle
class CompassNeedlePainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  CompassNeedlePainter({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final needleLength = size.height * 0.35;
    
    // North pointer (red)
    final northPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    
    final northPath = Path()
      ..moveTo(center.dx, center.dy - needleLength)
      ..lineTo(center.dx - 6, center.dy)
      ..lineTo(center.dx + 6, center.dy)
      ..close();
    
    canvas.drawPath(northPath, northPaint);
    
    // South pointer (white with border)
    final southPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final southBorderPaint = Paint()
      ..color = Colors.grey[600]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    final southPath = Path()
      ..moveTo(center.dx, center.dy + needleLength)
      ..lineTo(center.dx - 6, center.dy)
      ..lineTo(center.dx + 6, center.dy)
      ..close();
    
    canvas.drawPath(southPath, southPaint);
    canvas.drawPath(southPath, southBorderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
