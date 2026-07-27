import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/status_badge.dart';
import '../../l10n/generated/app_localizations.dart';
import '../garage/garage_repository.dart';
import '../garage/vehicle_model.dart';
import 'concierge_model.dart';
import 'concierge_repository.dart';

const _orderTypeIcons = <String, IconData>{
  'registration_renewal': Icons.description_outlined,
  'ownership_transfer': Icons.swap_horiz,
  'pickup_delivery': Icons.local_shipping_outlined,
  'detailing': Icons.local_car_wash_outlined,
  'driver_service': Icons.drive_eta_outlined,
};

class ConciergeScreen extends StatefulWidget {
  const ConciergeScreen({super.key});

  @override
  State<ConciergeScreen> createState() => _ConciergeScreenState();
}

class _ConciergeScreenState extends State<ConciergeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<ConciergeOrderItem>> _ordersFuture;
  bool _requesting = false;

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
    _ordersFuture = context.read<ConciergeRepository>().fetchMyOrders();
  }

  Future<void> _requestOrder(String orderType) async {
    final l10n = AppLocalizations.of(context)!;
    if (_requesting) return;
    setState(() => _requesting = true);
    try {
      final vehicles = await context.read<GarageRepository>().fetchVehicles();
      if (!mounted) return;
      if (vehicles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.conciergeAddVehicleFirst)),
        );
        return;
      }

      final vehicle = vehicles.length == 1
          ? vehicles.first
          : await showModalBottomSheet<Vehicle>(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (sheetContext) => GlassCard(
                strong: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.conciergeSelectVehicle, style: Theme.of(sheetContext).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    ...vehicles.map((v) => ListTile(
                          title: Text(v.label, style: const TextStyle(color: AppColors.textPrimary)),
                          onTap: () => Navigator.of(sheetContext).pop(v),
                        )),
                  ],
                ),
              ),
            );
      if (vehicle == null || !mounted) return;

      await context.read<ConciergeRepository>().createOrder(orderType: orderType, vehicleId: vehicle.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.conciergeRequestReceived)));
        setState(_reload);
        _tabController.animateTo(1);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.conciergeSubmitFailed)));
      }
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  String _statusColorKey(String status) {
    if (status == 'completed') return 'green';
    if (status == 'cancelled') return 'red';
    return 'amber';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.conciergeTitle),
        bottom: TabBar(controller: _tabController, tabs: [Tab(text: l10n.conciergeRequestTab), Tab(text: l10n.conciergeOrdersTab)]),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: TabBarView(controller: _tabController, children: [_buildRequestTab(l10n), _buildOrdersTab()]),
        ),
      ),
    );
  }

  Widget _buildRequestTab(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
        children: ConciergeRepository.orderTypeKeys.map((key) {
          return GlassCard(
            onTap: _requesting ? null : () => _requestOrder(key),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_orderTypeIcons[key] ?? Icons.support_agent_outlined, size: 32, color: AppColors.goldLight),
                const SizedBox(height: 10),
                Text(ConciergeRepository.orderTypeLabel(l10n, key), style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrdersTab() {
    return FutureBuilder<List<ConciergeOrderItem>>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context)!;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.wifi_off,
            title: l10n.conciergeCouldNotLoadOrders,
            message: l10n.conciergeCheckConnectionRetry,
            actionLabel: l10n.commonRetry,
            onAction: () => setState(_reload),
          );
        }
        final orders = snapshot.data!;
        if (orders.isEmpty) {
          return EmptyState(icon: Icons.support_agent_outlined, title: l10n.conciergeNoOrdersYet, message: l10n.conciergeNoOrdersMessage);
        }
        return RefreshIndicator(
          onRefresh: () async => setState(_reload),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index];
              return GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(ConciergeRepository.orderTypeLabel(l10n, order.orderType), style: Theme.of(context).textTheme.titleLarge)),
                        StatusBadge(status: _statusColorKey(order.status), label: order.status.replaceAll('_', ' ')),
                      ],
                    ),
                    if (order.vehicleLabel != null) ...[
                      const SizedBox(height: 4),
                      Text(order.vehicleLabel!, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                    if (order.checklist.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ...order.checklist.map((item) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(item.done ? Icons.check_circle : Icons.radio_button_unchecked, size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: 8),
                                Expanded(child: Text(item.label, style: Theme.of(context).textTheme.bodySmall)),
                              ],
                            ),
                          )),
                    ],
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
