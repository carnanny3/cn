import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/status_badge.dart';
import '../../l10n/generated/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final vehicles = await context.read<GarageRepository>().fetchVehicles();
    if (!mounted) return;
    if (vehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.warrantyAddVehicleFirst)),
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
            Text(l10n.warrantySelectVehicle, style: Theme.of(sheetContext).textTheme.titleLarge),
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${plan.name} ${l10n.warrantyPurchasedFor} ${vehicle.label}.')));
        setState(_reload);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.warrantyPurchaseFailed)));
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _fileClaim(WarrantyPolicy policy) async {
    final l10n = AppLocalizations.of(context)!;
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
              Text(l10n.warrantyFileClaim, style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 4,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(hintText: l10n.warrantyDescribeIssueHint),
              ),
              const SizedBox(height: 16),
              GradientButton(
                label: l10n.warrantySubmitClaim,
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.warrantyClaimSubmitted)));
        setState(_reload);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.warrantyClaimSubmitFailed)));
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.warrantyTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [Tab(text: l10n.warrantyPlansTab), Tab(text: l10n.warrantyMyPoliciesTab)],
        ),
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
        final l10n = AppLocalizations.of(context)!;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.wifi_off,
            title: l10n.warrantyCouldNotLoadPlans,
            message: l10n.warrantyCheckConnection,
            actionLabel: l10n.commonRetry,
            onAction: () => setState(_reload),
          );
        }
        final plans = snapshot.data!;
        if (plans.isEmpty) {
          return EmptyState(icon: Icons.shield_outlined, title: l10n.warrantyNoPlansAvailable, message: l10n.warrantyCheckBackSoonPlans);
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
                        child: Text(l10n.warrantyBuy),
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
        final l10n = AppLocalizations.of(context)!;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.wifi_off,
            title: l10n.warrantyCouldNotLoadPolicies,
            message: l10n.warrantyCheckConnection,
            actionLabel: l10n.commonRetry,
            onAction: () => setState(_reload),
          );
        }
        final policies = snapshot.data!;
        if (policies.isEmpty) {
          return EmptyState(icon: Icons.shield_outlined, title: l10n.warrantyNoPoliciesYet, message: l10n.warrantyBuyPlanToProtect);
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
                    Text('${l10n.warrantyPolicyNumberLabel} ${policy.policyNumber}', style: Theme.of(context).textTheme.bodyMedium),
                    Text('${l10n.warrantyValidUntil} ${policy.endDate.toLocal().toString().split(' ').first}', style: Theme.of(context).textTheme.bodyMedium),
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
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: policy.status == 'active' ? () => _fileClaim(policy) : null,
                        child: Text(l10n.warrantyFileClaim),
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
