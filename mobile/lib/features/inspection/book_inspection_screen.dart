import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/gradient_button.dart';
import '../../l10n/generated/app_localizations.dart';
import 'inspection_repository.dart';

class BookInspectionScreen extends StatefulWidget {
  const BookInspectionScreen({super.key});

  @override
  State<BookInspectionScreen> createState() => _BookInspectionScreenState();
}

class _BookInspectionScreenState extends State<BookInspectionScreen> {
  final _plateController = TextEditingController();
  final _makeModelYearController = TextEditingController();
  bool _submitting = false;
  DateTime _scheduledAt = DateTime.now().add(const Duration(days: 1));

  @override
  void dispose() {
    _plateController.dispose();
    _makeModelYearController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (date != null) setState(() => _scheduledAt = date);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final result = await context.read<InspectionRepository>().bookInspection(
            plateNumber: _plateController.text.trim().isEmpty ? null : _plateController.text.trim(),
            makeModelYear: _makeModelYearController.text.trim().isEmpty ? null : _makeModelYearController.text.trim(),
            lat: 25.2048,
            lng: 55.2708,
            scheduledAt: _scheduledAt,
          );
      if (mounted) {
        context.push('/inspection/${result['id']}/report');
      }
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.inspectionBookError)),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const textStyle = TextStyle(color: AppColors.textPrimary);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.inspectionBookTitle)),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              GlassCard(
                glow: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.inspectionBookCheckpointsDescription,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 10),
                    Text(l10n.inspectionBookPriceLabel, style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.w800, fontSize: 20)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _makeModelYearController,
                      style: textStyle,
                      decoration: InputDecoration(labelText: l10n.inspectionBookMakeModelYearLabel),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _plateController,
                      style: textStyle,
                      decoration: InputDecoration(labelText: l10n.inspectionBookPlateLabel),
                    ),
                    const SizedBox(height: 14),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.inspectionBookPreferredDate, style: Theme.of(context).textTheme.bodyLarge),
                      subtitle: Text(
                        '${_scheduledAt.year}-${_scheduledAt.month.toString().padLeft(2, '0')}-${_scheduledAt.day.toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      trailing: const Icon(Icons.calendar_today_outlined, color: AppColors.goldLight),
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 20),
                    GradientButton(label: l10n.inspectionBookSubmit, loading: _submitting, onPressed: _submitting ? null : _submit),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
