import 'dart:async';
import 'package:flutter/material.dart';

import '../controllers/habitants_controller.dart';
import '../models/app_user.dart';
import '../models/payment_record.dart';
import '../services/firestore_service.dart';
import 'app_bottom_navigation.dart';
import 'collector_dashboard_view.dart';
import 'habitant_qr_scanner_view.dart';
import 'habitants_view.dart';
import 'payment_view.dart';
import 'receipt_view.dart';
import 'statistics_view.dart';

enum PaymentFilter { all, paid, partial, unpaid }

class PaymentHistoryView extends StatefulWidget {
  const PaymentHistoryView({super.key, this.user});

  final AppUser? user;

  @override
  State<PaymentHistoryView> createState() => _PaymentHistoryViewState();
}

class _PaymentHistoryViewState extends State<PaymentHistoryView> {
  static const _navy = Color(0xFF172747);
  static const _gold = Color(0xFFF5A817);
  final _controller = HabitantsController();
  late int _year = DateTime.now().year;
  int? _month;
  PaymentFilter _filter = PaymentFilter.all;
  String _query = '';
  late Future<_PaymentPageData> _data = _load();
  StreamSubscription<void>? _changesSub;

  Future<_PaymentPageData> _load() async {
    final results = await Future.wait([
      _controller.fetchPaymentsForYear(_year),
      _controller.fetchHabitants(),
    ]);
    return _PaymentPageData(
      results[0] as List<PaymentRecord>,
      results[1] as List<AppUser>,
    );
  }

  void _reload() => setState(() => _data = _load());

  Future<void> _scanAndPay() async {
    final collector = widget.user;
    if (collector == null) return;

    final habitant = await Navigator.of(context).push<AppUser>(
      MaterialPageRoute(
        builder: (_) => HabitantQrScannerView(controller: _controller),
      ),
    );
    if (!mounted || habitant == null) return;

    final history = await _controller.fetchPaymentHistory(habitant.id);
    if (!mounted) return;
    final payment = await Navigator.of(context).push<PaymentRecord>(
      MaterialPageRoute(
        builder: (_) => PaymentView(
          habitant: habitant,
          collector: collector,
          paymentHistory: history,
          onPaymentConfirmed: _controller.savePayment,
        ),
      ),
    );
    if (!mounted || payment == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReceiptView(
          habitant: habitant,
          collector: collector,
          payment: payment,
        ),
      ),
    );
    if (mounted) _reload();
  }

  void _openReceipt(PaymentRecord payment, _PaymentPageData data) {
    if (!payment.isPaid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le reçu est disponible après validation du paiement.')),
      );
      return;
    }
    final habitant = data.habitant(payment.habitantId);
    if (habitant == null) return;
    final collector = widget.user ??
        AppUser(
          id: payment.collectorId ?? '',
          fullName: payment.collectorId ?? 'Collecteur non renseigné',
          email: '',
          type: AppUserType.collecteur,
          isActive: true,
        );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReceiptView(
          habitant: habitant,
          collector: collector,
          payment: payment,
        ),
      ),
    );
  }

  List<PaymentRecord> _filtered(_PaymentPageData data) {
    return data.payments.where((payment) {
      final name = data.habitantName(payment.habitantId).toLowerCase();
      final matchesMonth = _month == null || payment.month == _month;
      final matchesQuery = name.contains(_query.toLowerCase());
      final matchesStatus = switch (_filter) {
        PaymentFilter.all => true,
        PaymentFilter.paid => payment.status.toLowerCase() == 'paye',
        PaymentFilter.partial => payment.status.toLowerCase() == 'partiel',
        PaymentFilter.unpaid => payment.status.toLowerCase() == 'impaye',
      };
      return matchesMonth && matchesQuery && matchesStatus;
    }).toList()..sort(
      (a, b) =>
          (b.paidAt ?? DateTime(1900)).compareTo(a.paidAt ?? DateTime(1900)),
    );
  }

  @override
  void initState() {
    super.initState();
    _changesSub = FirestoreService.changes.listen((_) => _reload());
  }

  @override
  void dispose() {
    _changesSub?.cancel();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EC),
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: const Text('Paiements'),
        actions: [
          TextButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Export disponible prochainement.')),
            ),
            icon: const Icon(Icons.file_download_outlined, size: 17),
            label: const Text('Export'),
            style: TextButton.styleFrom(foregroundColor: _gold),
          ),
        ],
      ),
      body: FutureBuilder<_PaymentPageData>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(
              child: Text('Chargement impossible : ${snapshot.error}'),
            );
          final data = snapshot.data!;
          final payments = _filtered(data);
          final collected = payments
              .where((p) => p.status.toLowerCase() != 'impaye')
              .fold(0, (sum, p) => sum + p.amount);
          return Column(
            children: [
              _filters(),
              _summary(collected, payments),
              Expanded(
                child: payments.isEmpty
                    ? const Center(
                        child: Text('Aucun paiement pour ces filtres.'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                        itemCount: payments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, index) => _PaymentTile(
                          payment: payments[index],
                          name: data.habitantName(payments[index].habitantId),
                          onTap: () => _openReceipt(payments[index], data),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _PaymentNav(user: widget.user),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'scan-payment-habitant',
        backgroundColor: _gold,
        foregroundColor: _navy,
        onPressed: widget.user == null ? null : _scanAndPay,
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: const Text('Scanner'),
      ),
    );
  }

  Widget _filters() => Container(
    color: _navy,
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _dropdown<int?>(
                value: _month,
                label: 'Tous les mois',
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Tous les mois'),
                  ),
                  ...List.generate(
                    12,
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text(
                        '${i + 1} - ${PaymentRecord.monthName(i + 1)}',
                      ),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _month = value),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 100,
              child: _dropdown<int>(
                value: _year,
                label: 'Année',
                items: [
                  for (
                    var year = DateTime.now().year - 2;
                    year <= DateTime.now().year + 1;
                    year++
                  )
                    DropdownMenuItem(value: year, child: Text('$year')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _year = value);
                    _reload();
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          onChanged: (value) => setState(() => _query = value.trim()),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Rechercher un habitant...',
            hintStyle: const TextStyle(color: Color(0xFF9BA6B8), fontSize: 12),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF9BA6B8)),
            filled: true,
            fillColor: const Color(0xFF30405F),
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final filter in PaymentFilter.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_filterLabel(filter)),
                    selected: _filter == filter,
                    selectedColor: _gold,
                    onSelected: (_) => setState(() => _filter = filter),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _dropdown<T>({
    required T value,
    required String label,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) => DropdownButtonFormField<T>(
    value: value,
    items: items,
    onChanged: onChanged,
    dropdownColor: Colors.white,
    style: const TextStyle(color: _navy, fontSize: 12),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF9BA6B8), fontSize: 10),
      filled: true,
      fillColor: const Color(0xFF30405F),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    ),
  );

  Widget _summary(int collected, List<PaymentRecord> payments) => Padding(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        Expanded(child: _metric('TOTAL', '$collected F')),
        const SizedBox(width: 8),
        Expanded(
          child: _metric(
            'VALIDÉS',
            '${payments.where((p) => p.status == 'paye').length}',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _metric(
            'PARTIELS',
            '${payments.where((p) => p.status == 'partiel').length}',
          ),
        ),
      ],
    ),
  );
  Widget _metric(String title, String value) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
    ),
    child: Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 8,
            color: Color(0xFF7B8290),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: _navy,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
      ],
    ),
  );
  String _filterLabel(PaymentFilter value) => switch (value) {
    PaymentFilter.all => 'Tous',
    PaymentFilter.paid => 'Validés',
    PaymentFilter.partial => 'Partiels',
    PaymentFilter.unpaid => 'Impayés',
  };
}

class _PaymentPageData {
  const _PaymentPageData(this.payments, this.habitants);
  final List<PaymentRecord> payments;
  final List<AppUser> habitants;
  String habitantName(String id) {
    for (final habitant in habitants) {
      if (habitant.id == id) return habitant.fullName;
    }
    return 'Habitant inconnu';
  }

  AppUser? habitant(String id) {
    for (final habitant in habitants) {
      if (habitant.id == id) return habitant;
    }
    return null;
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.payment,
    required this.name,
    required this.onTap,
  });
  final PaymentRecord payment;
  final String name;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final color = payment.status == 'paye'
        ? const Color(0xFF2E8B57)
        : payment.status == 'partiel'
        ? const Color(0xFFF5A817)
        : const Color(0xFFD2473F);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: .15),
            child: Icon(Icons.payments_outlined, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF172747),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  payment.periodLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF7B8290),
                  ),
                ),
                Text(
                  payment.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${payment.amount} F',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF172747),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _PaymentNav extends StatelessWidget {
  const _PaymentNav({this.user});
  final AppUser? user;
  @override
  Widget build(BuildContext context) =>
      AppBottomNavigation(currentIndex: 2, user: user);
}
