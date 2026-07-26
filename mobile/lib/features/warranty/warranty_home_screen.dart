import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/status_badge.dart';
import '../garage/garage_repository.dart';
import '../garage/vehicle_model.dart';
import 'warranty_model.dart';
import 'warranty_repository.dart';

class WarrantyHomeScreen extends StatefulWidget {
  const WarrantyHomeScreen({super.key});

  @override
  State<WarrantyHomeScreen> createState() => _WarrantyHomeScreenState();
}

class _WarrantyHomeScreenState extends State<WarrantyHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<WarrantyPlan>> _plansFuture;
  late Future<List<WarrantyPolicy>> _policiesFuture;
  bool _purchasing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _reload();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _reload() {
    _plansFuture = context.read<WarrantyRepository>().fetchPlans();
    _policiesFuture = context.read<WarrantyRepository>().fetchMyPolicies();
  }

  Future<void> _buyPlan(WarrantyPlan plan) async {
    final vehicles = await context.read<GarageRepository>().fetchVehicles();
    if (!mounted) return;
    if (vehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a vehicle to My Garage before buying a warranty.')),
      );
      return;
    }

    final vehicle = await showModalBottomSheet<Vehicle>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => GlassCard(
        strong: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Select a vehicle', style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...vehicles.map((v) => ListTile(
                  title: Text(v.label, style: const TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(v.plateNumber, style: const TextStyle(color: AppColors.textSecondary)),
                  onTap: () => Navigator.of(sheetContext).pop(v),
                )),
          ],
        ),
      ),
    );
    if (vehicle == null || !mounted) return;

    setState(() => _purchasing = true);
    try {
      await context.read<WarrantyRepository>().purchasePolicy(planId: plan.id, vehicleId: vehicle.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${plan.name} purchased for ${vehicle.label}.')));
        setState(_reload);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not complete the purchase. Try again.')));
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _fileClaim(WarrantyPolicy policy) async {
    final controller = TextEditingController();
    final description = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: GlassCard(
          strong: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('File a Claim', style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 4,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(hintText: 'Describe the issue...'),
              ),
              const SizedBox(height: 16),
              GradientButton(
                label: 'Submit Claim',
                onPressed: () => Navigator.of(sheetContext).pop(controller.text.trim()),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
    if (description == null || description.isEmpty || !mounted) return;

    try {
      await context.read<WarrantyRepository>().submitClaim(policyId: policy.id, description: description);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Claim submitted.')));
        setState(_reload);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not submit the claim. Try again.')));
      }
    }
  }

  String _statusColorKey(String status) {
    if (status == 'active') return 'green';
    if (status == 'cancelled' || status == 'expired') return 'red';
    return 'amber';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Warranty'),
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: 'Plans'), Tab(text: 'My Policies')]),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [_buildPlansTab(), _buildPoliciesTab()],
          ),
        ),
      ),
    );
  }

  Widget _buildPlansTab() {
    return FutureBuilder<List<WarrantyPlan>>(
      future: _plansFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.wifi_off,
            title: 'Could not load warranty plans',
            message: 'Check your connection and try again.',
            actionLabel: 'Retry',
            onAction: () => setState(_reload),
          );
        }
        final plans = snapshot.data!;
        if (plans.isEmpty) {
          return const EmptyState(icon: Icons.shield_outlined, title: 'No plans available', message: 'Check back soon for warranty plans.');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: plans.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final plan = plans[index];
            return GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(plan.providerName, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Text(plan.coverageSummary, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('AED ${plan.price.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.w700, fontSize: 18)),
                      const Spacer(),
                      TextButton(
                        onPressed: _purchasing ? null : () => _buyPlan(plan),
                        child: const Text('Buy'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPoliciesTab() {
    return FutureBuilder<List<WarrantyPolicy>>(
      future: _policiesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.wifi_off,
            title: 'Could not load your policies',
            message: 'Check your connection and try again.',
            actionLabel: 'Retry',
            onAction: () => setState(_reload),
          );
        }
        final policies = snapshot.data!;
        if (policies.isEmpty) {
          return const EmptyState(icon: Icons.shield_outlined, title: 'No warranty policies yet', message: 'Buy a plan to protect your vehicle.');
        }
        return RefreshIndicator(
          onRefresh: () async => setState(_reload),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: policies.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final policy = policies[index];
              return GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(policy.planName, style: Theme.of(context).textTheme.titleLarge)),
                        StatusBadge(status: _statusColorKey(policy.status), label: policy.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Policy ${policy.policyNumber}', style: Theme.of(context).textTheme.bodyMedium),
                    Text('Valid until ${policy.endDate.toLocal().toString().split(' ').first}', style: Theme.of(context).textTheme.bodyMedium),
                    if (policy.claims.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ...policy.claims.map((c) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Expanded(child: Text(c.description, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                                Text(c.status.replaceAll('_', ' '), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            ),
                          )),
                    ],
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: policy.status == 'active' ? () => _fileClaim(policy) : null,
                        child: const Text('File a Claim'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
