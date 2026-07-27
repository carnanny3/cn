import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/status_badge.dart';
import '../../l10n/generated/app_localizations.dart';
import 'roadside_model.dart';
import 'roadside_repository.dart';

/// Full-screen takeover during an active roadside request, per the product
/// spec's UX guidance for emotionally urgent moments — not a normal nav
/// screen, minimal chrome, one big primary action.
class RoadsideTrackingScreen extends StatefulWidget {
  const RoadsideTrackingScreen({super.key, required this.requestId});

  final String requestId;

  @override
  State<RoadsideTrackingScreen> createState() => _RoadsideTrackingScreenState();
}

class _RoadsideTrackingScreenState extends State<RoadsideTrackingScreen> {
  RoadsideRequestItem? _request;
  bool _loading = true;
  bool _cancelling = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final request = await context.read<RoadsideRepository>().track(widget.requestId);
      if (mounted) setState(() => _request = request);
    } catch (_) {
      // Keep showing the last known state on a transient failure — this
      // screen shouldn't flash errors during a live emergency wait.
    } finally {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  Future<void> _callProvider() async {
    final phone = _request?.providerPhone;
    if (phone == null) return;
    final uri = Uri(scheme: 'tel', path: phone);
    await launchUrl(uri);
  }

  Future<void> _cancel() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _cancelling = true);
    try {
      await context.read<RoadsideRepository>().cancel(widget.requestId);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.roadsideTrackingCancelFailed)));
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  String _statusMessage(AppLocalizations l10n, String status) {
    switch (status) {
      case 'requested':
        return l10n.roadsideTrackingStatusRequested;
      case 'matched':
        return l10n.roadsideTrackingStatusMatched;
      case 'accepted':
        return l10n.roadsideTrackingStatusAccepted;
      case 'en_route':
        return l10n.roadsideTrackingStatusEnRoute;
      case 'arrived':
        return l10n.roadsideTrackingStatusArrived;
      case 'in_service':
        return l10n.roadsideTrackingStatusInService;
      case 'completed':
        return l10n.roadsideTrackingStatusCompleted;
      case 'cancelled':
        return l10n.roadsideTrackingStatusCancelled;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final request = _request;
    final isActive = request != null && request.status != 'completed' && request.status != 'cancelled';

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: _loading || request == null
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              RoadsideRepository.serviceTypeLabel(l10n, request.serviceType),
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                          StatusBadge(
                            status: request.status == 'completed' ? 'green' : (request.status == 'cancelled' ? 'red' : 'amber'),
                            label: request.status.replaceAll('_', ' '),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: Center(
                          child: GlassCard(
                            glow: true,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  request.status == 'completed' ? Icons.check_circle_outline : Icons.support_agent,
                                  size: 56,
                                  color: AppColors.goldLight,
                                ),
                                const SizedBox(height: 16),
                                Text(_statusMessage(l10n, request.status), style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                                if (request.providerName != null) ...[
                                  const SizedBox(height: 8),
                                  Text(request.providerName!, style: Theme.of(context).textTheme.bodyLarge),
                                ],
                                if (request.etaMinutes != null && isActive) ...[
                                  const SizedBox(height: 16),
                                  Text(l10n.roadsideTrackingEtaMinutes(request.etaMinutes!), style: Theme.of(context).textTheme.displayLarge),
                                  Text(l10n.roadsideTrackingEstimatedArrival, style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (isActive) ...[
                        if (request.providerPhone != null) ...[
                          GradientButton(label: l10n.roadsideTrackingCallProvider, icon: Icons.call, onPressed: _callProvider),
                          const SizedBox(height: 12),
                        ],
                        TextButton(
                          onPressed: _cancelling ? null : _cancel,
                          child: Text(_cancelling ? l10n.roadsideTrackingCancelling : l10n.roadsideTrackingCancelRequest, style: const TextStyle(color: AppColors.statusRed)),
                        ),
                      ] else
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            side: const BorderSide(color: AppColors.glassBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                          child: Text(l10n.roadsideTrackingDone),
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
