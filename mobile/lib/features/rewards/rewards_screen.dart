import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/gradient_button.dart';
import 'rewards_model.dart';
import 'rewards_repository.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  late Future<RewardsSummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _summaryFuture = context.read<RewardsRepository>().fetchMyRewards();
  }

  void _shareCode(String code) {
    Share.share('Join me on Car Nanny and use my referral code $code when you sign up!');
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referral code copied.')));
  }

  String _reasonLabel(String reason) {
    switch (reason) {
      case 'referral_bonus':
        return 'Referral bonus';
      case 'booking_completed':
        return 'Booking completed';
      case 'promo_credit':
        return 'Promo credit';
      case 'redemption':
        return 'Redeemed';
      default:
        return 'Adjustment';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rewards & Referrals')),
      body: GradientBackground(
        child: SafeArea(
          child: FutureBuilder<RewardsSummary>(
            future: _summaryFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return EmptyState(
                  icon: Icons.wifi_off,
                  title: 'Could not load rewards',
                  message: 'Check your connection and try again.',
                  actionLabel: 'Retry',
                  onAction: () => setState(_reload),
                );
              }
              final summary = snapshot.data!;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  GlassCard(
                    glow: true,
                    child: Column(
                      children: [
                        Text('${summary.pointsBalance}', style: Theme.of(context).textTheme.displayLarge),
                        const SizedBox(height: 4),
                        Text('Points balance', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Your referral code', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => _copyCode(summary.referralCode),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.glassFillStrong,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.glassBorder),
                            ),
                            child: Center(
                              child: Text(
                                summary.referralCode,
                                style: const TextStyle(
                                  color: AppColors.goldLight,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                  letterSpacing: 3,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GradientButton(
                          label: 'Share Referral Code',
                          icon: Icons.share_outlined,
                          onPressed: () => _shareCode(summary.referralCode),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Referrals', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  if (summary.referrals.isEmpty)
                    const EmptyState(icon: Icons.people_outline, title: 'No referrals yet', message: 'Share your code to start earning bonus points.')
                  else
                    ...summary.referrals.map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          child: Row(
                            children: [
                              Expanded(child: Text(r.referredUserName ?? 'A new member', style: Theme.of(context).textTheme.bodyLarge)),
                              Text(r.status, style: TextStyle(color: r.status == 'completed' ? AppColors.statusGreen : AppColors.statusAmber)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text('Activity', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  if (summary.transactions.isEmpty)
                    const EmptyState(icon: Icons.receipt_long_outlined, title: 'No activity yet', message: 'Points you earn will show up here.')
                  else
                    ...summary.transactions.map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          child: Row(
                            children: [
                              Expanded(child: Text(_reasonLabel(t.reason), style: Theme.of(context).textTheme.bodyLarge)),
                              Text('+${t.points}', style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
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
