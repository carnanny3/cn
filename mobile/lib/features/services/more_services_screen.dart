import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../l10n/generated/app_localizations.dart';

/// Secondary product lines, grouped out of the customer's main path. These are
/// real offerings but not what someone opens the app to do, so they live one
/// level down (Profile → More Services) instead of in the bottom nav.
class MoreServicesScreen extends StatelessWidget {
  const MoreServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rows = <_MoreServiceRow>[
      // Roadside stays first — it's the one entry here someone may need urgently.
      _MoreServiceRow(icon: Icons.car_crash_outlined, label: l10n.homeRoadsideHelp, route: '/roadside'),
      _MoreServiceRow(icon: Icons.fact_check_outlined, label: l10n.homeInspectACar, route: '/inspection/book'),
      _MoreServiceRow(icon: Icons.shield_outlined, label: l10n.servicesWarrantyPlans, route: '/warranty'),
      _MoreServiceRow(icon: Icons.security_outlined, label: l10n.servicesInsurance, route: '/insurance'),
      _MoreServiceRow(icon: Icons.support_agent_outlined, label: l10n.servicesConcierge, route: '/concierge'),
      _MoreServiceRow(icon: Icons.directions_car_outlined, label: l10n.servicesBuySell, route: '/listings'),
      _MoreServiceRow(icon: Icons.smart_toy_outlined, label: l10n.homeAskAi, route: '/ai'),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.moreServicesTitle)),
      body: GradientBackground(
        child: SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final row = rows[index];
              return GlassCard(
                onTap: () => context.push(row.route),
                child: Row(
                  children: [
                    Icon(row.icon, color: AppColors.goldLight),
                    const SizedBox(width: 14),
                    Expanded(child: Text(row.label, style: Theme.of(context).textTheme.bodyLarge)),
                    Icon(
                      Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MoreServiceRow {
  const _MoreServiceRow({required this.icon, required this.label, required this.route});

  final IconData icon;
  final String label;
  final String route;
}
