import 'package:flutter/material.dart';

import '../controllers/habitants_controller.dart';
import '../models/app_user.dart';
import '../models/payment_record.dart';
import 'collector_dashboard_view.dart';
import 'habitant_detail_view.dart';
import 'habitant_creation_view.dart';
import 'habitant_qr_scanner_view.dart';
import 'payment_view.dart';
import 'payment_history_view.dart';
import 'receipt_view.dart';
import 'statistics_view.dart';

enum HabitantFilter { all, paid, unpaid }

class HabitantsView extends StatefulWidget {
  const HabitantsView({super.key, this.user});

  final AppUser? user;

  @override
  State<HabitantsView> createState() => _HabitantsViewState();
}

class _HabitantsViewState extends State<HabitantsView> {
  static const Color _navy = Color(0xFF172747);
  static const Color _gold = Color(0xFFF5A817);
  static const Color _surface = Color(0xFFF4F2EC);

  final HabitantsController _controller = HabitantsController();
  final TextEditingController _searchController = TextEditingController();
  late Future<_HabitantsPageData> _pageDataFuture;
  HabitantFilter _filter = HabitantFilter.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _pageDataFuture = _loadPageData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<_HabitantsPageData> _loadPageData() async {
    final habitants = await _controller.fetchHabitants();
    final historyByHabitant = <String, List<PaymentRecord>>{};
    for (final habitant in habitants) {
      historyByHabitant[habitant.id] = await _controller.fetchPaymentHistory(
        habitant.id,
      );
    }
    return _HabitantsPageData(
      habitants: habitants,
      historyByHabitant: historyByHabitant,
    );
  }

  List<AppUser> _filteredHabitants(_HabitantsPageData data) {
    return data.habitants.where((habitant) {
      final payment = data.latestPaymentFor(habitant.id);
      final matchesQuery =
          habitant.fullName.toLowerCase().contains(_query.toLowerCase()) ||
          (habitant.address ?? '').toLowerCase().contains(_query.toLowerCase());

      final matchesFilter = switch (_filter) {
        HabitantFilter.all => true,
        HabitantFilter.paid => payment?.status.toLowerCase() == 'paye',
        HabitantFilter.unpaid => payment?.status.toLowerCase() == 'impaye',
      };

      return matchesQuery && matchesFilter;
    }).toList();
  }

  Future<void> _openPayment(
    AppUser habitant, [
    List<PaymentRecord> history = const [],
  ]) async {
    if (widget.user == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentView(
          habitant: habitant,
          collector: widget.user!,
          paymentHistory: history,
          onPaymentConfirmed: (payment) async {
            await _controller.savePayment(payment);
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => ReceiptView(
                  habitant: habitant,
                  collector: widget.user!,
                  payment: payment,
                ),
              ),
            );
          },
        ),
      ),
    );
    if (mounted) {
      setState(() => _pageDataFuture = _loadPageData());
    }
  }

  Future<void> _openScan() async {
    if (widget.user == null) return;

    final habitant = await Navigator.of(context).push<AppUser>(
      MaterialPageRoute(
        builder: (_) => HabitantQrScannerView(controller: _controller),
      ),
    );

    if (!mounted || habitant == null) return;
    final history = await _controller.fetchPaymentHistory(habitant.id);
    if (!mounted) return;
    _openPayment(habitant, history);
  }

  void _openDetail(AppUser habitant, List<PaymentRecord> history) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HabitantDetailView(
          habitant: habitant,
          paymentHistory: history,
          onPayNow: widget.user != null
              ? () => _openPayment(habitant, history)
              : null,
        ),
      ),
    );
  }

  Future<void> _openCreateHabitant() async {
    final habitant = await Navigator.of(context).push<AppUser>(
      MaterialPageRoute(
        builder: (_) => HabitantCreationView(controller: _controller),
      ),
    );
    if (habitant != null && mounted) {
      setState(() => _pageDataFuture = _loadPageData());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${habitant.fullName} a été ajouté.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: Container(
                color: _surface,
                child: Column(
                  children: [
                    _Header(
                      searchController: _searchController,
                      user: widget.user,
                      onChanged: (value) {
                        setState(() => _query = value.trim());
                      },
                      onScanRequested: widget.user != null ? _openScan : null,
                    ),
                    Expanded(
                      child: FutureBuilder<_HabitantsPageData>(
                        future: _pageDataFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState !=
                              ConnectionState.done) {
                            return const Center(
                              child: CircularProgressIndicator(color: _gold),
                            );
                          }

                          if (snapshot.hasError) {
                            return _EmptyState(
                              icon: Icons.error_outline,
                              title: 'Chargement impossible',
                              message: snapshot.error.toString(),
                            );
                          }

                          final data =
                              snapshot.data ?? _HabitantsPageData.empty();
                          final habitants = _filteredHabitants(data);
                          return Column(
                            children: [
                              _FilterBar(
                                selectedFilter: _filter,
                                onChanged: (filter) {
                                  setState(() => _filter = filter);
                                },
                              ),
                              Expanded(
                                child: habitants.isEmpty
                                    ? const _EmptyState(
                                        icon: Icons.groups_2_outlined,
                                        title: 'Aucun habitant',
                                        message:
                                            'Aucun resultat ne correspond a votre recherche.',
                                      )
                                    : ListView.separated(
                                        padding: const EdgeInsets.fromLTRB(
                                          18,
                                          12,
                                          18,
                                          18,
                                        ),
                                        itemBuilder: (context, index) {
                                          final habitant = habitants[index];
                                          final history =
                                              data.historyByHabitant[habitant
                                                  .id] ??
                                              const <PaymentRecord>[];
                                          final latest = data.latestPaymentFor(
                                            habitant.id,
                                          );
                                          return _HabitantTile(
                                            habitant: habitant,
                                            payment: latest,
                                            onTap: () =>
                                                _openDetail(habitant, history),
                                            onPaymentTap: widget.user != null
                                                ? () => _openPayment(habitant, history)
                                                : null,
                                          );
                                        },
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 10),
                                        itemCount: habitants.length,
                                      ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    _BottomNavigation(user: widget.user),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Padding(
        // Le bouton est volontairement remonté pour ne jamais recouvrir Stats.
        padding: const EdgeInsets.only(bottom: 70),
        child: FloatingActionButton.small(
          backgroundColor: _gold,
          foregroundColor: _navy,
          onPressed: _openCreateHabitant,
          tooltip: 'Ajouter un habitant',
          child: const Icon(Icons.person_add_alt_1_outlined),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.searchController,
    required this.onChanged,
    this.user,
    this.onScanRequested,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onChanged;
  final AppUser? user;
  final VoidCallback? onScanRequested;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
      decoration: const BoxDecoration(
        color: _HabitantsViewState._navy,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 118,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B36),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                tooltip: 'Retour',
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.of(context).pop();
                  } else if (user != null) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => CollectorDashboardView(user: user!),
                      ),
                    );
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 17,
                ),
              ),
              const Expanded(
                child: Text(
                  'Habitants',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _HabitantsViewState._gold,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  '26 total',
                  style: TextStyle(
                    color: Color(0xFF2B230E),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: searchController,
            onChanged: onChanged,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Rechercher un habitant...',
              hintStyle: const TextStyle(
                color: Color(0xFF9BA6B8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF9BA6B8),
                size: 18,
              ),
              filled: true,
              fillColor: const Color(0xFF22314E),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selectedFilter, required this.onChanged});

  final HabitantFilter selectedFilter;
  final ValueChanged<HabitantFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Row(
        children: [
          _FilterChip(
            label: 'Tous',
            isSelected: selectedFilter == HabitantFilter.all,
            onTap: () => onChanged(HabitantFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Payes',
            isSelected: selectedFilter == HabitantFilter.paid,
            onTap: () => onChanged(HabitantFilter.paid),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Impayes',
            isSelected: selectedFilter == HabitantFilter.unpaid,
            onTap: () => onChanged(HabitantFilter.unpaid),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFE8E5DE),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.filter_list_rounded,
                  size: 13,
                  color: Color(0xFF7B8290),
                ),
                SizedBox(width: 4),
                Text(
                  'Filtrer',
                  style: TextStyle(
                    color: Color(0xFF7B8290),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? _HabitantsViewState._navy
              : const Color(0xFFE8E5DE),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF7B8290),
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _HabitantTile extends StatelessWidget {
  const _HabitantTile({
    required this.habitant,
    required this.payment,
    required this.onTap,
    this.onPaymentTap,
  });

  final AppUser habitant;
  final PaymentRecord? payment;
  final VoidCallback onTap;
  final VoidCallback? onPaymentTap;

  @override
  Widget build(BuildContext context) {
    final status = payment?.status.toLowerCase() ?? 'impaye';
    final badge = _PaymentBadgeData.fromStatus(status);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: _HabitantsViewState._navy,
              child: Text(
                _initials(habitant.fullName),
                style: const TextStyle(
                  color: _HabitantsViewState._gold,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habitant.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF22314E),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    habitant.address ?? 'Adresse non renseignee',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF7B8290),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
            if (onPaymentTap != null) ...[
              const SizedBox(width: 8),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.payments_outlined,
                  color: Color(0xFF8C96A6),
                  size: 18,
                ),
                tooltip: 'Payer',
                onPressed: onPaymentTap,
              ),
            ],
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF9AA0AA),
              size: 18,
            ),
          ],
        ),
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

class _PaymentBadgeData {
  const _PaymentBadgeData({required this.label, required this.color});

  final String label;
  final Color color;

  factory _PaymentBadgeData.fromStatus(String status) {
    switch (status) {
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF8A92A2), size: 36),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF22314E),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF7B8290),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitantsPageData {
  const _HabitantsPageData({
    required this.habitants,
    required this.historyByHabitant,
  });

  factory _HabitantsPageData.empty() {
    return const _HabitantsPageData(habitants: [], historyByHabitant: {});
  }

  final List<AppUser> habitants;
  final Map<String, List<PaymentRecord>> historyByHabitant;

  PaymentRecord? latestPaymentFor(String habitantId) {
    final history = historyByHabitant[habitantId];
    if (history == null || history.isEmpty) return null;
    return history.first;
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            label: 'Accueil',
            onTap: () {
              if (user != null) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => CollectorDashboardView(user: user!),
                  ),
                );
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          const _NavItem(
            icon: Icons.groups_2_outlined,
            label: 'Habitants',
            isActive: true,
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
        ? _HabitantsViewState._gold
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
