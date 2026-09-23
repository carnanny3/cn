import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../l10n/generated/app_localizations.dart';
import 'logbook_format.dart';
import 'logbook_models.dart';
import 'logbook_repository.dart';

/// Reminders that are overdue, due soon or upcoming, across every vehicle the
/// user owns. Renders nothing at all when there's nothing to act on (or it
/// can't load), so the garage list never gains an empty or error card.
class AttentionCard extends StatefulWidget {
  const AttentionCard({super.key});

  @override
  State<AttentionCard> createState() => _AttentionCardState();
}

class _AttentionCardState extends State<AttentionCard> {
  late final Future<List<Reminder>> _items = context.read<LogbookRepository>().fetchAttention();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<List<Reminder>>(
      future: _items,
      builder: (context, snapshot) {
        final items = snapshot.data;
        if (items == null || items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            glow: items.any((r) => r.urgency == 'overdue'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications_active_outlined, color: AppColors.goldLight, size: 20),
                    const SizedBox(width: 8),
                    Text(l10n.attentionTitle, style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 8),
                for (final r in items.take(5))
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: r.vehicleId == null ? null : () => context.push('/garage/${r.vehicleId}/logbook?tab=reminders'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StatusBadge(status: urgencyStatus(r.urgency), label: urgencyLabel(l10n, r.urgency)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.title, style: Theme.of(context).textTheme.bodyLarge),
                                Text(
                                  [
                                    if (r.vehicleLabel != null) r.vehicleLabel!,
                                    reminderDueText(
                                      context,
                                      l10n,
                                      dueDate: r.dueDate,
                                      daysLeft: r.daysLeft,
                                      dueOdometerKm: r.dueOdometerKm,
                                      kmLeft: r.kmLeft,
                                    ),
                                  ].where((s) => s.isNotEmpty).join('\n'),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
