import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/status_badge.dart';
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
    setState(() => _cancelling = true);
    try {
      await context.read<RoadsideRepository>().cancel(widget.requestId);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not cancel. Try again.')));
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  String _statusMessage(String status) {
    switch (status) {
      case 'requested':
        return 'Finding you a provider...';
      case 'matched':
        return 'Provider matched';
      case 'accepted':
        return 'Provider is preparing to head your way';
      case 'en_route':
        return 'Provider is on the way';
      case 'arrived':
        return 'Provider has arrived';
      case 'in_service':
        return 'Service in progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                              RoadsideRepository.serviceTypes[request.serviceType] ?? request.serviceType,
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
                                Text(_statusMessage(request.status), style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                                if (request.providerName != null) ...[
                                  const SizedBox(height: 8),
                                  Text(request.providerName!, style: Theme.of(context).textTheme.bodyLarge),
                                ],
                                if (request.etaMinutes != null && isActive) ...[
                                  const SizedBox(height: 16),
                                  Text('${request.etaMinutes} min', style: Theme.of(context).textTheme.displayLarge),
                                  Text('estimated arrival', style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (isActive) ...[
                        if (request.providerPhone != null) ...[
                          GradientButton(label: 'Call Provider', icon: Icons.call, onPressed: _callProvider),
                          const SizedBox(height: 12),
                        ],
                        TextButton(
                          onPressed: _cancelling ? null : _cancel,
                          child: Text(_cancelling ? 'Cancelling...' : 'Cancel Request', style: const TextStyle(color: AppColors.statusRed)),
                        ),
                      ] else
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            side: const BorderSide(color: AppColors.glassBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                          child: const Text('Done'),
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
