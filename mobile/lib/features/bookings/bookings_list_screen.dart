import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/status_badge.dart';
import '../services/services_repository.dart';
import 'booking_model.dart';
import '../../l10n/generated/app_localizations.dart';

class BookingsListScreen extends StatefulWidget {
  const BookingsListScreen({super.key});

  @override
  State<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends State<BookingsListScreen> {
  late Future<List<Booking>> _bookingsFuture;
  String? _cancellingId;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _bookingsFuture = context.read<ServicesRepository>().fetchBookings();
  }

  Future<void> _cancel(Booking booking) async {
    setState(() => _cancellingId = booking.id);
    try {
      await context.read<ServicesRepository>().cancelBooking(booking.id);
      if (mounted) setState(_reload);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.bookingsCancelFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _cancellingId = null);
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  /// Every booking needs a title. serviceCategory is optional on roadside and
  /// concierge bookings, so falling straight through to the category lookup
  /// used to leave those cards with a blank heading.
  String _titleFor(AppLocalizations l10n, Booking b) {
    switch (b.bookingType) {
      case 'inspection':
        return l10n.bookingPrePurchaseInspection;
      case 'roadside':
        return l10n.roadsideRequestTitle;
      case 'concierge':
        return l10n.conciergeTitle;
    }
    final category = b.serviceCategory;
    if (category == null || category.isEmpty) return l10n.partnerJobsServiceFallback;
    return ServicesRepository.categoryLabel(l10n, category);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, title: Text(l10n.navBookings)),
      body: GradientBackground(
        child: SafeArea(
          child: FutureBuilder<List<Booking>>(
            future: _bookingsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return EmptyState(
                  icon: Icons.wifi_off,
                  title: l10n.bookingsCouldNotLoad,
                  message: l10n.bookingsCheckConnection,
                  actionLabel: l10n.commonRetry,
                  onAction: () => setState(_reload),
                );
              }
              final bookings = snapshot.data!;
              if (bookings.isEmpty) {
                return EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: l10n.bookingsNoneYet,
                  message: l10n.bookingsNoneYetMessage,
                  actionLabel: l10n.homeBookService,
                  onAction: () => context.push('/services').then((_) => setState(_reload)),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => setState(_reload),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 96, 16, 32),
                  // Row 0 is the "book something" entry point — booking used to
                  // live in its own tab, so this tab has to offer it directly.
                  itemCount: bookings.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _BookCtas(onBooked: () => setState(_reload));
                    }
                    final b = bookings[index - 1];
                    return GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(_titleFor(l10n, b), style: Theme.of(context).textTheme.titleLarge),
                              ),
                              StatusBadge(status: b.statusColorKey, label: b.status.replaceAll('_', ' ')),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (b.partnerName != null)
                            Text(b.partnerName!, style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 4),
                          Text(_formatDate(b.scheduledAt), style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text(
                                'AED ${b.totalAmount.toStringAsFixed(0)}',
                                style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.w700),
                              ),
                              const Spacer(),
                              if (b.cancellable)
                                TextButton(
                                  onPressed: _cancellingId == b.id ? null : () => _cancel(b),
                                  child: Text(
                                    _cancellingId == b.id ? l10n.bookingsCancelling : l10n.bookingsCancel,
                                    style: const TextStyle(color: AppColors.statusRed),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The two things a customer can start from this tab. Sits above the booking
/// list so an empty-handed user always has an obvious next step.
class _BookCtas extends StatelessWidget {
  const _BookCtas({required this.onBooked});

  final VoidCallback onBooked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _Cta(
            icon: Icons.build_outlined,
            label: l10n.homeBookService,
            onTap: () => context.push('/services').then((_) => onBooked()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Cta(
            icon: Icons.fact_check_outlined,
            label: l10n.homeInspectACar,
            onTap: () => context.push('/inspection/book').then((_) => onBooked()),
          ),
        ),
      ],
    );
  }
}

class _Cta extends StatelessWidget {
  const _Cta({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.goldLight),
          const SizedBox(height: 10),
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
