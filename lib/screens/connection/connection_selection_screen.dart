import 'package:flutter/material.dart';
import 'package:flutter_thingy_91x/screens/connection/examples_menu_screen.dart';
import 'package:flutter_thingy_91x/screens/compass/compass_connection_screen.dart';
import 'package:flutter_thingy_91x/l10n/app_localizations.dart';
import 'package:flutter_thingy_91x/providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ConnectionSelectionScreen extends StatefulWidget {
  const ConnectionSelectionScreen({super.key});

  @override
  State<ConnectionSelectionScreen> createState() => _ConnectionSelectionScreenState();
}

class _ConnectionSelectionScreenState extends State<ConnectionSelectionScreen> {
  @override
  void initState() {
    super.initState();
    // Note: We only disconnect when user explicitly presses logout, 
    // not when returning to this screen via back navigation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
              Theme.of(context).colorScheme.secondary.withOpacity(0.8),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Language selector button
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Consumer<LanguageProvider>(
                builder: (context, languageProvider, child) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _showLanguageDialog(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.language,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                languageProvider.isEnglish ? 'EN' : 'ES',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Main content
            SafeArea(
              child: Column(
                children: [
              const SizedBox(height: 48),
              Text(
                AppLocalizations.of(context)?.selectConnection ?? 'Select Connection Type',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ConnectionCard(
                        title: AppLocalizations.of(context)?.bluetoothConnection ?? 'BLE Connection',
                        subtitle: AppLocalizations.of(context)?.bluetoothDescription ?? 'Connect directly to your device via Bluetooth',
                        // icon: 'assets/images/MoonMakers.png',
                        icon: 'assets/animations/data.json',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ExamplesMenuScreen(connectionType: 'BLE'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _ConnectionCard(
                        title: AppLocalizations.of(context)?.mqttConnection ?? 'MQTT Connection',
                        subtitle: AppLocalizations.of(context)?.mqttDescription ?? 'Connect through MQTT broker',
                        icon: 'assets/animations/cloud.json',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ExamplesMenuScreen(connectionType: 'MQTT'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _ConnectionCard(
                        title: AppLocalizations.of(context)?.compassNavigation ?? 'Compass Navigation',
                        subtitle: AppLocalizations.of(context)?.compassNavigationSubtitle ?? 'Indoor navigation with compass and floor detection',
                        icon: 'assets/images/compass_card.svg',
                        isImageAsset: true,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CompassConnectionScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
);
}

void _showLanguageDialog(BuildContext context) {
  final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
  final l10n = AppLocalizations.of(context);
  
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(l10n?.selectLanguage ?? 'Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
              title: Text(l10n?.english ?? 'English'),
              trailing: languageProvider.isEnglish 
                  ? const Icon(Icons.check, color: Colors.green) 
                  : null,
              onTap: () {
                languageProvider.setLanguage('en');
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Text('🇪🇸', style: TextStyle(fontSize: 24)),
              title: Text(l10n?.spanish ?? 'Español'),
              trailing: languageProvider.isSpanish 
                  ? const Icon(Icons.check, color: Colors.green) 
                  : null,
              onTap: () {
                languageProvider.setLanguage('es');
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
        ],
      );
    },
  );
}
}

class _ConnectionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String icon;
  final bool isImageAsset;
  final VoidCallback onTap;

  const _ConnectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isImageAsset = false,
    required this.onTap,
  });

  @override
  _ConnectionCardState createState() => _ConnectionCardState();
}

class _ConnectionCardState extends State<_ConnectionCard> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  @override
  void initState() {
    super.initState();
    // Optimizado: Animación más rápida y simple para mejor rendimiento en Android
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150), // Reducido de 300 a 150ms
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(_animController); // Sin CurvedAnimation para mejor rendimiento
    
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(_animController); // Sin CurvedAnimation para mejor rendimiento
  }
  
  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Para web, usamos un container sin Hero para evitar problemas de renderizado
    if (kIsWeb) {
      return _buildAnimatedCard(context);
    }
    
    // Para móvil, mantenemos el Hero para las transiciones
    return Hero(
      tag: widget.title,
      child: _buildAnimatedCard(context),
    );
  }
  
  Widget _buildAnimatedCard(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _animController.forward(),
      onExit: (_) => _animController.reverse(),
      child: GestureDetector(
        onTapDown: (_) => _animController.forward(),
        onTapUp: (_) {
          _animController.reverse();
          widget.onTap();
        },
        onTapCancel: () => _animController.reverse(),
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Material(
                  color: Colors.transparent,
                  child: _buildCardContent(context),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Extraído el contenido de la tarjeta a un método separado para reutilizarlo
  Widget _buildCardContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: widget.isImageAsset 
                ? SvgPicture.asset(
                    widget.icon,
                    width: 80,
                    height: 80,
                    colorFilter: widget.icon.contains('witch') 
                        ? null
                        : widget.icon.contains('compass')
                            ? null  // No color filter for compass images
                            : ColorFilter.mode(
                                Theme.of(context).colorScheme.primary,
                                BlendMode.srcIn,
                              ),
                  )
                : Lottie.asset(
                    widget.icon,
                    repeat: true,
                  ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Envolver el texto en un Container puede ayudar con problemas de renderizado en web
                Container(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_animController.value * -4, 0),
                child: const Icon(Icons.arrow_forward_ios),
              );
            },
          ),
        ],
      ),
    );
  }
}