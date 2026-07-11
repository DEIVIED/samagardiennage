import 'package:flutter/material.dart';

import '../controllers/habitants_controller.dart';
import '../models/app_user.dart';
import '../models/payment_record.dart';
import 'habitants_view.dart';
import 'payment_history_view.dart';
import 'statistics_view.dart';

class CollectorDashboardView extends StatefulWidget {
  const CollectorDashboardView({super.key, required this.user});

  final AppUser user;

  @override
  State<CollectorDashboardView> createState() => _CollectorDashboardViewState();
}

class _CollectorDashboardViewState extends State<CollectorDashboardView> {
  static const Color _navy = Color(0xFF172747);
  static const Color _gold = Color(0xFFF5A817);
  static const Color _surface = Color(0xFFF4F2EC);
  static const Color _green = Color(0xFF7DBA8D);

  final HabitantsController _controller = HabitantsController();
  late Future<_DashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboardData();
  }

  Future<_DashboardData> _loadDashboardData() async {
    final results = await Future.wait([
      _controller.fetchPaymentsForYear(DateTime.now().year),
      _controller.fetchHabitants(),
    ]);

    return _DashboardData(
      payments: results[0] as List<PaymentRecord>,
      habitants: results[1] as List<AppUser>,
    );
  }

  void _openHabitants(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => HabitantsView(user: widget.user)));
  }

  void _openStatistics(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => StatisticsView(user: widget.user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: SafeArea(
        child: FutureBuilder<_DashboardData>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: _gold),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Chargement impossible : ${snapshot.error}'),
              );
            }

            final data = snapshot.data ?? _DashboardData.empty();
            final totalCollected = data.payments
                .where((payment) => payment.status.toLowerCase() != 'impaye')
                .fold<int>(0, (sum, payment) => sum + payment.amount);
            final paidHabitants = data.payments
                .where((payment) => payment.status.toLowerCase() == 'paye')
                .map((payment) => payment.habitantId)
                .toSet()
                .length;
            final totalHabitants = data.habitants.length;
            final currentMonth = DateTime.now().month;
            final expectedTotal = totalHabitants * 2000 * currentMonth;
            final progress = expectedTotal > 0
                ? (totalCollected / expectedTotal).clamp(0.0, 1.0)
                : 0.0;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Container(
                  color: _surface,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _Header(user: widget.user),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  14,
                                  20,
                                  0,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _MetricCard(
                                            title: 'COLLECTE',
                                            value: '$totalCollected',
                                            subtitle: 'F CFA',
                                            valueColor: _navy,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _MetricCard(
                                            title: 'HABITANTS',
                                            value:
                                                '$paidHabitants/$totalHabitants',
                                            subtitle: 'payés',
                                            valueColor: _gold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    _ProgressCard(
                                      progress: progress,
                                      expectedTotal: expectedTotal,
                                    ),
                                    const SizedBox(height: 18),
                                    const Text(
                                      'ACTIONS RAPIDES',
                                      style: TextStyle(
                                        color: Color(0xFF7B8290),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    GridView.count(
                                      crossAxisCount: 2,
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      mainAxisSpacing: 12,
                                      crossAxisSpacing: 12,
                                      childAspectRatio: 2.8,
                                      children: [
                                        _ActionTile(
                                          icon: Icons.payments_outlined,
                                          label: 'Nouveau\nPaiement',
                                          color: _gold,
                                          onTap: () => _openHabitants(context),
                                        ),
                                        _ActionTile(
                                          icon: Icons.groups_2_outlined,
                                          label: 'Habitants',
                                          color: const Color(0xFF8C96A6),
                                          onTap: () => _openHabitants(context),
                                        ),
                                        const _ActionTile(
                                          icon: Icons.receipt_long_outlined,
                                          label: 'Recus',
                                          color: Color(0xFF8793CA),
                                        ),
                                        _ActionTile(
                                          icon: Icons.bar_chart_rounded,
                                          label: 'Statistiques',
                                          color: _green,
                                          onTap: () => _openStatistics(context),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _BottomNavigation(user: widget.user),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 138,
      decoration: const BoxDecoration(
        color: _CollectorDashboardViewState._navy,
      ),
      child: Stack(
        children: [
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 118,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1B36),
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),
          ),
          Positioned(
            left: 22,
            right: 22,
            bottom: 22,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'BONJOUR',
                        style: TextStyle(
                          color: Color(0xFFAEB8C9),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.home_work_outlined,
                            color: Color(0xFFAEB8C9),
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              '${user.address ?? 'Juste 208'}  -  ${user.quartierName ?? 'Quartier Medina'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFAEB8C9),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    Positioned(
                      right: 3,
                      top: 2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: _CollectorDashboardViewState._gold,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 17,
                  backgroundColor: _CollectorDashboardViewState._gold,
                  child: Text(
                    _initials(user.fullName),
                    style: const TextStyle(
                      color: Color(0xFF2B230E),
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'SG';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.valueColor,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
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
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor,
              fontSize: 18,
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
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress, required this.expectedTotal});

  final double progress;
  final int expectedTotal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Progression mensuelle',
                  style: TextStyle(
                    color: Color(0xFF313D54),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: _CollectorDashboardViewState._gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: const Color(0xFFE8E5DE),
              valueColor: const AlwaysStoppedAnimation<Color>(
                _CollectorDashboardViewState._navy,
              ),
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              const Text(
                '0 F CFA',
                style: TextStyle(
                  color: Color(0xFF9AA0AA),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '$expectedTotal F CFA',
                style: const TextStyle(
                  color: Color(0xFF9AA0AA),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardData {
  const _DashboardData({required this.payments, required this.habitants});

  factory _DashboardData.empty() =>
      const _DashboardData(payments: [], habitants: []);

  final List<PaymentRecord> payments;
  final List<AppUser> habitants;
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF22314E),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const _NavItem(
            icon: Icons.home_outlined,
            label: 'Accueil',
            isActive: true,
          ),
          _NavItem(
            icon: Icons.groups_2_outlined,
            label: 'Habitants',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => HabitantsView(user: user)),
            ),
          ),
          _NavItem(
            icon: Icons.credit_card_outlined,
            label: 'Paiements',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PaymentHistoryView(user: user)),
            ),
          ),
          _NavItem(
            icon: Icons.bar_chart_rounded,
            label: 'Stats',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => StatisticsView(user: user)),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? _CollectorDashboardViewState._gold
        : const Color(0xFF748092);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
