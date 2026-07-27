import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/status_badge.dart';
import '../../l10n/generated/app_localizations.dart';
import 'partner_model.dart';
import 'partner_repository.dart';

class PartnerHomeScreen extends StatefulWidget {
  const PartnerHomeScreen({super.key});

  @override
  State<PartnerHomeScreen> createState() => _PartnerHomeScreenState();
}

class _PartnerHomeScreenState extends State<PartnerHomeScreen> {
  late Future<(PartnerProfile, PartnerEarnings)> _dataFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final repo = context.read<PartnerRepository>();
    _dataFuture = Future.wait([repo.fetchMyProfile(), repo.fetchMyEarnings()])
        .then((results) => (results[0] as PartnerProfile, results[1] as PartnerEarnings));
  }

  String _statusColorKey(String status) {
    switch (status) {
      case 'verified':
        return 'green';
      case 'rejected':
      case 'suspended':
        return 'red';
      default:
        return 'amber';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, title: Text(l10n.partnerHomeTitle)),
      body: GradientBackground(
        child: SafeArea(
          child: FutureBuilder<(PartnerProfile, PartnerEarnings)>(
            future: _dataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return EmptyState(
                  icon: Icons.wifi_off,
                  title: l10n.partnerHomeCouldNotLoad,
                  message: l10n.homeCheckConnection,
                  actionLabel: l10n.commonRetry,
                  onAction: () => setState(_reload),
                );
              }
              final (profile, earnings) = snapshot.data!;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 96, 16, 32),
                children: [
                  GlassCard(
                    glow: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile.businessName, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            StatusBadge(status: _statusColorKey(profile.status), label: profile.status.toUpperCase()),
                            const SizedBox(width: 10),
                            Text('★ ${profile.ratingAvg.toStringAsFixed(1)}', style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                        if (profile.status == 'pending') ...[
                          const SizedBox(height: 12),
                          Text(
                            l10n.partnerHomePendingReview,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(l10n.partnerHomeEarnings, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          child: Column(
                            children: [
                              Text('AED ${earnings.netPayout.toStringAsFixed(0)}', style: Theme.of(context).textTheme.headlineMedium),
                              const SizedBox(height: 4),
                              Text(l10n.partnerHomeNetPayout, style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassCard(
                          child: Column(
                            children: [
                              Text('${earnings.completedJobCount}', style: Theme.of(context).textTheme.headlineMedium),
                              const SizedBox(height: 4),
                              Text(l10n.partnerHomeCompletedJobs, style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.partnerHomeGrossCommission((earnings.commissionRate * 100).toStringAsFixed(0)),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text('AED ${earnings.grossAmount.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.w700)),
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
