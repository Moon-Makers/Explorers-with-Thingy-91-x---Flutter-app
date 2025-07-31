import 'package:flutter/material.dart';
import 'package:flutter_thingy_91x/l10n/app_localizations.dart';

/// Compact bottom navigation panel with icon tabs
class CompassBottomPanel extends StatelessWidget {
  final Widget infoContent;
  final Widget devicesContent;
  final Widget navigationContent;
  final ScrollController scrollController;

  const CompassBottomPanel({
    super.key,
    required this.infoContent,
    required this.devicesContent,
    required this.navigationContent,
    required this.scrollController,
  });

  String _getLocalizedText(BuildContext context, String englishText, String spanishText) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      final locale = Localizations.localeOf(context);
      return locale.languageCode == 'es' ? spanishText : englishText;
    }
    
    // Map common strings to proper localization keys
    switch (englishText) {
      case 'Info':
        return localizations.info;
      case 'Devices':
        return localizations.devices;
      case 'Navigate':
        return localizations.navigate;
      default:
        final locale = Localizations.localeOf(context);
        return locale.languageCode == 'es' ? spanishText : englishText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 50,
            height: 5,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          
          // Compact tab bar
          Container(
            height: 60,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                _CompactTab(
                  icon: Icons.info_outline,
                  label: _getLocalizedText(context, 'Info', 'Info'),
                  isSelected: true, // Default selection
                ),
                _CompactTab(
                  icon: Icons.devices,
                  label: _getLocalizedText(context, 'Devices', 'Dispositivos'),
                  isSelected: false,
                ),
                _CompactTab(
                  icon: Icons.navigation,
                  label: _getLocalizedText(context, 'Navigate', 'Navegar'),
                  isSelected: false,
                ),
              ],
            ),
          ),
          
          // Content area - smaller height for compact design
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: TabBarView(
                children: [
                  infoContent,
                  devicesContent,
                  navigationContent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;

  const _CompactTab({
    required this.icon,
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected 
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(25),
            onTap: () {
              // Handle tab selection
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isSelected 
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[600],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected 
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
