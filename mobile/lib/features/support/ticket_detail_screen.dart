import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/status_badge.dart';
import '../../l10n/generated/app_localizations.dart';
import 'support_model.dart';
import 'support_repository.dart';

class TicketDetailScreen extends StatefulWidget {
  const TicketDetailScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  late Future<SupportTicketDetail> _ticketFuture;
  final _replyController = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _ticketFuture = context.read<SupportRepository>().fetchTicket(widget.ticketId);
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context)!;
    final content = _replyController.text.trim();
    if (content.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await context.read<SupportRepository>().addMessage(widget.ticketId, content);
      _replyController.clear();
      if (mounted) setState(_reload);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.ticketDetailSendFailed)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.ticketDetailTitle)),
      body: GradientBackground(
        child: SafeArea(
          child: FutureBuilder<SupportTicketDetail>(
            future: _ticketFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return EmptyState(
                  icon: Icons.wifi_off,
                  title: l10n.ticketDetailCouldNotLoad,
                  message: l10n.ticketDetailCheckConnection,
                  actionLabel: l10n.commonRetry,
                  onAction: () => setState(_reload),
                );
              }
              final ticket = snapshot.data!;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(child: Text(ticket.subject, style: Theme.of(context).textTheme.titleLarge)),
                        StatusBadge(
                          status: ticket.status == 'resolved' || ticket.status == 'closed' ? 'green' : 'amber',
                          label: ticket.status.replaceAll('_', ' '),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: ticket.messages.map((m) {
                        final isUser = m.authorRole == 'user';
                        return Align(
                          alignment: isUser ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(14),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                            decoration: BoxDecoration(
                              gradient: isUser ? AppColors.goldGradient : null,
                              color: isUser ? null : AppColors.glassFillStrong,
                              border: isUser ? null : Border.all(color: AppColors.glassBorder),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(m.content, style: TextStyle(color: isUser ? AppColors.navyDeep : AppColors.textPrimary)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _replyController,
                              style: const TextStyle(color: AppColors.textPrimary),
                              decoration: InputDecoration(hintText: l10n.ticketDetailReplyHint, border: InputBorder.none, filled: false),
                              onSubmitted: (_) => _send(),
                            ),
                          ),
                          Container(
                            decoration: const BoxDecoration(gradient: AppColors.goldGradient, shape: BoxShape.circle),
                            child: IconButton(
                              onPressed: _sending ? null : _send,
                              icon: const Icon(Icons.arrow_upward, color: AppColors.navyDeep),
                            ),
                          ),
                        ],
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
