import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final Map<String, bool> _settings = {
    'Booking Confirmations': true,
    'Price Alerts': false,
    'Special Offers': true,
    'Chat Notifications': false,
    'Travel Tips': true,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Customize how you want to hear from us.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          ..._settings.entries.map((entry) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: SwitchListTile(
                title: Text(entry.key),
                subtitle: Text(_getSubtitle(entry.key)),
                value: entry.value,
                onChanged: (value) {
                  setState(() {
                    _settings[entry.key] = value;
                  });
                },
              ),
            );
          }),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.save),
            label: const Text('Save Preferences'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSubtitle(String key) {
    switch (key) {
      case 'Booking Confirmations':
        return 'Receive updates about your reservations and itinerary.';
      case 'Price Alerts':
        return 'Stay informed when room prices drop for saved searches.';
      case 'Special Offers':
        return 'Get exclusive promotions and partner discounts.';
      case 'Chat Notifications':
        return 'Know when hotel owners reply to your messages.';
      case 'Travel Tips':
        return 'Weekly recommendations tailored to your interests.';
      default:
        return '';
    }
  }
}
