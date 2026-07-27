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

/// Pick a service category to book. Reached from the Bookings tab — the other
/// product lines that used to share this screen now live in MoreServicesScreen,
/// so this stays a single-purpose "what do you need done?" step.
class ServicesHomeScreen extends StatelessWidget {
  const ServicesHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeBookService)),
      body: GradientBackground(
        child: SafeArea(
          child: GridView.count(
            padding: const EdgeInsets.all(16),
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
        ),
      ),
    );
  }
}
