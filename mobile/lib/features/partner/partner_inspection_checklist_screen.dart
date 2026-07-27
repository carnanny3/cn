import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/gradient_button.dart';
import '../../l10n/generated/app_localizations.dart';
import 'partner_repository.dart';

class PartnerInspectionChecklistScreen extends StatefulWidget {
  const PartnerInspectionChecklistScreen({super.key, required this.inspectionId});

  final String inspectionId;

  @override
  State<PartnerInspectionChecklistScreen> createState() => _PartnerInspectionChecklistScreenState();
}

class _PartnerInspectionChecklistScreenState extends State<PartnerInspectionChecklistScreen> {
  final Map<String, String> _results = {
    for (final c in PartnerRepository.checkpointCategories) c: 'pass',
  };
  final Map<String, TextEditingController> _notes = {
    for (final c in PartnerRepository.checkpointCategories) c: TextEditingController(),
  };
  final _roadTestNotesController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    for (final c in _notes.values) {
      c.dispose();
    }
    _roadTestNotesController.dispose();
    super.dispose();
  }

  String _labelFor(String category) => category
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _submitting = true);
    try {
      final checkpoints = PartnerRepository.checkpointCategories
          .map((category) => {
                'category': category,
                'checkpointName': _labelFor(category),
                'result': _results[category]!,
                if (_notes[category]!.text.trim().isNotEmpty) 'notes': _notes[category]!.text.trim(),
              })
          .toList();

      await context.read<PartnerRepository>().submitCheckpoints(
            widget.inspectionId,
            checkpoints,
            roadTestNotes: _roadTestNotesController.text.trim().isEmpty ? null : _roadTestNotesController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.partnerChecklistSubmitted)),
        );
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.partnerChecklistSubmitError)),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final resultLabels = <String, String>{
      'pass': l10n.partnerChecklistResultPass,
      'minor_defect': l10n.partnerChecklistResultMinor,
      'critical_defect': l10n.partnerChecklistResultCritical,
      'not_applicable': l10n.partnerChecklistResultNotApplicable,
    };
    return Scaffold(
      appBar: AppBar(title: Text(l10n.partnerChecklistTitle)),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l10n.partnerChecklistInstructions,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ...PartnerRepository.checkpointCategories.map((category) {
                final result = _results[category]!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_labelFor(category), style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: resultLabels.entries.map((entry) {
                            final selected = result == entry.key;
                            return ChoiceChip(
                              label: Text(entry.value),
                              selected: selected,
                              onSelected: (_) => setState(() => _results[category] = entry.key),
                              selectedColor: AppColors.goldMid,
                              backgroundColor: AppColors.glassFill,
                              labelStyle: TextStyle(color: selected ? AppColors.navyDeep : AppColors.textPrimary),
                            );
                          }).toList(),
                        ),
                        if (result != 'pass' && result != 'not_applicable') ...[
                          const SizedBox(height: 10),
                          TextField(
                            controller: _notes[category],
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: InputDecoration(hintText: l10n.partnerChecklistDefectNotesHint),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              Text(l10n.partnerChecklistRoadTestNotesLabel, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              GlassCard(
                child: TextField(
                  controller: _roadTestNotesController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  maxLines: 3,
                  decoration: InputDecoration(hintText: l10n.partnerChecklistRoadTestHint, border: InputBorder.none),
                ),
              ),
              const SizedBox(height: 24),
              GradientButton(label: l10n.partnerChecklistSubmitButton, onPressed: _submit, loading: _submitting),
            ],
          ),
        ),
      ),
    );
  }
}
