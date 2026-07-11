import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_user.dart';
import '../models/payment_record.dart';

class ReceiptView extends StatelessWidget {
  const ReceiptView({
    super.key,
    required this.habitant,
    required this.collector,
    required this.payment,
  });

  final AppUser habitant;
  final AppUser collector;
  final PaymentRecord payment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101A31),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101A31),
        foregroundColor: Colors.white,
        title: const Text('Reçu de paiement'),
        actions: [
          IconButton(
            tooltip: 'Partager par WhatsApp',
            onPressed: () => _shareOnWhatsApp(context),
            icon: const Icon(Icons.share_outlined),
          ),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            label: const Text('PDF', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Card(
            margin: const EdgeInsets.all(18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            color: const Color(0xFF0F1A34),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFFF5A817),
                    child: Icon(Icons.receipt_long, color: Color(0xFF172747)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'PAIEMENT CONFIRMÉ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    payment.receiptNumber ?? 'REC-XXXX-XXXX',
                    style: const TextStyle(
                      color: Color(0xFF7B8290),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Divider(color: Color(0xFF2D3B5A), height: 30),
                  _ReceiptRow(label: 'Habitant', value: habitant.fullName),
                  _ReceiptRow(label: 'Adresse', value: habitant.address ?? '—'),
                  _ReceiptRow(label: 'Période', value: payment.periodLabel),
                  _ReceiptRow(label: 'Mode', value: payment.status),
                  _ReceiptRow(label: 'Collecteur', value: collector.fullName),
                  _ReceiptRow(
                    label: 'Date',
                    value: _formatDate(payment.paidAt ?? DateTime.now()),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '${payment.amount} F CFA',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF5A817),
                      foregroundColor: const Color(0xFF172747),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => _shareOnWhatsApp(context),
                    child: const Text('Partager le reçu'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} ${_monthName(date.month)} ${date.year} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _shareOnWhatsApp(BuildContext context) async {
    final receiptNumber = payment.receiptNumber ?? payment.id;
    final message = '''Reçu de paiement Sama Gardiennage
N° reçu : $receiptNumber
Habitant : ${habitant.fullName}
Période : ${payment.periodLabel}
Montant : ${payment.amount} F CFA
Date : ${_formatDate(payment.paidAt ?? DateTime.now())}
Collecteur : ${collector.fullName}''';
    final whatsappUrl = Uri.https('wa.me', '/', {'text': message});
    final opened = await launchUrl(
      whatsappUrl,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WhatsApp est indisponible sur cet appareil.'),
        ),
      );
    }
  }

  static String _monthName(int month) {
    const names = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return names[month - 1];
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF7B8290),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
