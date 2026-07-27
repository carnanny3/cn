import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/gradient_button.dart';
import '../../l10n/generated/app_localizations.dart';
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

  List<({String value, String label})> _emirateOptions(AppLocalizations l10n) => [
        (value: 'Dubai', label: l10n.garageAddVehicleEmirateDubai),
        (value: 'Abu Dhabi', label: l10n.garageAddVehicleEmirateAbuDhabi),
        (value: 'Sharjah', label: l10n.garageAddVehicleEmirateSharjah),
        (value: 'Ajman', label: l10n.garageAddVehicleEmirateAjman),
        (value: 'Fujairah', label: l10n.garageAddVehicleEmirateFujairah),
        (value: 'Ras Al Khaimah', label: l10n.garageAddVehicleEmirateRasAlKhaimah),
        (value: 'Umm Al Quwain', label: l10n.garageAddVehicleEmirateUmmAlQuwain),
      ];

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
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.garageAddVehicleError)),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final emirateOptions = _emirateOptions(l10n);
    const textStyle = TextStyle(color: AppColors.textPrimary);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.garageAddVehicleTitle)),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(controller: _makeController, style: textStyle, decoration: InputDecoration(labelText: l10n.garageAddVehicleMakeLabel)),
                    const SizedBox(height: 14),
                    TextField(controller: _modelController, style: textStyle, decoration: InputDecoration(labelText: l10n.garageAddVehicleModelLabel)),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _yearController,
                      keyboardType: TextInputType.number,
                      style: textStyle,
                      decoration: InputDecoration(labelText: l10n.garageAddVehicleYearLabel),
                    ),
                    const SizedBox(height: 14),
                    TextField(controller: _plateController, style: textStyle, decoration: InputDecoration(labelText: l10n.garageAddVehiclePlateLabel)),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _emirate,
                      style: textStyle,
                      dropdownColor: AppColors.navyMid,
                      decoration: InputDecoration(labelText: l10n.garageAddVehicleEmirateLabel),
                      items: emirateOptions.map((e) => DropdownMenuItem(value: e.value, child: Text(e.label))).toList(),
                      onChanged: (v) => setState(() => _emirate = v ?? _emirate),
                    ),
                    const SizedBox(height: 20),
                    GradientButton(label: l10n.garageAddVehicleSave, loading: _submitting, onPressed: _submitting ? null : _submit),
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
