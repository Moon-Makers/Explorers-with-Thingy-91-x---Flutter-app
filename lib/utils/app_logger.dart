import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class AppLogger {
  static void log(String message, {String? name, Object? error}) {
    if (kDebugMode) {
      developer.log(
        message,
        name: name ?? 'ThingyApp',
        error: error,
      );
    }
  }
  
  static void logError(String message, Object error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      developer.log(
        message,
        name: 'ThingyApp-Error',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
  
  static void logPerformance(String operation, Duration duration) {
    if (kDebugMode) {
      developer.log(
        '$operation took ${duration.inMilliseconds}ms',
        name: 'ThingyApp-Performance',
      );
    }
  }
}
