import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Services')),
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
                children: ServicesRepository.categories.entries
                    .map(
                      (entry) => GlassCard(
                        onTap: () => context.push('/services/${entry.key}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(_categoryIcons[entry.key] ?? Icons.build_outlined, size: 28, color: AppColors.goldLight),
                            const SizedBox(height: 10),
                            Text(entry.value, style: Theme.of(context).textTheme.bodyLarge),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              Text('Protect Your Vehicle', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              GlassCard(
                onTap: () => context.push('/warranty'),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: AppColors.goldLight),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Warranty Plans', style: Theme.of(context).textTheme.bodyLarge)),
                    const Icon(Icons.chevron_right, color: AppColors.textSecondary),
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
                    Expanded(child: Text('Insurance', style: Theme.of(context).textTheme.bodyLarge)),
                    const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Concierge', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              GlassCard(
                onTap: () => context.push('/concierge'),
                child: Row(
                  children: [
                    const Icon(Icons.support_agent_outlined, color: AppColors.goldLight),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Registration, transfers, pickup & delivery, detailing', style: Theme.of(context).textTheme.bodyLarge)),
                    const Icon(Icons.chevron_right, color: AppColors.textSecondary),
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
