import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/gradient_button.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not book the inspection. Check the backend connection and try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(color: AppColors.textPrimary);
    return Scaffold(
      appBar: AppBar(title: const Text('Book Inspection')),
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
                      '300+ checkpoints covering engine, transmission, chassis, electrical, and more.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 10),
                    const Text('AED 349 (incl. VAT)', style: TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.w800, fontSize: 20)),
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
                      decoration: const InputDecoration(labelText: 'Make / Model / Year (e.g. 2019 Toyota Camry)'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _plateController,
                      style: textStyle,
                      decoration: const InputDecoration(labelText: 'Plate number'),
                    ),
                    const SizedBox(height: 14),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Preferred date', style: Theme.of(context).textTheme.bodyLarge),
                      subtitle: Text(
                        '${_scheduledAt.year}-${_scheduledAt.month.toString().padLeft(2, '0')}-${_scheduledAt.day.toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      trailing: const Icon(Icons.calendar_today_outlined, color: AppColors.goldLight),
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 20),
                    GradientButton(label: 'Book Inspection', loading: _submitting, onPressed: _submitting ? null : _submit),
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
