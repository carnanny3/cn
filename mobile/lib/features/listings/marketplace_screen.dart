import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/api/file_pickers.dart';
import '../../core/api/upload_file.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/status_badge.dart';
import '../../l10n/generated/app_localizations.dart';
import 'listing_model.dart';
import 'listing_repository.dart';
import 'listing_thumbnail.dart';

/// Mirrors MAX_LISTING_PHOTOS in the backend's storage.service.ts — the API
/// rejects more than this, so the picker stops before the request would fail.
const _maxPhotos = 8;

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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.marketplaceTitle),
        actions: [
          IconButton(
            icon: Icon(_compareMode ? Icons.close : Icons.compare_arrows, color: AppColors.goldLight),
            tooltip: _compareMode ? l10n.marketplaceCancelCompare : l10n.marketplaceCompareListings,
            onPressed: () => setState(() {
              _compareMode = !_compareMode;
              if (!_compareMode) _compareSelection.clear();
            }),
          ),
        ],
        bottom: TabBar(controller: _tabController, tabs: [Tab(text: l10n.marketplaceBrowseTab), Tab(text: l10n.marketplaceSellTab), Tab(text: l10n.marketplaceMyListingsTab)]),
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
              label: Text(l10n.marketplaceCompareCount(_compareSelection.length), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
              onPressed: () => context.push('/listings/compare?ids=${_compareSelection.join(',')}'),
            )
          : null,
    );
  }

  Widget _listingCard(AppLocalizations l10n, VehicleListingItem listing) {
    final selected = _compareSelection.contains(listing.id);
    return GlassCard(
      onTap: _compareMode ? () => _toggleCompareSelection(listing.id) : () => context.push('/listings/${listing.id}'),
      child: Row(
        children: [
          if (_compareMode) ...[
            Icon(selected ? Icons.check_box : Icons.check_box_outline_blank, color: AppColors.goldLight),
            const SizedBox(width: 10),
          ],
          ListingThumbnail(url: listing.photoUrls.isEmpty ? null : listing.photoUrls.first),
          const SizedBox(width: 12),
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
                Text(l10n.marketplacePriceAed(listing.askingPrice.toStringAsFixed(0)), style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.w700)),
                if (listing.mileageKm != null) Text(l10n.marketplaceMileageKm(listing.mileageKm!.toString()), style: Theme.of(context).textTheme.bodySmall),
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
        final l10n = AppLocalizations.of(context)!;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.wifi_off,
            title: l10n.marketplaceCouldNotLoadListings,
            message: l10n.marketplaceCheckConnectionRetry,
            actionLabel: l10n.commonRetry,
            onAction: () => setState(_reloadBrowse),
          );
        }
        final listings = snapshot.data!;
        if (listings.isEmpty) {
          return EmptyState(icon: Icons.directions_car_outlined, title: l10n.marketplaceNoListingsYet, message: l10n.marketplaceNoListingsMessage);
        }
        return RefreshIndicator(
          onRefresh: () async => setState(_reloadBrowse),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 96, 16, 100),
            itemCount: listings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _listingCard(l10n, listings[index]),
          ),
        );
      },
    );
  }

  Widget _buildMineTab() {
    return FutureBuilder<List<VehicleListingItem>>(
      future: _mineFuture,
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context)!;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.wifi_off,
            title: l10n.marketplaceCouldNotLoadYourListings,
            message: l10n.marketplaceCheckConnectionRetry,
            actionLabel: l10n.commonRetry,
            onAction: () => setState(_reloadMine),
          );
        }
        final listings = snapshot.data!;
        if (listings.isEmpty) {
          return EmptyState(icon: Icons.sell_outlined, title: l10n.marketplaceNoYourListings, message: l10n.marketplaceListFromSellTab);
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
                  ListingThumbnail(
                    url: listings[index].photoUrls.isEmpty ? null : listings[index].photoUrls.first,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(listings[index].title, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(l10n.marketplacePriceAed(listings[index].askingPrice.toStringAsFixed(0)), style: Theme.of(context).textTheme.bodyMedium),
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
  final _photos = <UploadFile>[];

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
    final l10n = AppLocalizations.of(context)!;
    final make = _makeController.text.trim();
    final model = _modelController.text.trim();
    final year = int.tryParse(_yearController.text.trim());
    final price = double.tryParse(_priceController.text.trim());
    if (make.isEmpty || model.isEmpty || year == null || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.marketplaceFillRequiredFields)));
      return;
    }
    setState(() => _submitting = true);
    try {
      final repository = context.read<ListingRepository>();
      // Photos have to exist before the listing references them — the API only
      // accepts photo URLs it issued itself.
      final photoUrls = _photos.isEmpty ? null : await repository.uploadPhotos(_photos);
      await repository.createListing(
            make: make,
            model: model,
            year: year,
            mileageKm: int.tryParse(_mileageController.text.trim()),
            askingPrice: price,
            photoUrls: photoUrls,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.marketplaceListingLive)));
        _makeController.clear();
        _modelController.clear();
        _yearController.clear();
        _mileageController.clear();
        _priceController.clear();
        setState(_photos.clear);
        widget.onCreated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is DioException ? ApiClient.messageFrom(e) : l10n.marketplaceCreateListingFailed),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _addPhotos() async {
    final l10n = AppLocalizations.of(context)!;
    final remaining = _maxPhotos - _photos.length;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.marketplacePhotoLimit)));
      return;
    }
    final picked = await pickImages(limit: remaining);
    if (picked.isEmpty || !mounted) return;
    setState(() => _photos.addAll(picked));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const textStyle = TextStyle(color: AppColors.textPrimary);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 96, 20, 40),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.marketplaceSellCardTitle, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              TextField(controller: _makeController, style: textStyle, decoration: InputDecoration(labelText: l10n.marketplaceMakeLabel)),
              const SizedBox(height: 12),
              TextField(controller: _modelController, style: textStyle, decoration: InputDecoration(labelText: l10n.marketplaceModelLabel)),
              const SizedBox(height: 12),
              TextField(controller: _yearController, style: textStyle, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.marketplaceYearLabel)),
              const SizedBox(height: 12),
              TextField(controller: _mileageController, style: textStyle, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.marketplaceMileageLabel)),
              const SizedBox(height: 12),
              TextField(controller: _priceController, style: textStyle, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.marketplacePriceLabel)),
              const SizedBox(height: 18),
              Text(l10n.marketplacePhotosLabel, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 10),
              if (_photos.isNotEmpty)
                SizedBox(
                  height: 84,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _photos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) => _PhotoThumb(
                      bytes: _photos[index].bytes,
                      onRemove: () => setState(() => _photos.removeAt(index)),
                    ),
                  ),
                ),
              if (_photos.isNotEmpty) const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _submitting ? null : _addPhotos,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 18, color: AppColors.goldLight),
                label: Text(l10n.marketplaceAddPhotos),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.glassBorder)),
              ),
              const SizedBox(height: 20),
              GradientButton(
                label: _submitting && _photos.isNotEmpty ? l10n.marketplaceUploadingPhotos : l10n.marketplacePublishListing,
                loading: _submitting,
                onPressed: _submitting ? null : _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A picked-but-not-yet-uploaded photo, rendered from memory with a remove button.
class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.bytes, required this.onRemove});

  final Uint8List bytes;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(bytes, width: 84, height: 84, fit: BoxFit.cover),
        ),
        PositionedDirectional(
          top: 2,
          end: 2,
          child: InkWell(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
