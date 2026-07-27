import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../l10n/generated/app_localizations.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Three destinations only: the customer's job is to keep vehicles, book
    // work on them, and manage their account. Everything else (warranty,
    // insurance, concierge, marketplace, AI) lives behind Profile → More
    // Services so it doesn't compete with the core loop.
    final items = [
      (icon: Icons.garage_outlined, selectedIcon: Icons.garage, label: l10n.navGarage),
      (icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long, label: l10n.navBookings),
      (icon: Icons.person_outline, selectedIcon: Icons.person, label: l10n.navProfile),
    ];
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.glassFillStrong,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.glassBorder),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 8)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final selected = navigationShell.currentIndex == index;
                  return _NavItem(
                    icon: selected ? item.selectedIcon : item.icon,
                    label: item.label,
                    selected: selected,
                    onTap: () => navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.goldGradient : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: selected ? AppColors.navyDeep : AppColors.textSecondary),
            const SizedBox(height: 2),
            // Labels stay visible on every tab — with only three destinations
            // there's room, and unlabelled icons made the bar hard to read.
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.navyDeep : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
