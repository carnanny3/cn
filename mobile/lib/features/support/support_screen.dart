import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/status_badge.dart';
import '../../l10n/generated/app_localizations.dart';
import 'support_model.dart';
import 'support_repository.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  late Future<List<SupportTicketSummary>> _ticketsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _ticketsFuture = context.read<SupportRepository>().fetchMyTickets();
  }

  String _statusColorKey(String status) {
    if (status == 'resolved' || status == 'closed') return 'green';
    if (status == 'in_progress') return 'amber';
    return 'amber';
  }

  Future<void> _showNewTicketSheet() async {
    final l10n = AppLocalizations.of(context)!;
    String category = SupportRepository.categories.keys.first;
    final subjectController = TextEditingController();
    final messageController = TextEditingController();
    bool submitting = false;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom, left: 16, right: 16, top: 16),
              child: GlassCard(
                strong: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.supportContactSupport, style: Theme.of(sheetContext).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      dropdownColor: AppColors.navyMid,
                      style: const TextStyle(color: AppColors.textPrimary),
                      items: SupportRepository.categories.entries
                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (value) => setSheetState(() => category = value ?? category),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: subjectController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(labelText: l10n.supportSubjectLabel),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: messageController,
                      maxLines: 4,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(labelText: l10n.supportHowCanWeHelp),
                    ),
                    const SizedBox(height: 20),
                    GradientButton(
                      label: l10n.supportSubmitTicket,
                      loading: submitting,
                      onPressed: () async {
                        if (subjectController.text.trim().isEmpty || messageController.text.trim().isEmpty) return;
                        setSheetState(() => submitting = true);
                        try {
                          await context.read<SupportRepository>().createTicket(
                                category: category,
                                subject: subjectController.text.trim(),
                                message: messageController.text.trim(),
                              );
                          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                          if (mounted) setState(_reload);
                        } catch (_) {
                          setSheetState(() => submitting = false);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.supportTitle),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: _showNewTicketSheet)],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: FutureBuilder<List<SupportTicketSummary>>(
            future: _ticketsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return EmptyState(
                  icon: Icons.wifi_off,
                  title: l10n.supportCouldNotLoadTickets,
                  message: l10n.supportCheckConnection,
                  actionLabel: l10n.commonRetry,
                  onAction: () => setState(_reload),
                );
              }
              final tickets = snapshot.data!;
              if (tickets.isEmpty) {
                return EmptyState(
                  icon: Icons.help_outline,
                  title: l10n.supportNoTicketsYet,
                  message: l10n.supportNeedHelpMessage,
                  actionLabel: l10n.supportSubmitTicket,
                  onAction: _showNewTicketSheet,
                );
              }
              return RefreshIndicator(
                onRefresh: () async => setState(_reload),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 96, 16, 32),
                  itemCount: tickets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final ticket = tickets[index];
                    return GlassCard(
                      onTap: () => context.push('/support/${ticket.id}').then((_) => setState(_reload)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ticket.subject, style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 4),
                                Text(SupportRepository.categories[ticket.category] ?? ticket.category, style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                          StatusBadge(status: _statusColorKey(ticket.status), label: ticket.status.replaceAll('_', ' ')),
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
