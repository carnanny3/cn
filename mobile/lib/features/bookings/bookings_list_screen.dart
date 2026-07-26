import 'package:flutter/material.dart';
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
          const SnackBar(content: Text('Could not cancel this booking. Check your connection and try again.')),
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

  String _titleFor(AppLocalizations l10n, Booking b) {
    if (b.bookingType == 'inspection') return l10n.bookingPrePurchaseInspection;
    return ServicesRepository.categoryLabel(l10n, b.serviceCategory ?? '');
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
                );
              }
              return RefreshIndicator(
                onRefresh: () async => setState(_reload),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 96, 16, 32),
                  itemCount: bookings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final b = bookings[index];
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
