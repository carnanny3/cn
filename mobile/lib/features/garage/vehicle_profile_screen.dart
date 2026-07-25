import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/status_badge.dart';
import 'garage_repository.dart';
import 'vehicle_model.dart';

class VehicleProfileScreen extends StatefulWidget {
  const VehicleProfileScreen({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  State<VehicleProfileScreen> createState() => _VehicleProfileScreenState();
}

class _VehicleProfileScreenState extends State<VehicleProfileScreen> {
  late Future<HealthScoreBreakdown> _healthFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _healthFuture = context.read<GarageRepository>().fetchHealthScore(widget.vehicleId);
  }

  String _statusFor(int score) {
    if (score >= 80) return 'green';
    if (score >= 60) return 'amber';
    return 'red';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle Health')),
      body: GradientBackground(
        child: SafeArea(
          child: FutureBuilder<HealthScoreBreakdown>(
            future: _healthFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return EmptyState(
                  icon: Icons.wifi_off,
                  title: 'Could not load health score',
                  message: 'Check your connection to the server and try again.',
                  actionLabel: 'Retry',
                  onAction: () => setState(_reload),
                );
              }
              final health = snapshot.data!;
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  GlassCard(
                    glow: true,
                    child: Column(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: const BoxDecoration(gradient: AppColors.goldGradient, shape: BoxShape.circle),
                          child: Center(
                            child: Text(
                              '${health.overall}',
                              style: const TextStyle(color: AppColors.navyDeep, fontWeight: FontWeight.w800, fontSize: 30),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        StatusBadge(status: _statusFor(health.overall), label: 'Health: ${health.overall}/100'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Breakdown', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 16),
                        ...health.categories.entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(flex: 2, child: Text(_labelFor(e.key), style: Theme.of(context).textTheme.bodyMedium)),
                                Expanded(
                                  flex: 5,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: e.value / 100,
                                      minHeight: 8,
                                      backgroundColor: AppColors.glassFill,
                                      valueColor: const AlwaysStoppedAnimation(AppColors.goldMid),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text('${e.value}', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (health.recommendations.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Recommendations', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 14),
                          ...health.recommendations.map(
                            (r) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.info_outline, size: 18, color: AppColors.goldLight),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(r, style: Theme.of(context).textTheme.bodyMedium)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _labelFor(String key) {
    switch (key) {
      case 'inspection':
        return 'Inspection';
      case 'maintenance':
        return 'Maintenance';
      case 'documents':
        return 'Documents';
      case 'ageMileage':
        return 'Age/Mileage';
      default:
        return key;
    }
  }
}
