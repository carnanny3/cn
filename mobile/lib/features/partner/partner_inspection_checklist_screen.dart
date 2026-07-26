import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/gradient_button.dart';
import 'partner_repository.dart';

const _resultLabels = <String, String>{
  'pass': 'Pass',
  'minor_defect': 'Minor',
  'critical_defect': 'Critical',
  'not_applicable': 'N/A',
};

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
          const SnackBar(content: Text('Checklist submitted for QA review.')),
        );
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not submit the checklist. Check your connection and try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inspection Checklist')),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Record a result for every category. Add notes for anything flagged minor or critical.',
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
                          children: _resultLabels.entries.map((entry) {
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
                            decoration: const InputDecoration(hintText: 'Notes on the defect...'),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              Text('Road Test Notes (optional)', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              GlassCard(
                child: TextField(
                  controller: _roadTestNotesController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'How did the vehicle drive?', border: InputBorder.none),
                ),
              ),
              const SizedBox(height: 24),
              GradientButton(label: 'Submit for QA Review', onPressed: _submit, loading: _submitting),
            ],
          ),
        ),
      ),
    );
  }
}
