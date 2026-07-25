import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../garage/garage_repository.dart';
import '../garage/vehicle_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo_icon.png', height: 28, width: 28),
            const SizedBox(width: 10),
            const Text('Car Nanny'),
          ],
        ),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: FutureBuilder<List<Vehicle>>(
            future: _vehiclesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return EmptyState(
                  icon: Icons.wifi_off,
                  title: 'Could not reach Car Nanny',
                  message: 'Check your connection to the server and try again.',
                  actionLabel: 'Retry',
                  onAction: () => setState(_reload),
                );
              }
              final vehicles = snapshot.data!;
              if (vehicles.isEmpty) {
                return EmptyState(
                  icon: Icons.garage_outlined,
                  title: 'Add your first vehicle',
                  message: 'Unlock your Health Score, service reminders, and more.',
                  actionLabel: 'Add Vehicle',
                  onAction: () => context.push('/garage/add'),
                );
              }

              final primary = vehicles.first;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 96, 16, 120),
                children: [
                  Text('Good to see you', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 16),
                  GlassCard(
                    glow: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(primary.label, style: Theme.of(context).textTheme.titleLarge),
                        Text(primary.plateNumber, style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(gradient: AppColors.goldGradient, shape: BoxShape.circle),
                              child: Center(
                                child: Text(
                                  '${primary.healthScore ?? "--"}',
                                  style: const TextStyle(
                                    color: AppColors.navyDeep,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(child: Text('Vehicle Health Score')),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Quick actions', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.4,
                    children: [
                      _QuickAction(icon: Icons.build_outlined, label: 'Book Service', onTap: () => context.go('/services')),
                      _QuickAction(icon: Icons.fact_check_outlined, label: 'Inspect a Car', onTap: () => context.push('/inspection/book')),
                      _QuickAction(icon: Icons.garage_outlined, label: 'My Garage', onTap: () => context.go('/garage')),
                      _QuickAction(icon: Icons.smart_toy_outlined, label: 'Ask AI', onTap: () => context.go('/ai')),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.goldLight),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
