import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../garage/garage_repository.dart';
import 'ai_message_model.dart';
import 'ai_repository.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<AiMessage> _messages = [];
  bool _sending = false;
  String? _primaryVehicleId;

  static const _suggestedPrompts = [
    'When is my next service due?',
    'Is my insurance active?',
    'Explain my last inspection report',
  ];

  @override
  void initState() {
    super.initState();
    context.read<GarageRepository>().fetchVehicles().then((vehicles) {
      if (mounted && vehicles.isNotEmpty) {
        setState(() => _primaryVehicleId = vehicles.first.id);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? text]) async {
    final content = (text ?? _controller.text).trim();
    if (content.isEmpty || _sending) return;

    setState(() {
      _messages.add(AiMessage(role: 'user', content: content));
      _sending = true;
      _controller.clear();
    });

    final reply = await context.read<AiRepository>().sendMessage(content, vehicleId: _primaryVehicleId);

    setState(() {
      _messages.add(reply);
      _sending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('AI Assistant')),
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 56),
              Expanded(
                child: _messages.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(gradient: AppColors.goldGradient, shape: BoxShape.circle),
                              child: const Icon(Icons.smart_toy_outlined, color: AppColors.navyDeep),
                            ),
                            const SizedBox(height: 16),
                            Text('Ask me anything about your car', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _suggestedPrompts
                                  .map((p) => _SuggestedPrompt(label: p, onTap: () => _send(p)))
                                  .toList(),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final m = _messages[index];
                          final isUser = m.role == 'user';
                          return Align(
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
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
                              child: Text(
                                m.content,
                                style: TextStyle(color: isUser ? AppColors.navyDeep : AppColors.textPrimary),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (_sending) const LinearProgressIndicator(minHeight: 2, color: AppColors.goldMid),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            hintText: 'Ask about your car...',
                            border: InputBorder.none,
                            filled: false,
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      Container(
                        decoration: const BoxDecoration(gradient: AppColors.goldGradient, shape: BoxShape.circle),
                        child: IconButton(
                          onPressed: _sending ? null : () => _send(),
                          icon: const Icon(Icons.arrow_upward, color: AppColors.navyDeep),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestedPrompt extends StatelessWidget {
  const _SuggestedPrompt({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
