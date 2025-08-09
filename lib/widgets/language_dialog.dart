import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_thingy_91x/l10n/app_localizations.dart';
import 'package:flutter_thingy_91x/providers/language_provider.dart';

class LanguageDialog extends StatelessWidget {
  const LanguageDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: const Color.fromRGBO(0, 0, 0, 0),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
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
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
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
  }
}
