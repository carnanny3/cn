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
    final vehicles = await context.read<GarageRepository>().fetchVehicles();
    if (!mounted) return;
    if (vehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a vehicle to My Garage before requesting insurance.')),
      );
      return;
    }

    Vehicle? selectedVehicle = vehicles.first;
    String coverageType = InsuranceRepository.coverageTypes.keys.first;

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
                    Text('Request a Quote', style: Theme.of(sheetContext).textTheme.titleLarge),
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
                      items: InsuranceRepository.coverageTypes.entries
                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (v) => setSheetState(() => coverageType = v ?? coverageType),
                    ),
                    const SizedBox(height: 20),
                    GradientButton(label: 'Request Quote', onPressed: () => Navigator.of(sheetContext).pop(true)),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quote requested — check back soon.')));
        setState(_reload);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not request a quote. Try again.')));
      }
    }
  }

  Future<void> _purchase(InsuranceQuote quote) async {
    setState(() => _purchasing = true);
    try {
      await context.read<InsuranceRepository>().purchasePolicy(quote.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Policy purchased.')));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Insurance'),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: _requestQuote)],
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: 'Quotes'), Tab(text: 'My Policies')]),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.wifi_off,
            title: 'Could not load your quotes',
            message: 'Check your connection and try again.',
            actionLabel: 'Retry',
            onAction: () => setState(_reload),
          );
        }
        final quotes = snapshot.data!;
        if (quotes.isEmpty) {
          return EmptyState(
            icon: Icons.security_outlined,
            title: 'No quotes yet',
            message: 'Request a quote to compare insurance options for your vehicle.',
            actionLabel: 'Request Quote',
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
                    Text(InsuranceRepository.coverageTypes[quote.coverageType] ?? quote.coverageType!, style: Theme.of(context).textTheme.bodyMedium),
                  if (quote.premiumAmount != null) ...[
                    const SizedBox(height: 8),
                    Text('AED ${quote.premiumAmount!.toStringAsFixed(0)} / year', style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.w700, fontSize: 18)),
                    if (quote.excessAmount != null)
                      Text('Excess: AED ${quote.excessAmount!.toStringAsFixed(0)}', style: Theme.of(context).textTheme.bodySmall),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('Awaiting a quote from the provider...', style: Theme.of(context).textTheme.bodySmall),
                    ),
                  if (quote.status == 'quoted' && !quote.hasPolicy) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _purchasing ? null : () => _purchase(quote),
                        child: const Text('Buy This Policy'),
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
          return const EmptyState(icon: Icons.security_outlined, title: 'No insurance policies yet', message: 'Purchase a quoted policy to see it here.');
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
                    Text('Policy ${policy.policyNumber}', style: Theme.of(context).textTheme.bodyMedium),
                    Text('Valid until ${policy.endDate.toLocal().toString().split(' ').first}', style: Theme.of(context).textTheme.bodyMedium),
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
