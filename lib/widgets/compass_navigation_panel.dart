import 'package:flutter/material.dart';
import 'package:flutter_thingy_91x/l10n/app_localizations.dart';

/// Widget that shows navigation instructions
class CompassNavigationPanel extends StatelessWidget {
  final String? selectedTargetName;
  final List<dynamic> navigationSteps; // Using dynamic to avoid type conflicts
  final VoidCallback onCancelNavigation;

  const CompassNavigationPanel({
    super.key,
    required this.selectedTargetName,
    required this.navigationSteps,
    required this.onCancelNavigation,
  });

  String _getLocalizedText(BuildContext context, String englishText, String spanishText) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      final locale = Localizations.localeOf(context);
      return locale.languageCode == 'es' ? spanishText : englishText;
    }
    
    // Map common strings to proper localization keys
    switch (englishText) {
      case 'To':
        return 'A'; // Simple translation
      case 'Cancel':
        return localizations.cancel;
      default:
        final locale = Localizations.localeOf(context);
        return locale.languageCode == 'es' ? spanishText : englishText;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (selectedTargetName == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.navigation,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _getLocalizedText(
                context,
                'Select a device to navigate',
                'Selecciona un dispositivo para navegar'
              ),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Navigation header
          Row(
            children: [
              Icon(
                Icons.navigation,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_getLocalizedText(context, "To", "A")} $selectedTargetName',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: onCancelNavigation,
                child: Text(_getLocalizedText(context, 'Cancel', 'Cancelar')),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Navigation steps
          Expanded(
            child: navigationSteps.isEmpty
              ? Center(
                  child: Text(
                    _getLocalizedText(context, 'Calculating route...', 'Calculando ruta...'),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: navigationSteps.length,
                  itemBuilder: (context, index) {
                    final step = navigationSteps[index];
                    final isCurrentStep = index == 0;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: isCurrentStep ? 3 : 1,
                      color: isCurrentStep ? Colors.blue[50] : null,
                      child: ListTile(
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCurrentStep 
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[300],
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isCurrentStep ? Colors.white : Colors.grey[600],
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          step.instruction,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isCurrentStep ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        subtitle: step.distance > 0
                          ? Text(
                              '${step.distance.toStringAsFixed(0)}m',
                              style: const TextStyle(fontSize: 12),
                            )
                          : null,
                        trailing: isCurrentStep 
                          ? Icon(
                              Icons.my_location,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            )
                          : null,
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
