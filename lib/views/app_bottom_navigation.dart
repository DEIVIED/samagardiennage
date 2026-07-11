import 'package:flutter/material.dart';

import '../models/app_user.dart';
import 'collector_dashboard_view.dart';
import 'habitants_view.dart';
import 'payment_history_view.dart';
import 'statistics_view.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    this.user,
  });

  final int currentIndex;
  final AppUser? user;

  static const _gold = Color(0xFFF5A817);
  static const _inactive = Color(0xFF748092);

  void _navigate(BuildContext context, int index) {
    if (index == currentIndex) return;

    final Widget? destination = switch (index) {
      0 when user != null => CollectorDashboardView(user: user!),
      1 => HabitantsView(user: user),
      2 => PaymentHistoryView(user: user),
      3 => StatisticsView(user: user),
      _ => null,
    };
    if (destination == null) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    const items = <_NavigationItemData>[
      _NavigationItemData(Icons.home_outlined, 'Accueil'),
      _NavigationItemData(Icons.groups_2_outlined, 'Habitants'),
      _NavigationItemData(Icons.credit_card_outlined, 'Paiements'),
      _NavigationItemData(Icons.bar_chart_rounded, 'Stats'),
    ];
    return Container(
      height: 68,
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var index = 0; index < items.length; index++)
            _NavigationItem(
              item: items[index],
              isActive: currentIndex == index,
              onTap: () => _navigate(context, index),
            ),
        ],
      ),
    );
  }
}

class _NavigationItemData {
  const _NavigationItemData(this.icon, this.label);

  final IconData icon;
  final String label;
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final _NavigationItemData item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? AppBottomNavigation._gold
        : AppBottomNavigation._inactive;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              item.label,
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
