import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_thingy_91x/screens/connection/connection_selection_screen.dart';
import 'package:flutter_thingy_91x/providers/language_provider.dart';
import 'package:flutter_thingy_91x/l10n/app_localizations.dart';
import 'package:flutter_thingy_91x/utils/platform_optimization.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _colorAnimationController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    
    // Controlador para la animación de color (optimizado con PlatformOptimization)
    _colorAnimationController = AnimationController(
      duration: PlatformOptimization.splashDuration,
      vsync: this,
    );
    
    // Animación que cambia de negro a blanco (con curva optimizada)
    _colorAnimation = ColorTween(
      begin: Colors.black,
      end: Colors.white,
    ).animate(PlatformOptimization.shouldUseComplexCurves
      ? CurvedAnimation(
          parent: _colorAnimationController,
          curve: Curves.easeInOut,
        )
      : _colorAnimationController); // Sin curva en Android para mejor rendimiento
    
    // Iniciar la animación
    _colorAnimationController.forward();
    
    // Timer para navegar a la siguiente pantalla (optimizado por plataforma)
    Timer(PlatformOptimization.splashDuration, () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ConnectionSelectionScreen()),
        );
      }
    });
  }
  
  @override
  void dispose() {
    _colorAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // decoration: BoxDecoration(
        //   gradient: LinearGradient(
        //     begin: Alignment.topLeft,
        //     end: Alignment.bottomRight,
        //     colors: [
        //       Theme.of(context).colorScheme.primary,
        //       Theme.of(context).colorScheme.secondary,
        //     ],
        //   ),
        // ),
        decoration: BoxDecoration(
          color: Colors.black,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // SVG con animación de color
              AnimatedBuilder(
                animation: _colorAnimationController,
                builder: (context, child) {
                  return SvgPicture.asset(
                    'assets/images/logo.svg',
                    width: 150,
                    height: 150,
                    colorFilter: ColorFilter.mode(
                      _colorAnimation.value!,
                      BlendMode.srcIn,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Consumer<LanguageProvider>(
                builder: (context, languageProvider, child) {
                  final l10n = AppLocalizations.of(context);
                  return Column(
                    children: [
                      Text(
                        l10n?.appTitle ?? 'Thingy:91 X',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n?.homeSubtitle ?? 'Connect to your Nordic Thingy:91 X device',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 48),
              // Indicador de progreso que avanza con la animación
              AnimatedBuilder(
                animation: _colorAnimationController,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: _colorAnimationController.value,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    backgroundColor: Colors.white.withOpacity(0.3),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

