import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_thingy_91x/providers/mqtt_provider.dart';
import 'package:flutter_thingy_91x/providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_thingy_91x/providers/ble_provider.dart';
import 'package:flutter_thingy_91x/providers/sensor_provider.dart';
import 'package:flutter_thingy_91x/screens/splash_screen.dart';
import 'package:flutter_thingy_91x/theme/app_theme.dart';
import 'package:flutter_thingy_91x/services/ble_service.dart';
import 'package:flutter_thingy_91x/l10n/app_localizations.dart';
import 'package:flutter_thingy_91x/utils/app_logger.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// Importación condicional para manejar web y plataformas móviles
import 'package:permission_handler/permission_handler.dart' if (dart.library.js) 'package:flutter_thingy_91x/utils/web_permission_stub.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar el servicio BLE
  final bleService = BleService();
  await bleService.initialize();
  
  // Configuración específica para cada plataforma
  if (!kIsWeb) {
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        // Solicitar permisos en plataformas móviles
        await Permission.bluetooth.request();
        await Permission.bluetoothScan.request();
        await Permission.bluetoothConnect.request();
        await Permission.location.request();
      } catch (e) {
        AppLogger.logError('Error al solicitar permisos', e);
      }
    }
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => BleProvider()),
        ChangeNotifierProvider(create: (_) => SensorProvider()),
        ChangeNotifierProvider(create: (_) => MQTTProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            title: 'Thingy:91 X Sensor Hub',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            themeMode: ThemeMode.system,
            locale: languageProvider.currentLocale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('es'),
            ],
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
