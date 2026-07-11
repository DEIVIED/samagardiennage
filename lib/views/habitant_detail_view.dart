import 'dart:async';
import 'package:flutter/material.dart';

import '../controllers/habitants_controller.dart';
import '../models/app_user.dart';
import '../models/payment_record.dart';
import '../services/firestore_service.dart';

class HabitantDetailView extends StatefulWidget {
  const HabitantDetailView({
    super.key,
    required this.habitant,
    required this.paymentHistory,
    this.onPayNow,
  });

  final AppUser habitant;
  final List<PaymentRecord> paymentHistory;
  final Future<void> Function()? onPayNow;

  static const Color _navy = Color(0xFF172747);
  static const Color _gold = Color(0xFFF5A817);
  static const Color _surface = Color(0xFFF4F2EC);

  @override
  State<HabitantDetailView> createState() => _HabitantDetailViewState();
}

class _HabitantDetailViewState extends State<HabitantDetailView> {
  final _controller = HabitantsController();
  late Future<List<PaymentRecord>> _history = Future.value(
    widget.paymentHistory,
  );
  bool _isPaying = false;
  StreamSubscription<void>? _changesSub;

  Future<void> _payNow() async {
    if (_isPaying || widget.onPayNow == null) return;
    setState(() => _isPaying = true);
    try {
      await widget.onPayNow!();
      if (mounted) {
        setState(
          () => _history = _controller.fetchPaymentHistory(widget.habitant.id),
        );
      }
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _changesSub = FirestoreService.changes.listen((_) {
      if (mounted)
        setState(
          () => _history = _controller.fetchPaymentHistory(widget.habitant.id),
        );
    });
  }

  @override
  void dispose() {
    _changesSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PaymentRecord>>(
      future: _history,
      builder: (context, snapshot) {
        final paymentHistory = snapshot.data ?? widget.paymentHistory;
        final totalPaid = paymentHistory
            .where((payment) => payment.status.toLowerCase() != 'impaye')
            .fold<int>(0, (sum, payment) => sum + payment.amount);

        return Scaffold(
          backgroundColor: HabitantDetailView._navy,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Container(
                  color: HabitantDetailView._surface,
                  child: Column(
                    children: [
                      _Header(habitant: widget.habitant),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _SummaryCard(
                                      title: 'TOTAL PAYE',
                                      value: '$totalPaid',
                                      subtitle: 'F CFA',
                                      color: const Color(0xFF2E8B57),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _SummaryCard(
                                      title: 'HISTORIQUE',
                                      value: '${paymentHistory.length}',
                                      subtitle: 'paiements',
                                      color: HabitantDetailView._gold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _InfoCard(habitant: widget.habitant),
                              if (widget.onPayNow != null) ...[
                                const SizedBox(height: 16),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: HabitantDetailView._gold,
                                    foregroundColor: HabitantDetailView._navy,
                                    minimumSize: const Size.fromHeight(46),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: _isPaying ? null : _payNow,
                                  child: Text(
                                    _isPaying
                                        ? 'Mise à jour...'
                                        : 'Enregistrer un nouveau paiement',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 18),
                              const Text(
                                'HISTORIQUE DES PAIEMENTS',
                                style: TextStyle(
                                  color: Color(0xFF7B8290),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (paymentHistory.isEmpty)
                                const _EmptyHistory()
                              else
                                ...paymentHistory.map(_PaymentHistoryTile.new),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.habitant});

  final AppUser habitant;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
      decoration: const BoxDecoration(color: HabitantDetailView._navy),
      child: Column(
        children: [
          Container(
            width: 118,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B36),
              borderRadius: BorderRadius.zero,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              IconButton(
                tooltip: 'Retour',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 17,
                ),
              ),
              CircleAvatar(
                radius: 25,
                backgroundColor: HabitantDetailView._gold,
                child: Text(
                  _initials(habitant.fullName),
                  style: const TextStyle(
                    color: Color(0xFF172747),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habitant.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      habitant.address ?? 'Adresse non renseignee',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFAEB8C9),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'HB';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF848C98),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF8B929C),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.habitant});

  final AppUser habitant;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.phone_outlined,
            label: 'Telephone',
            value: habitant.phone ?? 'Non renseigne',
          ),
          const Divider(height: 22, color: Color(0xFFE8E5DE)),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Quartier',
            value: habitant.quartierName ?? 'Non renseigne',
          ),
          const Divider(height: 22, color: Color(0xFFE8E5DE)),
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: habitant.email,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: HabitantDetailView._gold, size: 19),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF848C98),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF22314E),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentHistoryTile extends StatelessWidget {
  const _PaymentHistoryTile(this.payment);

  final PaymentRecord payment;

  @override
  Widget build(BuildContext context) {
    final badge = _PaymentBadgeData.fromStatus(payment.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: badge.color.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              color: badge.color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.periodLabel,
                  style: const TextStyle(
                    color: Color(0xFF22314E),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  payment.receiptNumber ?? 'Aucun recu',
                  style: const TextStyle(
                    color: Color(0xFF848C98),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${payment.amount} F',
                style: const TextStyle(
                  color: Color(0xFF22314E),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badge.color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge.label,
                  style: TextStyle(
                    color: badge.color,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentBadgeData {
  const _PaymentBadgeData({required this.label, required this.color});

  final String label;
  final Color color;

  factory _PaymentBadgeData.fromStatus(String status) {
    switch (status.toLowerCase()) {
      case 'paye':
        return const _PaymentBadgeData(label: 'Paye', color: Color(0xFF2E8B57));
      case 'partiel':
        return const _PaymentBadgeData(
          label: 'Partiel',
          color: Color(0xFFB7791F),
        );
      case 'impaye':
      default:
        return const _PaymentBadgeData(
          label: 'Impaye',
          color: Color(0xFFD2473F),
        );
    }
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'Aucun paiement enregistre pour cet habitant.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF7B8290), fontWeight: FontWeight.w700),
      ),
    );
  }
}
