import 'package:flutter/material.dart';

import '../controllers/habitants_controller.dart';
import '../models/app_user.dart';
import '../models/payment_record.dart';
import 'app_bottom_navigation.dart';

class StatisticsView extends StatefulWidget {
  const StatisticsView({super.key, this.user});
  final AppUser? user;

  @override
  State<StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<StatisticsView> {
  static const _navy = Color(0xFF172747);
  static const _gold = Color(0xFFF5A817);
  final _controller = HabitantsController();
  late int _year = DateTime.now().year;
  late Future<List<PaymentRecord>> _payments = _load();

  Future<List<PaymentRecord>> _load() => _controller.fetchPaymentsForYear(_year);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EC),
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: const Text('Statistiques'),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _year,
              dropdownColor: _navy,
              iconEnabledColor: _gold,
              style: const TextStyle(color: Colors.white),
              items: [for (var year = DateTime.now().year - 2; year <= DateTime.now().year + 1; year++) DropdownMenuItem(value: year, child: Text('$year'))],
              onChanged: (year) { if (year != null) setState(() { _year = year; _payments = _load(); }); },
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: FutureBuilder<List<PaymentRecord>>(
        future: _payments,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Chargement impossible : ${snapshot.error}'));
          final payments = snapshot.data ?? [];
          final paid = payments.where((p) => p.status.toLowerCase() == 'paye').length;
          final partial = payments.where((p) => p.status.toLowerCase() == 'partiel').length;
          final unpaid = payments.where((p) => p.status.toLowerCase() == 'impaye').length;
          final collected = payments.where((p) => p.status.toLowerCase() != 'impaye').fold(0, (sum, p) => sum + p.amount);
          final byMonth = <int, int>{for (var i = 1; i <= 12; i++) i: 0};
          for (final payment in payments) { final index = payment.month; byMonth[index] = (byMonth[index] ?? 0) + payment.amount; }
          final max = byMonth.values.fold(1, (value, element) => element > value ? element : value);
          return ListView(padding: const EdgeInsets.all(18), children: [
            Text('Bilan $_year', style: const TextStyle(color: _navy, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            Row(children: [Expanded(child: _card('Collecté', '$collected F', _gold)), const SizedBox(width: 10), Expanded(child: _card('Paiements', '${payments.length}', _navy))]),
            const SizedBox(height: 18),
            const Text('Collecte mensuelle (F CFA)', style: TextStyle(fontWeight: FontWeight.w900, color: _navy)),
            const SizedBox(height: 12),
            Container(height: 185, padding: const EdgeInsets.all(16), decoration: _box(), child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [for (var month = 1; month <= 12; month++) Expanded(child: _bar(month, byMonth[month]!, max))])),
            const SizedBox(height: 18),
            Container(padding: const EdgeInsets.all(18), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Statut des habitants', style: TextStyle(fontWeight: FontWeight.w900, color: _navy)), const SizedBox(height: 12), _status('Payé', paid, const Color(0xFF2E8B57)), _status('Partiel', partial, _gold), _status('Impayé', unpaid, const Color(0xFFD2473F))])),
          ]);
        },
      ),
      bottomNavigationBar: AppBottomNavigation(currentIndex: 3, user: widget.user),
    );
  }

  BoxDecoration _box() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18));
  Widget _card(String title, String value, Color color) => Container(padding: const EdgeInsets.all(15), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, color: Color(0xFF7B8290), fontWeight: FontWeight.w800)), const SizedBox(height: 7), Text(value, style: TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.w900))]));
  Widget _bar(int month, int value, int max) => Column(mainAxisAlignment: MainAxisAlignment.end, children: [Container(height: value == 0 ? 3 : 105 * value / max, margin: const EdgeInsets.symmetric(horizontal: 3), decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(3))), const SizedBox(height: 7), Text(const ['J','F','M','A','M','J','J','A','S','O','N','D'][month - 1], style: const TextStyle(fontSize: 9))]);
  Widget _status(String label, int value, Color color) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [CircleAvatar(radius: 5, backgroundColor: color), const SizedBox(width: 9), Text(label), const Spacer(), Text('$value', style: const TextStyle(fontWeight: FontWeight.w900))]));
}
