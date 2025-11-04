import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final List<Map<String, dynamic>> paymentMethods = [
      {
        'type': 'Visa',
        'last4': '1234',
        'holder': 'Nguyen Van A',
        'expiry': '08/27',
        'isDefault': true,
      },
      {
        'type': 'Mastercard',
        'last4': '9876',
        'holder': 'Tran Thi B',
        'expiry': '11/26',
        'isDefault': false,
      },
      {
        'type': 'Momo Wallet',
        'last4': '5566',
        'holder': 'Nguyen Van A',
        'expiry': '--/--',
        'isDefault': false,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.paymentMethods),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: paymentMethods.length,
        itemBuilder: (context, index) {
          final method = paymentMethods[index];
          final type = method['type'] as String;
          final last4 = method['last4'] as String;
          final holder = method['holder'] as String;
          final expiry = method['expiry'] as String;
          final isDefault = method['isDefault'] == true;
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Text(
                      type.substring(0, 1),
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                            type,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isDefault)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Default',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '**** **** **** $last4',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Card Holder: $holder',
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        Text(
                          'Expiry: $expiry',
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: const Text('Set Default'),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Add Method'),
      ),
    );
  }
}
