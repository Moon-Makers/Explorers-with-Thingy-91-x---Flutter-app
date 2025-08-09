import 'package:flutter/material.dart';
import 'package:flutter_thingy_91x/screens/getting_started.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();

    // Inicializar el video
    _videoController =
        VideoPlayerController.asset('assets/explorersThingy/anim/Inicio.mp4')
          ..setLooping(true)
          ..setVolume(0)
          ..initialize().then((_) {
            setState(() {});
            _videoController.play();
          });

    // Timer para navegar a la siguiente pantalla (optimizado por plataforma)
    Timer(const Duration(milliseconds: 4700), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const GettingStarted()),
        );
      }
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.secondary,
              Theme.of(context).colorScheme.primary,
            ],
            stops: [0.5, 0.9],
            tileMode: TileMode.clamp,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.05),
              // * logos SVG
              Image.asset(
                'assets/explorersThingy/logos.png',
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.15,
                fit: BoxFit.contain,
              ),

              // * animacion de carga en gif
              Lottie.asset(
                'assets/explorersThingy/anim/Barra.json',
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.10,
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.20),

              // * video
              SizedBox(
                width: MediaQuery.of(context).size.width * 1,
                height: MediaQuery.of(context).size.height * 0.50,
                child: VideoPlayer(_videoController),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
