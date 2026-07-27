import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../l10n/generated/app_localizations.dart';

/// Bottom-nav shell for partner-role accounts (garages/inspectors), separate
/// from the customer MainShell — same visual language, different tab set.
class PartnerShell extends StatelessWidget {
  const PartnerShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = [
      (icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, label: l10n.partnerNavHome),
      (icon: Icons.work_outline, selectedIcon: Icons.work, label: l10n.partnerNavJobs),
      (icon: Icons.build_outlined, selectedIcon: Icons.build, label: l10n.partnerNavCatalog),
      (icon: Icons.storefront_outlined, selectedIcon: Icons.storefront, label: l10n.partnerNavProfile),
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
            if (selected) ...[
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.navyDeep),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
