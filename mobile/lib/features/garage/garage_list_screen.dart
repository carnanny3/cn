import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import 'garage_repository.dart';
import 'vehicle_model.dart';

class GarageListScreen extends StatefulWidget {
  const GarageListScreen({super.key});

  @override
  State<GarageListScreen> createState() => _GarageListScreenState();
}

class _GarageListScreenState extends State<GarageListScreen> {
  late Future<List<Vehicle>> _vehiclesFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _vehiclesFuture = context.read<GarageRepository>().fetchVehicles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('My Garage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/garage/add').then((_) => setState(_reload)),
          ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: FutureBuilder<List<Vehicle>>(
            future: _vehiclesFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final vehicles = snapshot.data!;
              if (vehicles.isEmpty) {
                return EmptyState(
                  icon: Icons.garage_outlined,
                  title: 'No vehicles yet',
                  message: 'Add your first vehicle to unlock its Health Score and service history.',
                  actionLabel: 'Add Vehicle',
                  onAction: () => context.push('/garage/add').then((_) => setState(_reload)),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 96, 16, 120),
                itemCount: vehicles.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final v = vehicles[index];
                  return GlassCard(
                    onTap: () => context.push('/garage/${v.id}'),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(color: AppColors.glassFillStrong, borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.directions_car_filled_outlined, color: AppColors.goldLight),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(v.label, style: Theme.of(context).textTheme.titleLarge),
                              Text(v.plateNumber, style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                        if (v.healthScore != null)
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(gradient: AppColors.goldGradient, shape: BoxShape.circle),
                            child: Center(
                              child: Text(
                                '${v.healthScore}',
                                style: const TextStyle(color: AppColors.navyDeep, fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                            ),
                          )
                        else
                          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
