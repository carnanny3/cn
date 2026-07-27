import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../l10n/generated/app_localizations.dart';
import '../garage/garage_repository.dart';
import 'roadside_repository.dart';

const _serviceIcons = <String, IconData>{
  'tow': Icons.local_shipping_outlined,
  'jumpstart': Icons.battery_charging_full_outlined,
  'flat_tire': Icons.tire_repair_outlined,
  'fuel_delivery': Icons.local_gas_station_outlined,
  'lockout': Icons.lock_outline,
};

class RoadsideRequestScreen extends StatefulWidget {
  const RoadsideRequestScreen({super.key});

  @override
  State<RoadsideRequestScreen> createState() => _RoadsideRequestScreenState();
}

class _RoadsideRequestScreenState extends State<RoadsideRequestScreen> {
  bool _requesting = false;

  Future<void> _request(String serviceType) async {
    final l10n = AppLocalizations.of(context)!;
    if (_requesting) return;
    setState(() => _requesting = true);
    try {
      final vehicles = await context.read<GarageRepository>().fetchVehicles();
      if (!mounted) return;
      if (vehicles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.roadsideRequestAddVehicleFirst)),
        );
        return;
      }

      // Real device GPS isn't wired up anywhere in this app yet (the
      // inspection booking flow hardcodes a Dubai coordinate the same way)
      // — using the same fixed location for consistency until a real
      // location package is added app-wide.
      final request = await context.read<RoadsideRepository>().createRequest(
            vehicleId: vehicles.first.id,
            serviceType: serviceType,
            lat: 25.2048,
            lng: 55.2708,
          );
      if (mounted) {
        context.pushReplacement('/roadside/${request.id}');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.roadsideRequestCreateFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.roadsideRequestTitle)),
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.roadsideRequestHeadline, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(l10n.roadsideRequestSubtitle, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 24),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.1,
                    children: RoadsideRepository.serviceTypeKeys.map((key) {
                      return GlassCard(
                        glow: true,
                        onTap: _requesting ? null : () => _request(key),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_serviceIcons[key] ?? Icons.build_outlined, size: 36, color: AppColors.goldLight),
                            const SizedBox(height: 12),
                            Text(RoadsideRepository.serviceTypeLabel(l10n, key), style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (_requesting) const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
