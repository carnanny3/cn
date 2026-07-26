import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/status_badge.dart';
import 'listing_model.dart';
import 'listing_repository.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<VehicleListingItem>> _browseFuture;
  late Future<List<VehicleListingItem>> _mineFuture;
  final Set<String> _compareSelection = {};
  bool _compareMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _reloadBrowse();
    _reloadMine();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _reloadBrowse() {
    _browseFuture = context.read<ListingRepository>().browseActive();
  }

  void _reloadMine() {
    _mineFuture = context.read<ListingRepository>().fetchMyListings();
  }

  void _toggleCompareSelection(String id) {
    setState(() {
      if (_compareSelection.contains(id)) {
        _compareSelection.remove(id);
      } else if (_compareSelection.length < 3) {
        _compareSelection.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Buy a Car'),
        actions: [
          IconButton(
            icon: Icon(_compareMode ? Icons.close : Icons.compare_arrows, color: AppColors.goldLight),
            tooltip: _compareMode ? 'Cancel compare' : 'Compare listings',
            onPressed: () => setState(() {
              _compareMode = !_compareMode;
              if (!_compareMode) _compareSelection.clear();
            }),
          ),
        ],
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: 'Browse'), Tab(text: 'Sell'), Tab(text: 'My Listings')]),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: TabBarView(controller: _tabController, children: [_buildBrowseTab(), _SellTab(onCreated: () => setState(_reloadMine)), _buildMineTab()]),
        ),
      ),
      floatingActionButton: _compareMode && _compareSelection.length >= 2
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.goldLight,
              icon: const Icon(Icons.compare_arrows, color: Colors.black),
              label: Text('Compare (${_compareSelection.length})', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
              onPressed: () => context.push('/listings/compare?ids=${_compareSelection.join(',')}'),
            )
          : null,
    );
  }

  Widget _listingCard(VehicleListingItem listing) {
    final selected = _compareSelection.contains(listing.id);
    return GlassCard(
      onTap: _compareMode ? () => _toggleCompareSelection(listing.id) : () => context.push('/listings/${listing.id}'),
      child: Row(
        children: [
          if (_compareMode) ...[
            Icon(selected ? Icons.check_box : Icons.check_box_outline_blank, color: AppColors.goldLight),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(listing.title, style: Theme.of(context).textTheme.titleLarge)),
                    StatusBadge(status: listing.sellerType == 'certified' ? 'green' : 'amber', label: listing.sellerType),
                  ],
                ),
                const SizedBox(height: 6),
                Text('AED ${listing.askingPrice.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.w700)),
                if (listing.mileageKm != null) Text('${listing.mileageKm} km', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrowseTab() {
    return FutureBuilder<List<VehicleListingItem>>(
      future: _browseFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.wifi_off,
            title: 'Could not load listings',
            message: 'Check your connection and try again.',
            actionLabel: 'Retry',
            onAction: () => setState(_reloadBrowse),
          );
        }
        final listings = snapshot.data!;
        if (listings.isEmpty) {
          return const EmptyState(icon: Icons.directions_car_outlined, title: 'No listings yet', message: 'Check back soon for certified and private listings.');
        }
        return RefreshIndicator(
          onRefresh: () async => setState(_reloadBrowse),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 96, 16, 100),
            itemCount: listings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _listingCard(listings[index]),
          ),
        );
      },
    );
  }

  Widget _buildMineTab() {
    return FutureBuilder<List<VehicleListingItem>>(
      future: _mineFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.wifi_off,
            title: 'Could not load your listings',
            message: 'Check your connection and try again.',
            actionLabel: 'Retry',
            onAction: () => setState(_reloadMine),
          );
        }
        final listings = snapshot.data!;
        if (listings.isEmpty) {
          return const EmptyState(icon: Icons.sell_outlined, title: 'You have no listings', message: 'List your car for sale from the Sell tab.');
        }
        return RefreshIndicator(
          onRefresh: () async => setState(_reloadMine),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 96, 16, 100),
            itemCount: listings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => GlassCard(
              onTap: () => context.push('/listings/${listings[index].id}'),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(listings[index].title, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text('AED ${listings[index].askingPrice.toStringAsFixed(0)}', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  StatusBadge(status: listings[index].status == 'active' ? 'green' : 'amber', label: listings[index].status),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SellTab extends StatefulWidget {
  const _SellTab({required this.onCreated});

  final VoidCallback onCreated;

  @override
  State<_SellTab> createState() => _SellTabState();
}

class _SellTabState extends State<_SellTab> {
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _mileageController = TextEditingController();
  final _priceController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _mileageController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final make = _makeController.text.trim();
    final model = _modelController.text.trim();
    final year = int.tryParse(_yearController.text.trim());
    final price = double.tryParse(_priceController.text.trim());
    if (make.isEmpty || model.isEmpty || year == null || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill in make, model, year, and asking price.')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await context.read<ListingRepository>().createListing(
            make: make,
            model: model,
            year: year,
            mileageKm: int.tryParse(_mileageController.text.trim()),
            askingPrice: price,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your listing is live — check My Listings.')));
        _makeController.clear();
        _modelController.clear();
        _yearController.clear();
        _mileageController.clear();
        _priceController.clear();
        widget.onCreated();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not create the listing. Try again.')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(color: AppColors.textPrimary);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 96, 20, 40),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('List your car for sale', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              TextField(controller: _makeController, style: textStyle, decoration: const InputDecoration(labelText: 'Make')),
              const SizedBox(height: 12),
              TextField(controller: _modelController, style: textStyle, decoration: const InputDecoration(labelText: 'Model')),
              const SizedBox(height: 12),
              TextField(controller: _yearController, style: textStyle, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Year')),
              const SizedBox(height: 12),
              TextField(controller: _mileageController, style: textStyle, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Mileage (km, optional)')),
              const SizedBox(height: 12),
              TextField(controller: _priceController, style: textStyle, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Asking price (AED)')),
              const SizedBox(height: 20),
              GradientButton(label: 'Publish Listing', loading: _submitting, onPressed: _submitting ? null : _submit),
            ],
          ),
        ),
      ],
    );
  }
}
