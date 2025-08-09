import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_thingy_91x/screens/connection/connection_selection_screen.dart';
import 'package:flutter_thingy_91x/providers/language_provider.dart';
import 'package:flutter_thingy_91x/l10n/app_localizations.dart';
import 'package:flutter_thingy_91x/utils/platform_optimization.dart';
import 'package:flutter_thingy_91x/widgets/language_dialog.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class Instruccions extends StatefulWidget {
  const Instruccions({super.key});

  @override
  InstruccionsState createState() => InstruccionsState();
}

class InstruccionsState extends State<Instruccions>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();

    // Inicializar el video
    _videoController =
        VideoPlayerController.asset(
            'assets/explorersThingy/anim/Despliegue.mp4',
          )
          ..setLooping(true)
          ..setVolume(0)
          ..initialize().then((_) {
            setState(() {});
            _videoController.play();
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
            colors: [Color(0xFFF6CF59), Color(0xFFFF7100)],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [

                  SizedBox(
                    height: 20,
                  ),

                  Center(
                    child: Image.asset(
                      'assets/explorersThingy/intrciones-texto.png',
                      width: MediaQuery.of(context).size.width * 0.8,
                      fit: BoxFit.contain,
                    ),
                  ),

                  Center(
                    child: Column(
                      children: [
                        Text(
                          AppLocalizations.of(context)?.getItFrom ?? "Get it from",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            fontFamily: "FatFrank-Heavy"
                          ),
                        ),

                        Image.asset(
                          "assets/explorersThingy/HacksterioBoton.png",
                          width: 250,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                    height: 20,
                  ),

                  // * button to navigate to connection selection screen
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.zero,

                    ),
                    onPressed: () {
                      if (mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const ConnectionSelectionScreen(),
                          ),
                        );
                      }
                    },
                    child: Image.asset(
                      'assets/explorersThingy/BotonBlanco.png',
                      width: 79,
                      height: 79,
                      fit: BoxFit.contain,
                    ),
                  ),

                  SizedBox(
                    height: 10,
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
