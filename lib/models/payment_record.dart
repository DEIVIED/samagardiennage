import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.habitantId,
    required this.amount,
    required this.month,
    required this.year,
    required this.status,
    this.paidAt,
    this.collectorId,
    this.receiptNumber,
  });

  final String id;
  final String habitantId;
  final int amount;
  /// Mois de la cotisation, de 1 (janvier) à 12 (décembre).
  final int month;
  /// Année concernée par la cotisation, indépendante de la date d'encaissement.
  final int year;
  final String status;
  final DateTime? paidAt;
  final String? collectorId;
  final String? receiptNumber;

  bool get isPaid => status.toLowerCase() == 'paye';

  String get periodLabel => '${monthName(month)} $year';

  static String monthName(int month) {
    const names = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
    ];
    return names[month.clamp(1, 12).toInt() - 1];
  }

  factory PaymentRecord.fromFirestore(String id, Map<String, dynamic> data) {
    final paidAtValue = data['paidAt'];
    return PaymentRecord(
      id: id,
      habitantId: (data['habitantId'] ?? '').toString(),
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      month: _monthFromValue(data['month']),
      year: (data['year'] as num?)?.toInt() ??
          (data['years'] as num?)?.toInt() ??
          _yearFromLegacyValue(data['month']?.toString()),
      status: (data['status'] ?? '').toString(),
      paidAt: paidAtValue is Timestamp ? paidAtValue.toDate() : null,
      collectorId: data['collectorId']?.toString(),
      receiptNumber: data['receiptNumber']?.toString(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'habitantId': habitantId,
      'amount': amount,
      'month': month,
      'year': year,
      'status': status,
      'paidAt': paidAt == null ? null : Timestamp.fromDate(paidAt!),
      'collectorId': collectorId,
      'receiptNumber': receiptNumber,
    };
  }

  static int _yearFromMonth(String? value) {
    final match = RegExp(r'(19|20)\d{2}').firstMatch(value ?? '');
    return match == null ? DateTime.now().year : int.parse(match.group(0)!);
  }

  static int _yearFromLegacyValue(String? value) => _yearFromMonth(value);

  static int _monthFromValue(dynamic value) {
    if (value is num) return value.toInt().clamp(1, 12).toInt();
    final raw = value?.toString().toLowerCase() ?? '';
    final number = int.tryParse(raw);
    if (number != null) return number.clamp(1, 12).toInt();
    const names = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ];
    final index = names.indexWhere(raw.contains);
    return index < 0 ? 1 : index + 1;
  }
}
