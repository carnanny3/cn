import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import 'listing_model.dart';
import 'listing_repository.dart';

class ListingCompareScreen extends StatefulWidget {
  const ListingCompareScreen({super.key, required this.ids});

  final List<String> ids;

  @override
  State<ListingCompareScreen> createState() => _ListingCompareScreenState();
}

class _ListingCompareScreenState extends State<ListingCompareScreen> {
  late Future<List<VehicleListingItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<ListingRepository>().compare(widget.ids);
  }

  Widget _row(String label, List<VehicleListingItem> listings, String Function(VehicleListingItem) value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          ...listings.map((l) => Expanded(child: Text(value(l), style: Theme.of(context).textTheme.bodyMedium))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compare Listings')),
      body: GradientBackground(
        child: SafeArea(
          child: FutureBuilder<List<VehicleListingItem>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || (snapshot.data?.isEmpty ?? true)) {
                return const EmptyState(icon: Icons.wifi_off, title: 'Could not load listings', message: 'Try again from the browse screen.');
              }
              final listings = snapshot.data!;
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const SizedBox(width: 90),
                            ...listings.map((l) => Expanded(
                                  child: Text(l.title, style: Theme.of(context).textTheme.titleLarge, maxLines: 2),
                                )),
                          ],
                        ),
                        const Divider(color: AppColors.textSecondary),
                        _row('Price', listings, (l) => 'AED ${l.askingPrice.toStringAsFixed(0)}'),
                        _row('Year', listings, (l) => '${l.year}'),
                        _row('Mileage', listings, (l) => l.mileageKm != null ? '${l.mileageKm} km' : '—'),
                        _row('Seller', listings, (l) => l.sellerType),
                        _row('Inspected', listings, (l) => l.inspectionId != null ? 'Yes' : 'No'),
                      ],
                    ),
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
