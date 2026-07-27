import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/status_badge.dart';
import '../../l10n/generated/app_localizations.dart';
import '../roadside/roadside_model.dart';
import '../roadside/roadside_repository.dart';
import 'partner_model.dart';
import 'partner_repository.dart';

class PartnerJobsScreen extends StatefulWidget {
  const PartnerJobsScreen({super.key});

  @override
  State<PartnerJobsScreen> createState() => _PartnerJobsScreenState();
}

class _PartnerJobsScreenState extends State<PartnerJobsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<PartnerBookingJob>> _bookingsFuture;
  late Future<List<PartnerInspectionJob>> _inspectionsFuture;
  late Future<List<RoadsideRequestItem>> _roadsideFuture;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _reload();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _reload() {
    final repo = context.read<PartnerRepository>();
    _bookingsFuture = repo.fetchMyBookingJobs();
    _inspectionsFuture = repo.fetchMyInspectionJobs();
    _roadsideFuture = context.read<RoadsideRepository>().fetchAssignedToMe();
  }

  Future<void> _updateRoadsideStatus(RoadsideRequestItem job, String status) async {
    setState(() => _busyId = job.id);
    try {
      await context.read<RoadsideRepository>().updateStatus(job.id, status);
      if (mounted) setState(_reload);
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.partnerJobsUpdateRequestFailed)));
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _updateBookingStatus(PartnerBookingJob job, String status) async {
    setState(() => _busyId = job.id);
    try {
      await context.read<PartnerRepository>().updateBookingStatus(job.id, status);
      if (mounted) setState(_reload);
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.partnerJobsUpdateJobFailed)));
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _startInspection(PartnerInspectionJob job) async {
    setState(() => _busyId = job.id);
    try {
      await context.read<PartnerRepository>().updateInspectionStatus(job.id, 'in_progress');
      if (mounted) setState(_reload);
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.partnerJobsStartJobFailed)));
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.partnerJobsTitle),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: l10n.partnerJobsTabBookings),
            Tab(text: l10n.partnerJobsTabInspections),
            Tab(text: l10n.partnerJobsTabRoadside),
          ],
        ),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [_buildBookingsTab(), _buildInspectionsTab(), _buildRoadsideTab()],
          ),
        ),
      ),
    );
  }

  Widget _buildRoadsideTab() {
    return FutureBuilder<List<RoadsideRequestItem>>(
      future: _roadsideFuture,
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context)!;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.wifi_off,
            title: l10n.partnerJobsRoadsideCouldNotLoad,
            message: l10n.partnerJobsCheckConnection,
            actionLabel: l10n.commonRetry,
            onAction: () => setState(_reload),
          );
        }
        final jobs = snapshot.data!;
        if (jobs.isEmpty) {
          return EmptyState(
            icon: Icons.support_agent_outlined,
            title: l10n.partnerJobsNoRoadsideYet,
            message: l10n.partnerJobsNoRoadsideMessage,
          );
        }
        return RefreshIndicator(
          onRefresh: () async => setState(_reload),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: jobs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final job = jobs[index];
              final busy = _busyId == job.id;
              return GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(RoadsideRepository.serviceTypes[job.serviceType] ?? job.serviceType, style: Theme.of(context).textTheme.titleLarge)),
                        StatusBadge(status: _roadsideStatusColor(job.status), label: job.status.replaceAll('_', ' ')),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(_formatDate(job.requestedAt), style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: busy
                          ? [const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))]
                          : _roadsideActions(job, l10n),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  List<Widget> _roadsideActions(RoadsideRequestItem job, AppLocalizations l10n) {
    switch (job.status) {
      case 'matched':
        return [TextButton(onPressed: () => _updateRoadsideStatus(job, 'accepted'), child: Text(l10n.partnerJobsAccept))];
      case 'accepted':
        return [TextButton(onPressed: () => _updateRoadsideStatus(job, 'en_route'), child: Text(l10n.partnerJobsStartDriving))];
      case 'en_route':
        return [TextButton(onPressed: () => _updateRoadsideStatus(job, 'arrived'), child: Text(l10n.partnerJobsMarkArrived))];
      case 'arrived':
        return [TextButton(onPressed: () => _updateRoadsideStatus(job, 'in_service'), child: Text(l10n.partnerJobsStartService))];
      case 'in_service':
        return [TextButton(onPressed: () => _updateRoadsideStatus(job, 'completed'), child: Text(l10n.partnerJobsMarkComplete))];
      default:
        return [];
    }
  }

  String _roadsideStatusColor(String status) {
    if (status == 'completed') return 'green';
    if (status == 'cancelled') return 'red';
    return 'amber';
  }

  Widget _buildBookingsTab() {
    return FutureBuilder<List<PartnerBookingJob>>(
      future: _bookingsFuture,
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context)!;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.wifi_off,
            title: l10n.partnerJobsBookingsCouldNotLoad,
            message: l10n.partnerJobsCheckConnection,
            actionLabel: l10n.commonRetry,
            onAction: () => setState(_reload),
          );
        }
        final jobs = snapshot.data!;
        if (jobs.isEmpty) {
          return EmptyState(
            icon: Icons.build_outlined,
            title: l10n.partnerJobsNoBookingsYet,
            message: l10n.partnerJobsNoBookingsMessage,
          );
        }
        return RefreshIndicator(
          onRefresh: () async => setState(_reload),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: jobs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final job = jobs[index];
              final busy = _busyId == job.id;
              return GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(job.serviceCategory ?? l10n.partnerJobsServiceFallback, style: Theme.of(context).textTheme.titleLarge)),
                        StatusBadge(status: _bookingStatusColor(job.status), label: job.status.replaceAll('_', ' ')),
                      ],
                    ),
                    if (job.customerName != null) ...[
                      const SizedBox(height: 4),
                      Text(job.customerName!, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                    const SizedBox(height: 4),
                    Text(_formatDate(job.scheduledAt), style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text('AED ${job.totalAmount.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        ..._bookingActions(job, busy, l10n),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  List<Widget> _bookingActions(PartnerBookingJob job, bool busy, AppLocalizations l10n) {
    if (busy) return [const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))];
    switch (job.status) {
      case 'pending':
        return [
          TextButton(
            onPressed: () => _updateBookingStatus(job, 'cancelled'),
            child: Text(l10n.partnerJobsReject, style: const TextStyle(color: AppColors.statusRed)),
          ),
          TextButton(onPressed: () => _updateBookingStatus(job, 'confirmed'), child: Text(l10n.partnerJobsAccept)),
        ];
      case 'confirmed':
        return [TextButton(onPressed: () => _updateBookingStatus(job, 'in_progress'), child: Text(l10n.partnerJobsStartJob))];
      case 'in_progress':
        return [TextButton(onPressed: () => _updateBookingStatus(job, 'completed'), child: Text(l10n.partnerJobsMarkComplete))];
      default:
        return [];
    }
  }

  String _bookingStatusColor(String status) {
    if (status == 'completed') return 'green';
    if (status == 'cancelled') return 'red';
    return 'amber';
  }

  Widget _buildInspectionsTab() {
    return FutureBuilder<List<PartnerInspectionJob>>(
      future: _inspectionsFuture,
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context)!;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.wifi_off,
            title: l10n.partnerJobsInspectionsCouldNotLoad,
            message: l10n.partnerJobsCheckConnection,
            actionLabel: l10n.commonRetry,
            onAction: () => setState(_reload),
          );
        }
        final jobs = snapshot.data!;
        if (jobs.isEmpty) {
          return EmptyState(
            icon: Icons.fact_check_outlined,
            title: l10n.partnerJobsNoInspectionsYet,
            message: l10n.partnerJobsNoInspectionsMessage,
          );
        }
        return RefreshIndicator(
          onRefresh: () async => setState(_reload),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: jobs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final job = jobs[index];
              final busy = _busyId == job.id;
              return GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(job.vehicleLabel ?? l10n.partnerJobsVehicleInspectionFallback, style: Theme.of(context).textTheme.titleLarge)),
                        StatusBadge(status: _inspectionStatusColor(job.status), label: job.status.replaceAll('_', ' ')),
                      ],
                    ),
                    if (job.locationAddress != null) ...[
                      const SizedBox(height: 4),
                      Text(job.locationAddress!, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                    const SizedBox(height: 4),
                    Text(_formatDate(job.scheduledAt), style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (busy)
                          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        else if (job.status == 'assigned')
                          TextButton(onPressed: () => _startInspection(job), child: Text(l10n.partnerJobsStartJob))
                        else if (job.status == 'in_progress')
                          TextButton(
                            onPressed: () => context.push('/partner/inspection/${job.id}/checklist').then((_) => setState(_reload)),
                            child: Text(l10n.partnerJobsCompleteChecklist),
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
    );
  }

  String _inspectionStatusColor(String status) {
    if (status == 'completed') return 'green';
    if (status == 'cancelled') return 'red';
    return 'amber';
  }
}
