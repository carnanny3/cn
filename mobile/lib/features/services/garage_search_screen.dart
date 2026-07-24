import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../garage/garage_repository.dart';
import 'partner_model.dart';
import 'services_repository.dart';

class GarageSearchScreen extends StatefulWidget {
  const GarageSearchScreen({super.key, required this.serviceCategory});

  final String serviceCategory;

  @override
  State<GarageSearchScreen> createState() => _GarageSearchScreenState();
}

class _GarageSearchScreenState extends State<GarageSearchScreen> {
  late Future<List<PartnerResult>> _resultsFuture;
  bool _booking = false;

  @override
  void initState() {
    super.initState();
    _resultsFuture = context.read<ServicesRepository>().searchGarages(widget.serviceCategory);
  }

  Future<void> _book(PartnerResult partner) async {
    setState(() => _booking = true);
    final garageRepository = context.read<GarageRepository>();
    final servicesRepository = context.read<ServicesRepository>();
    try {
      final vehicles = await garageRepository.fetchVehicles();
      if (!mounted) return;
      if (vehicles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add a vehicle to My Garage before booking a service.')),
        );
        return;
      }
      await servicesRepository.createBooking(
            bookingType: 'service',
            vehicleId: vehicles.first.id,
            partnerId: partner.id,
            serviceCategory: widget.serviceCategory,
            scheduledAt: DateTime.now().add(const Duration(days: 1)),
            totalAmount: partner.price,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booked with ${partner.businessName} — check Bookings for status.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not create the booking. Check the backend connection and try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = ServicesRepository.categories[widget.serviceCategory] ?? widget.serviceCategory;
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: GradientBackground(
        child: SafeArea(
          child: FutureBuilder<List<PartnerResult>>(
            future: _resultsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final results = snapshot.data!;
              if (results.isEmpty) {
                return const EmptyState(
                  icon: Icons.search_off,
                  title: 'No garages match right now',
                  message: 'Try a different service category or check back soon.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: results.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final p = results[index];
                  return GlassCard(
                    onTap: _booking ? null : () => _book(p),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.businessName, style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 4),
                              Text(
                                [
                                  '★ ${p.ratingAvg.toStringAsFixed(1)}',
                                  if (p.distanceKm != null) '${p.distanceKm!.toStringAsFixed(1)} km away',
                                  if (p.durationEstimateMinutes != null) '~${p.durationEstimateMinutes} min',
                                ].join(' · '),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'AED ${p.price.toStringAsFixed(0)}',
                          style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
