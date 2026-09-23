import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../l10n/generated/app_localizations.dart';
import 'logbook_forms.dart';
import 'logbook_models.dart';
import 'logbook_repository.dart';

/// Who can see and edit this vehicle. The primary owner can share by email and
/// remove people; a co-owner can only leave.
class CoOwnersCard extends StatefulWidget {
  const CoOwnersCard({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  State<CoOwnersCard> createState() => _CoOwnersCardState();
}

class _CoOwnersCardState extends State<CoOwnersCard> {
  late Future<List<CoOwner>> _owners;
  final _email = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _reload() => _owners = context.read<LogbookRepository>().fetchOwners(widget.vehicleId);

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      if (success != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
      setState(_reload);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is DioException ? ApiClient.messageFrom(e) : AppLocalizations.of(context)!.commonSomethingWentWrong),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    final email = _email.text.trim();
    if (email.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    await _run(() => context.read<LogbookRepository>().addCoOwner(widget.vehicleId, email), success: l10n.coOwnersAdded);
    if (mounted) _email.clear();
  }

  Future<void> _remove(CoOwner owner) async {
    final l10n = AppLocalizations.of(context)!;
    final leaving = owner.isYou;
    final confirmed = await confirmDelete(context, leaving ? l10n.coOwnersLeaveConfirm : l10n.coOwnersRemoveConfirm(owner.fullName));
    if (!confirmed || !mounted) return;
    final repo = context.read<LogbookRepository>();
    if (leaving) {
      final router = GoRouter.of(context);
      await _run(() => repo.removeOwner(widget.vehicleId, owner.userId));
      // Access is gone, so this vehicle's screens can no longer load.
      router.go('/garage');
    } else {
      await _run(() => repo.removeOwner(widget.vehicleId, owner.userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GlassCard(
      child: FutureBuilder<List<CoOwner>>(
        future: _owners,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()));
          }
          if (snapshot.hasError) {
            return Text(l10n.coOwnersCouldNotLoad, style: Theme.of(context).textTheme.bodyMedium);
          }
          final owners = snapshot.data!;
          final iAmPrimary = owners.any((o) => o.isYou && o.isPrimary);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.coOwnersTitle, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(l10n.coOwnersExplainer, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 10),
              for (final o in owners)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.glassFillStrong,
                        child: Text(
                          o.fullName.isEmpty ? '?' : o.fullName.characters.first.toUpperCase(),
                          style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              o.isYou ? '${o.fullName} (${l10n.coOwnersYou})' : o.fullName,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            Text(
                              o.isPrimary ? '${l10n.coOwnersPrimary} · ${o.email}' : o.email,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (!o.isPrimary && (iAmPrimary || o.isYou))
                        TextButton(
                          onPressed: _busy ? null : () => _remove(o),
                          child: Text(
                            o.isYou ? l10n.coOwnersLeave : l10n.coOwnersRemove,
                            style: const TextStyle(color: AppColors.statusRed),
                          ),
                        ),
                    ],
                  ),
                ),
              if (iAmPrimary) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: InputDecoration(labelText: l10n.coOwnersAdd, hintText: l10n.coOwnersEmailHint),
                        onSubmitted: (_) => _share(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: _busy ? null : _share,
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.glassBorder)),
                      child: Text(l10n.coOwnersShare),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
