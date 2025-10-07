import 'package:flutter/material.dart';
import 'package:flutter_thingy_91x/l10n/app_localizations.dart';
import 'package:flutter_thingy_91x/screens/instruccions.dart';
import 'package:flutter_thingy_91x/widgets/language_dialog.dart';
import 'package:video_player/video_player.dart';

class GettingStarted extends StatefulWidget {
  const GettingStarted({super.key});

  @override
  GettingStartedState createState() => GettingStartedState();
}

class GettingStartedState extends State<GettingStarted>
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
        decoration: BoxDecoration(color: Colors.white),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // * video
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 1,
                    height: MediaQuery.of(context).size.height * 0.50,
                    child: VideoPlayer(_videoController),
                  ),

                  // * text
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 32.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFF6CF59),
                            Color(0xFFFF7100),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(34)
                      ),
                      
                      width: 274,
                      height: 132,
                      child: Center(
                        widthFactor: 1.0,
                        heightFactor: 1.0,
                        child: Text(
                          AppLocalizations.of(context)?.gettingStarted ?? 'GETTING STARTED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 45,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
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
                            builder: (_) => const Instruccions(),
                          ),
                        );
                      }
                    },
                    child: Image.asset(
                      'assets/explorersThingy/BotonNaranja.png',
                      width: 79,
                      height: 79,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: LanguageDialog(),
            )
            
          ],
        ),
      ),
    );
  }
}
