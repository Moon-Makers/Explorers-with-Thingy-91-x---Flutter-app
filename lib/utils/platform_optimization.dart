import 'dart:io';
import 'package:flutter/foundation.dart';

/// Utilidad para optimizaciones específicas de plataforma
class PlatformOptimization {
  
  /// Determina si estamos en Android
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  
  /// Determina si estamos en iOS
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  
  /// Duración de animación optimizada según la plataforma
  static Duration getAnimationDuration({
    Duration? androidDuration,
    Duration? iosDuration,
    Duration? defaultDuration,
  }) {
    if (isAndroid && androidDuration != null) {
      return androidDuration;
    } else if (isIOS && iosDuration != null) {
      return iosDuration;
    }
    return defaultDuration ?? const Duration(milliseconds: 300);
  }
  
  /// Duraciones estándar optimizadas
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);
  
  /// Duración de animación rápida para Android, normal para iOS
  static Duration get quickButtonAnimation => isAndroid 
    ? fastAnimation 
    : Duration(milliseconds: 200);
  
  /// Duración de splash optimizada
  static Duration get splashDuration => isAndroid 
    ? const Duration(milliseconds: 1500) 
    : const Duration(milliseconds: 2000);
  
  /// Configuración de pulso para animaciones continuas
  static Duration get pulseAnimation => isAndroid 
    ? const Duration(milliseconds: 2500) 
    : const Duration(milliseconds: 2000);
  
  /// Configuración de rotación 3D
  static Duration get rotation3D => isAndroid 
    ? const Duration(milliseconds: 1000) 
    : const Duration(milliseconds: 800);
  
  /// Número máximo de animaciones concurrentes recomendado
  static int get maxConcurrentAnimations => isAndroid ? 2 : 4;
  
  /// Determina si debemos usar animaciones complejas
  static bool get shouldUseComplexAnimations => !isAndroid || kDebugMode;
  
  /// Determina si debemos usar curvas de animación complejas
  static bool get shouldUseComplexCurves => isIOS;
}
