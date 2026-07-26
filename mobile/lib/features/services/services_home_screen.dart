import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../l10n/generated/app_localizations.dart';
import 'services_repository.dart';

const _categoryIcons = <String, IconData>{
  'oil_change': Icons.oil_barrel_outlined,
  'general_service': Icons.build_outlined,
  'brakes': Icons.disc_full_outlined,
  'battery': Icons.battery_charging_full_outlined,
  'ac_repair': Icons.ac_unit_outlined,
  'tires': Icons.tire_repair_outlined,
  'detailing': Icons.local_car_wash_outlined,
};

class ServicesHomeScreen extends StatelessWidget {
  const ServicesHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chevron = Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, title: Text(l10n.navServices)),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 96, 16, 120),
            children: [
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: ServicesRepository.categoryKeys
                    .map(
                      (key) => GlassCard(
                        onTap: () => context.push('/services/$key'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(_categoryIcons[key] ?? Icons.build_outlined, size: 28, color: AppColors.goldLight),
                            const SizedBox(height: 10),
                            Text(ServicesRepository.categoryLabel(l10n, key), style: Theme.of(context).textTheme.bodyLarge),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              Text(l10n.servicesProtectVehicle, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              GlassCard(
                onTap: () => context.push('/warranty'),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: AppColors.goldLight),
                    const SizedBox(width: 12),
                    Expanded(child: Text(l10n.servicesWarrantyPlans, style: Theme.of(context).textTheme.bodyLarge)),
                    Icon(chevron, color: AppColors.textSecondary),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                onTap: () => context.push('/insurance'),
                child: Row(
                  children: [
                    const Icon(Icons.security_outlined, color: AppColors.goldLight),
                    const SizedBox(width: 12),
                    Expanded(child: Text(l10n.servicesInsurance, style: Theme.of(context).textTheme.bodyLarge)),
                    Icon(chevron, color: AppColors.textSecondary),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(l10n.servicesConcierge, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              GlassCard(
                onTap: () => context.push('/concierge'),
                child: Row(
                  children: [
                    const Icon(Icons.support_agent_outlined, color: AppColors.goldLight),
                    const SizedBox(width: 12),
                    Expanded(child: Text(l10n.servicesConciergeDescription, style: Theme.of(context).textTheme.bodyLarge)),
                    Icon(chevron, color: AppColors.textSecondary),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(l10n.servicesBuySell, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              GlassCard(
                onTap: () => context.push('/listings'),
                child: Row(
                  children: [
                    const Icon(Icons.directions_car_outlined, color: AppColors.goldLight),
                    const SizedBox(width: 12),
                    Expanded(child: Text(l10n.servicesBuyACarDescription, style: Theme.of(context).textTheme.bodyLarge)),
                    Icon(chevron, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
