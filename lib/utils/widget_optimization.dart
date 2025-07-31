import 'package:flutter/material.dart';
import 'platform_optimization.dart';

/// Utilidades para optimizar el rendimiento de widgets
class WidgetOptimization {
  
  /// Crea un AnimatedBuilder optimizado que no reconstruye innecesariamente
  static Widget buildOptimizedAnimatedBuilder({
    required Animation<double> animation,
    required Widget Function(BuildContext context, Widget? child) builder,
    Widget? child,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: builder,
      child: child,
    );
  }
  
  /// Envuelve un widget en RepaintBoundary para optimizar el repintado
  static Widget withRepaintBoundary(Widget child) {
    return RepaintBoundary(child: child);
  }
  
  /// Crea un Container optimizado con menos reconstrucciones
  static Widget buildOptimizedContainer({
    Widget? child,
    Color? color,
    Decoration? decoration,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? width,
    double? height,
    AlignmentGeometry? alignment,
  }) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      alignment: alignment,
      decoration: decoration,
      child: child,
    );
  }
  
  /// Determina si debe usar Hero widgets (puede ser pesado en Android)
  static bool shouldUseHero() {
    return PlatformOptimization.isIOS || !PlatformOptimization.isAndroid;
  }
  
  /// Envuelve un widget en Hero solo si es beneficioso para la plataforma
  static Widget conditionalHero({
    required String tag,
    required Widget child,
  }) {
    if (shouldUseHero()) {
      return Hero(tag: tag, child: child);
    }
    return child;
  }
  
  /// Crea un LinearProgressIndicator optimizado
  static Widget buildOptimizedProgressIndicator({
    double? value,
    Color? backgroundColor,
    Color? valueColor,
    double minHeight = 4.0,
  }) {
    return RepaintBoundary(
      child: LinearProgressIndicator(
        value: value,
        backgroundColor: backgroundColor,
        valueColor: valueColor != null 
            ? AlwaysStoppedAnimation<Color>(valueColor)
            : null,
        minHeight: minHeight,
      ),
    );
  }
  
  /// Crea un Transform optimizado que usa menos recursos
  static Widget buildOptimizedTransform({
    required Matrix4 transform,
    required Widget child,
    AlignmentGeometry? alignment,
  }) {
    return RepaintBoundary(
      child: Transform(
        transform: transform,
        alignment: alignment,
        child: child,
      ),
    );
  }
}
