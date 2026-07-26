import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/status_badge.dart';
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
    if (_requesting) return;
    setState(() => _requesting = true);
    try {
      final vehicles = await context.read<GarageRepository>().fetchVehicles();
      if (!mounted) return;
      if (vehicles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add a vehicle to My Garage before requesting concierge services.')),
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
                    Text('Select a vehicle', style: Theme.of(sheetContext).textTheme.titleLarge),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request received — check My Orders for status.')));
        setState(_reload);
        _tabController.animateTo(1);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not submit the request. Try again.')));
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Concierge'),
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: 'Request'), Tab(text: 'My Orders')]),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: TabBarView(controller: _tabController, children: [_buildRequestTab(), _buildOrdersTab()]),
        ),
      ),
    );
  }

  Widget _buildRequestTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
        children: ConciergeRepository.orderTypes.entries.map((entry) {
          return GlassCard(
            onTap: _requesting ? null : () => _requestOrder(entry.key),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_orderTypeIcons[entry.key] ?? Icons.support_agent_outlined, size: 32, color: AppColors.goldLight),
                const SizedBox(height: 10),
                Text(entry.value, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.wifi_off,
            title: 'Could not load your orders',
            message: 'Check your connection and try again.',
            actionLabel: 'Retry',
            onAction: () => setState(_reload),
          );
        }
        final orders = snapshot.data!;
        if (orders.isEmpty) {
          return const EmptyState(icon: Icons.support_agent_outlined, title: 'No concierge orders yet', message: 'Request a service from the Request tab.');
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
                        Expanded(child: Text(ConciergeRepository.orderTypes[order.orderType] ?? order.orderType, style: Theme.of(context).textTheme.titleLarge)),
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
