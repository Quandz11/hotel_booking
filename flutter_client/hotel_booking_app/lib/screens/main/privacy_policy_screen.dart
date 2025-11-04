import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final sections = [
      {
        'title': 'Data Collection',
        'content':
            'We collect information you provide such as name, email, and booking preferences to deliver our services. We also gather device and usage data to improve app performance.',
      },
      {
        'title': 'How We Use Data',
        'content':
            'Your data is used to process reservations, personalize recommendations, provide customer support, and send important updates related to your bookings.',
      },
      {
        'title': 'Sharing Information',
        'content':
            'We only share necessary details with hotel partners to complete your reservation. We never sell your personal information to third parties.',
      },
      {
        'title': 'Your Choices',
        'content':
            'You can update profile information, manage notification preferences, and request data deletion at any time via the settings menu or by contacting support.',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.privacyPolicy),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final section = sections[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section['title']!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    section['content']!,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
