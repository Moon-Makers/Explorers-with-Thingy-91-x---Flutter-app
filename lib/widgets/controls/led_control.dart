import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ble_provider.dart';

class LedControl extends StatelessWidget {
  const LedControl({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<BleProvider>(
      builder: (context, provider, child) {
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Control LED',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Switch(
                      value: provider.isLedOn,
                      onChanged: (value) async {
                        final success = await provider.toggleLed(value);
                        if (!success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Error al controlar el LED'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Icon(
                  Icons.lightbulb,
                  color: provider.isLedOn ? Colors.yellow : Colors.grey,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  provider.isLedOn ? 'LED Encendido' : 'LED Apagado',
                  style: TextStyle(
                    color: provider.isLedOn ? Colors.yellow[800] : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}