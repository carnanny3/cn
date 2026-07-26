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

class ListingDetailScreen extends StatefulWidget {
  const ListingDetailScreen({super.key, required this.listingId});

  final String listingId;

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  late Future<VehicleListingItem> _listingFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _listingFuture = context.read<ListingRepository>().getOne(widget.listingId);
  }

  String _sellerLabel(String sellerType) {
    switch (sellerType) {
      case 'certified':
        return 'Car Nanny Certified';
      case 'dealer':
        return 'Dealer';
      default:
        return 'Private Seller';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Listing Details')),
      body: GradientBackground(
        child: SafeArea(
          child: FutureBuilder<VehicleListingItem>(
            future: _listingFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return EmptyState(
                  icon: Icons.wifi_off,
                  title: 'Could not load this listing',
                  message: 'Check your connection and try again.',
                  actionLabel: 'Retry',
                  onAction: () => setState(_reload),
                );
              }
              final listing = snapshot.data!;
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  GlassCard(
                    glow: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(listing.title, style: Theme.of(context).textTheme.titleLarge)),
                            StatusBadge(status: listing.sellerType == 'certified' ? 'green' : 'amber', label: _sellerLabel(listing.sellerType)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text('AED ${listing.askingPrice.toStringAsFixed(0)}',
                            style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.w800, fontSize: 24)),
                        const SizedBox(height: 12),
                        if (listing.mileageKm != null)
                          Row(
                            children: [
                              const Icon(Icons.speed_outlined, size: 18, color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              Text('${listing.mileageKm} km', style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.info_outline, size: 18, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            StatusBadge(status: listing.status == 'active' ? 'green' : 'amber', label: listing.status.toUpperCase()),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (listing.inspectionId != null)
                    GlassCard(
                      onTap: () => context.push('/inspection/${listing.inspectionId}/report'),
                      child: Row(
                        children: [
                          const Icon(Icons.fact_check_outlined, color: AppColors.goldLight),
                          const SizedBox(width: 12),
                          Expanded(child: Text('View Inspection Report', style: Theme.of(context).textTheme.bodyLarge)),
                          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                        ],
                      ),
                    )
                  else
                    GradientButton(
                      label: 'Request Independent Inspection',
                      onPressed: () => context.push('/inspection/book'),
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
