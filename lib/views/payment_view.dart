import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/payment_record.dart';

class PaymentView extends StatefulWidget {
  const PaymentView({
    super.key,
    required this.habitant,
    required this.collector,
    required this.onPaymentConfirmed,
    this.paymentHistory = const [],
  });
  final AppUser habitant;
  final AppUser collector;
  final Future<void> Function(PaymentRecord) onPaymentConfirmed;
  final List<PaymentRecord> paymentHistory;
  @override
  State<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView> {
  static const _navy = Color(0xFF172747);
  static const _gold = Color(0xFFF5A817);
  static const int _monthlyAmount = 2000;
  late final List<_PaymentPeriod> _unpaidPeriods;
  late _PaymentPeriod _selectedPeriod;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _unpaidPeriods = _findUnpaidPeriods(widget.paymentHistory);
    _selectedPeriod = _unpaidPeriods.first;
  }

  List<_PaymentPeriod> _findUnpaidPeriods(List<PaymentRecord> history) {
    final now = DateTime.now();
    final paidKeys = <String>{};
    final outstandingByKey = <String, PaymentRecord>{};
    for (final payment in history) {
      final status = payment.status.trim().toLowerCase();
      final key = '${payment.year}-${payment.month}';
      if (status == 'paye') {
        paidKeys.add(key);
        outstandingByKey.remove(key);
      } else if (!paidKeys.contains(key)) {
        outstandingByKey[key] = payment;
      }
    }
    final periods = <_PaymentPeriod>[];
    // Toutes les échéances déjà passées de l'année en cours sont dues
    // lorsqu'aucun paiement validé n'existe pour le mois concerné.
    for (var month = 1; month <= now.month; month++) {
      final key = '${now.year}-$month';
      if (!paidKeys.contains(key)) {
        periods.add(_PaymentPeriod(month, now.year, outstandingByKey[key]?.id));
      }
    }
    // Les impayés des années précédentes restent également payables.
    for (final entry in outstandingByKey.entries) {
      final payment = entry.value;
      final key = entry.key;
      final isCurrentPastPeriod =
          payment.year == now.year && payment.month <= now.month;
      if (!paidKeys.contains(key) &&
          (payment.year < now.year || isCurrentPastPeriod)) {
        if (!periods.any(
          (period) =>
              period.year == payment.year && period.month == payment.month,
        )) {
          periods.add(_PaymentPeriod(payment.month, payment.year, payment.id));
        }
      }
    }
    periods.sort((a, b) => a.compareTo(b));
    return periods;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final now = DateTime.now();
    final payment = PaymentRecord(
      // Une ancienne fiche impayée est réutilisée afin d'éviter un doublon.
      id:
          _selectedPeriod.existingId ??
          'payment_${widget.habitant.id}_${_selectedPeriod.year}_${_selectedPeriod.month}',
      habitantId: widget.habitant.id,
      amount: _monthlyAmount,
      month: _selectedPeriod.month,
      year: _selectedPeriod.year,
      status: 'paye',
      paidAt: now,
      collectorId: widget.collector.id,
      receiptNumber: 'REC-${now.year}-${now.millisecondsSinceEpoch}',
    );
    setState(() => _isSubmitting = true);
    try {
      await widget.onPaymentConfirmed(payment);
      if (mounted) {
        Navigator.of(context).pop(payment);
      }
    } catch (_) {
      if (mounted) setState(() => _isSubmitting = false);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EC),
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: const Text('Enregistrer un paiement'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.habitant.fullName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: _navy,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            widget.habitant.address ?? 'Adresse non renseignée',
            style: const TextStyle(color: Color(0xFF7B8290)),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Montant mensuel dû',
                  style: TextStyle(fontSize: 12, color: Color(0xFF7B8290)),
                ),
                SizedBox(height: 6),
                Text(
                  '2 000 XOF',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: _navy,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Mois impayés à régler',
            style: TextStyle(fontWeight: FontWeight.w900, color: _navy),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<_PaymentPeriod>(
            value: _selectedPeriod,
            decoration: InputDecoration(
              labelText: 'Mois et année',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: _unpaidPeriods
                .map(
                  (period) => DropdownMenuItem(
                    value: period,
                    child: Text(
                      '${PaymentRecord.monthName(period.month)} ${period.year}',
                    ),
                  ),
                )
                .toList(),
            onChanged: (period) {
              if (period != null) setState(() => _selectedPeriod = period);
            },
          ),
          const SizedBox(height: 8),
          Text(
            '${_unpaidPeriods.length} échéance(s) impayée(s) détectée(s) jusqu’au mois en cours.',
            style: const TextStyle(fontSize: 11, color: Color(0xFF7B8290)),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: _navy,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            icon: _isSubmitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(
              _isSubmitting ? 'Enregistrement...' : 'Encaisser 2 000 XOF',
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentPeriod implements Comparable<_PaymentPeriod> {
  const _PaymentPeriod(this.month, this.year, [this.existingId]);
  final int month;
  final int year;
  final String? existingId;
  @override
  int compareTo(_PaymentPeriod other) => year == other.year
      ? month.compareTo(other.month)
      : year.compareTo(other.year);
  @override
  bool operator ==(Object other) =>
      other is _PaymentPeriod && other.month == month && other.year == year;
  @override
  int get hashCode => Object.hash(month, year);
}
