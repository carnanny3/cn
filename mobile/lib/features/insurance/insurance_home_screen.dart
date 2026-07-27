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
import 'insurance_model.dart';
import 'insurance_repository.dart';

class InsuranceHomeScreen extends StatefulWidget {
  const InsuranceHomeScreen({super.key});

  @override
  State<InsuranceHomeScreen> createState() => _InsuranceHomeScreenState();
}

class _InsuranceHomeScreenState extends State<InsuranceHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<InsuranceQuote>> _quotesFuture;
  late Future<List<InsurancePolicy>> _policiesFuture;
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
    _quotesFuture = context.read<InsuranceRepository>().fetchMyQuotes();
    _policiesFuture = context.read<InsuranceRepository>().fetchMyPolicies();
  }

  Future<void> _requestQuote() async {
    final l10n = AppLocalizations.of(context)!;
    final vehicles = await context.read<GarageRepository>().fetchVehicles();
    if (!mounted) return;
    if (vehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.insuranceAddVehicleFirst)),
      );
      return;
    }

    Vehicle? selectedVehicle = vehicles.first;
    String coverageType = InsuranceRepository.coverageTypeKeys.first;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom, left: 16, right: 16, top: 16),
              child: GlassCard(
                strong: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.insuranceRequestQuoteTitle, style: Theme.of(sheetContext).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Vehicle>(
                      initialValue: selectedVehicle,
                      dropdownColor: AppColors.navyMid,
                      style: const TextStyle(color: AppColors.textPrimary),
                      items: vehicles.map((v) => DropdownMenuItem(value: v, child: Text(v.label))).toList(),
                      onChanged: (v) => setSheetState(() => selectedVehicle = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: coverageType,
                      dropdownColor: AppColors.navyMid,
                      style: const TextStyle(color: AppColors.textPrimary),
                      items: InsuranceRepository.coverageTypeKeys
                          .map((key) => DropdownMenuItem(value: key, child: Text(InsuranceRepository.coverageTypeLabel(l10n, key))))
                          .toList(),
                      onChanged: (v) => setSheetState(() => coverageType = v ?? coverageType),
                    ),
                    const SizedBox(height: 20),
                    GradientButton(label: l10n.insuranceRequestQuote, onPressed: () => Navigator.of(sheetContext).pop(true)),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmed != true || selectedVehicle == null || !mounted) return;
    try {
      await context.read<InsuranceRepository>().requestQuote(vehicleId: selectedVehicle!.id, coverageType: coverageType);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.insuranceQuoteRequested)));
        setState(_reload);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.insuranceQuoteRequestFailed)));
      }
    }
  }

  Future<void> _purchase(InsuranceQuote quote) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _purchasing = true);
    try {
      await context.read<InsuranceRepository>().purchasePolicy(quote.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.insurancePolicyPurchased)));
        setState(_reload);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.insurancePurchaseFailed)));
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.insuranceTitle),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: _requestQuote)],
        bottom: TabBar(controller: _tabController, tabs: [Tab(text: l10n.insuranceQuotesTab), Tab(text: l10n.insurancePoliciesTab)]),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: TabBarView(controller: _tabController, children: [_buildQuotesTab(), _buildPoliciesTab()]),
        ),
      ),
    );
  }

  Widget _buildQuotesTab() {
    return FutureBuilder<List<InsuranceQuote>>(
      future: _quotesFuture,
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context)!;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.wifi_off,
            title: l10n.insuranceCouldNotLoadQuotes,
            message: l10n.insuranceCheckConnectionRetry,
            actionLabel: l10n.commonRetry,
            onAction: () => setState(_reload),
          );
        }
        final quotes = snapshot.data!;
        if (quotes.isEmpty) {
          return EmptyState(
            icon: Icons.security_outlined,
            title: l10n.insuranceNoQuotesYet,
            message: l10n.insuranceNoQuotesMessage,
            actionLabel: l10n.insuranceRequestQuote,
            onAction: _requestQuote,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: quotes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final quote = quotes[index];
            return GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(quote.providerName, style: Theme.of(context).textTheme.titleLarge)),
                      StatusBadge(status: quote.status == 'quoted' ? 'green' : 'amber', label: quote.status),
                    ],
                  ),
                  if (quote.coverageType != null)
                    Text(InsuranceRepository.coverageTypeLabel(l10n, quote.coverageType!), style: Theme.of(context).textTheme.bodyMedium),
                  if (quote.premiumAmount != null) ...[
                    const SizedBox(height: 8),
                    Text(l10n.insurancePremiumPerYear(quote.premiumAmount!.toStringAsFixed(0)), style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.w700, fontSize: 18)),
                    if (quote.excessAmount != null)
                      Text(l10n.insuranceExcessAmount(quote.excessAmount!.toStringAsFixed(0)), style: Theme.of(context).textTheme.bodySmall),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(l10n.insuranceAwaitingQuote, style: Theme.of(context).textTheme.bodySmall),
                    ),
                  if (quote.status == 'quoted' && !quote.hasPolicy) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: _purchasing ? null : () => _purchase(quote),
                        child: Text(l10n.insuranceBuyPolicy),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPoliciesTab() {
    return FutureBuilder<List<InsurancePolicy>>(
      future: _policiesFuture,
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context)!;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.wifi_off,
            title: l10n.insuranceCouldNotLoadPolicies,
            message: l10n.insuranceCheckConnectionRetry,
            actionLabel: l10n.commonRetry,
            onAction: () => setState(_reload),
          );
        }
        final policies = snapshot.data!;
        if (policies.isEmpty) {
          return EmptyState(icon: Icons.security_outlined, title: l10n.insuranceNoPoliciesYet, message: l10n.insuranceNoPoliciesMessage);
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
                        Expanded(child: Text(policy.providerName, style: Theme.of(context).textTheme.titleLarge)),
                        StatusBadge(status: policy.status == 'active' ? 'green' : 'red', label: policy.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.insurancePolicyNumber(policy.policyNumber), style: Theme.of(context).textTheme.bodyMedium),
                    Text(l10n.insuranceValidUntil(policy.endDate.toLocal().toString().split(' ').first), style: Theme.of(context).textTheme.bodyMedium),
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
