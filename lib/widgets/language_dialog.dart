import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_thingy_91x/l10n/app_localizations.dart';
import 'package:flutter_thingy_91x/providers/language_provider.dart';

class LanguageDialog extends StatelessWidget {

  static Future<void> show(BuildContext context) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context);
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return LanguageDialog._internal(l10n: l10n, languageProvider: languageProvider);
      },
    );
  }

  final AppLocalizations? l10n;
  final LanguageProvider languageProvider;

  const LanguageDialog._internal({required this.l10n, required this.languageProvider, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
  }
}
