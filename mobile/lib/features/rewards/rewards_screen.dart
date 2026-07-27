import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/gradient_button.dart';
import '../../l10n/generated/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    Share.share('${l10n.rewardsShareMessagePrefix} $code ${l10n.rewardsShareMessageSuffix}');
  }

  void _copyCode(String code) {
    final l10n = AppLocalizations.of(context)!;
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.rewardsCodeCopied)));
  }

  String _reasonLabel(String reason, AppLocalizations l10n) {
    switch (reason) {
      case 'referral_bonus':
        return l10n.rewardsReasonReferralBonus;
      case 'booking_completed':
        return l10n.rewardsReasonBookingCompleted;
      case 'promo_credit':
        return l10n.rewardsReasonPromoCredit;
      case 'redemption':
        return l10n.rewardsReasonRedeemed;
      default:
        return l10n.rewardsReasonAdjustment;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.rewardsTitle)),
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
                  title: l10n.rewardsCouldNotLoad,
                  message: l10n.rewardsCheckConnection,
                  actionLabel: l10n.commonRetry,
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
                        Text(l10n.rewardsPointsBalance, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(l10n.rewardsYourReferralCode, style: Theme.of(context).textTheme.titleLarge),
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
                          label: l10n.rewardsShareReferralCode,
                          icon: Icons.share_outlined,
                          onPressed: () => _shareCode(summary.referralCode),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(l10n.rewardsReferrals, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  if (summary.referrals.isEmpty)
                    EmptyState(icon: Icons.people_outline, title: l10n.rewardsNoReferralsYet, message: l10n.rewardsShareCodeToEarn)
                  else
                    ...summary.referrals.map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          child: Row(
                            children: [
                              Expanded(child: Text(r.referredUserName ?? l10n.rewardsNewMember, style: Theme.of(context).textTheme.bodyLarge)),
                              Text(r.status, style: TextStyle(color: r.status == 'completed' ? AppColors.statusGreen : AppColors.statusAmber)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text(l10n.rewardsActivity, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  if (summary.transactions.isEmpty)
                    EmptyState(icon: Icons.receipt_long_outlined, title: l10n.rewardsNoActivityYet, message: l10n.rewardsPointsShowUpHere)
                  else
                    ...summary.transactions.map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          child: Row(
                            children: [
                              Expanded(child: Text(_reasonLabel(t.reason, l10n), style: Theme.of(context).textTheme.bodyLarge)),
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
