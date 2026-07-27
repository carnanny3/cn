import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/status_badge.dart';
import '../../l10n/generated/app_localizations.dart';
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

  String _sellerLabel(AppLocalizations l10n, String sellerType) {
    switch (sellerType) {
      case 'certified':
        return l10n.listingDetailSellerCertified;
      case 'dealer':
        return l10n.listingDetailSellerDealer;
      default:
        return l10n.listingDetailSellerPrivate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.listingDetailTitle)),
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
                  title: l10n.listingDetailCouldNotLoad,
                  message: l10n.listingDetailCheckConnection,
                  actionLabel: l10n.commonRetry,
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
                            StatusBadge(status: listing.sellerType == 'certified' ? 'green' : 'amber', label: _sellerLabel(l10n, listing.sellerType)),
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
                          Expanded(child: Text(l10n.listingDetailViewInspectionReport, style: Theme.of(context).textTheme.bodyLarge)),
                          Icon(
                            Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    )
                  else
                    GradientButton(
                      label: l10n.listingDetailRequestInspection,
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
