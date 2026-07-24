import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/gradient_button.dart';
import 'garage_repository.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _plateController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController(text: '${DateTime.now().year}');
  String _emirate = 'Dubai';
  bool _submitting = false;

  static const _emirates = ['Dubai', 'Abu Dhabi', 'Sharjah', 'Ajman', 'Fujairah', 'Ras Al Khaimah', 'Umm Al Quwain'];

  @override
  void dispose() {
    _plateController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await context.read<GarageRepository>().addVehicle(
            plateNumber: _plateController.text.trim(),
            emirateRegistered: _emirate,
            make: _makeController.text.trim(),
            model: _modelController.text.trim(),
            year: int.tryParse(_yearController.text.trim()) ?? DateTime.now().year,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not add vehicle. Check the backend connection and try again.')),
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
      appBar: AppBar(title: const Text('Add Vehicle')),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(controller: _makeController, style: textStyle, decoration: const InputDecoration(labelText: 'Make (e.g. Toyota)')),
                    const SizedBox(height: 14),
                    TextField(controller: _modelController, style: textStyle, decoration: const InputDecoration(labelText: 'Model (e.g. Camry)')),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _yearController,
                      keyboardType: TextInputType.number,
                      style: textStyle,
                      decoration: const InputDecoration(labelText: 'Year'),
                    ),
                    const SizedBox(height: 14),
                    TextField(controller: _plateController, style: textStyle, decoration: const InputDecoration(labelText: 'Plate number')),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _emirate,
                      style: textStyle,
                      dropdownColor: AppColors.navyMid,
                      decoration: const InputDecoration(labelText: 'Emirate'),
                      items: _emirates.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _emirate = v ?? _emirate),
                    ),
                    const SizedBox(height: 20),
                    GradientButton(label: 'Save Vehicle', loading: _submitting, onPressed: _submitting ? null : _submit),
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
