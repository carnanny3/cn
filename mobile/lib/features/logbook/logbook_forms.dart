import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api/api_client.dart';
import '../../core/api/file_pickers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gradient_button.dart';
import '../../l10n/generated/app_localizations.dart';
import 'logbook_format.dart';
import 'logbook_models.dart';
import 'logbook_repository.dart';

/// Opens [child] as a keyboard-aware bottom sheet. Resolves to true when the
/// sheet saved or deleted something, so the caller knows to reload.
Future<bool> _openSheet(BuildContext context, Widget child) async {
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.navyMid,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
      child: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 20), child: child)),
    ),
  );
  return changed ?? false;
}

Future<bool> showRecordSheet(BuildContext context, {required String vehicleId, required int currentOdometerKm, LogRecord? record}) =>
    _openSheet(context, _RecordForm(vehicleId: vehicleId, currentOdometerKm: currentOdometerKm, record: record));

Future<bool> showFuelSheet(BuildContext context, {required String vehicleId, required int currentOdometerKm, FuelEntry? entry}) =>
    _openSheet(context, _FuelForm(vehicleId: vehicleId, currentOdometerKm: currentOdometerKm, entry: entry));

Future<bool> showReminderSheet(BuildContext context, {required String vehicleId, Reminder? reminder}) =>
    _openSheet(context, _ReminderForm(vehicleId: vehicleId, reminder: reminder));

Future<bool> confirmDelete(BuildContext context, String message) async {
  final l10n = AppLocalizations.of(context)!;
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.navyMid,
      content: Text(message, style: const TextStyle(color: AppColors.textPrimary)),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.commonCancel)),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.commonDelete, style: const TextStyle(color: AppColors.statusRed)),
        ),
      ],
    ),
  );
  return ok ?? false;
}

void _showError(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context)!;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error is DioException ? ApiClient.messageFrom(error) : l10n.logbookSaveFailed)),
  );
}

// ---------- Shared field widgets ----------

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title, this.onDelete});

  final String title;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: AppColors.glassBorder, borderRadius: BorderRadius.circular(2)),
        ),
        Row(
          children: [
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
            if (onDelete != null)
              IconButton(
                tooltip: AppLocalizations.of(context)!.commonDelete,
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: AppColors.statusRed),
              ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onChanged, this.onClear});

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: DateTime(1980),
          lastDate: DateTime(now.year + 20),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: value != null && onClear != null
              ? IconButton(tooltip: l10n.reminderClear, icon: const Icon(Icons.close, size: 18), onPressed: onClear)
              : const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(value == null ? '' : formatDay(context, value!), style: const TextStyle(color: AppColors.textPrimary)),
      ),
    );
  }
}

TextFormField _numberField(TextEditingController controller, String label, {bool decimal = false, bool required = false}) {
  return TextFormField(
    controller: controller,
    keyboardType: TextInputType.numberWithOptions(decimal: decimal),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(decimal ? r'[0-9.]' : r'[0-9]'))],
    decoration: InputDecoration(labelText: label),
    validator: (v) {
      final text = v?.trim() ?? '';
      if (text.isEmpty) return required ? '' : null;
      return (decimal ? double.tryParse(text) : int.tryParse(text)) == null ? '' : null;
    },
  );
}

String _numText(num? n) {
  if (n == null) return '';
  if (n is int || n == n.roundToDouble()) return n.round().toString();
  return n.toString();
}

// ---------- Record ----------

class _RecordForm extends StatefulWidget {
  const _RecordForm({required this.vehicleId, required this.currentOdometerKm, this.record});

  final String vehicleId;
  final int currentOdometerKm;
  final LogRecord? record;

  @override
  State<_RecordForm> createState() => _RecordFormState();
}

class _RecordFormState extends State<_RecordForm> {
  final _formKey = GlobalKey<FormState>();
  late String _type = widget.record?.type ?? 'service';
  late DateTime _date = widget.record?.date ?? DateTime.now();
  late final _title = TextEditingController(text: widget.record?.title ?? '');
  late final _odometer = TextEditingController(
    text: _numText(widget.record?.odometerKm ?? (widget.record == null && widget.currentOdometerKm > 0 ? widget.currentOdometerKm : null)),
  );
  late final _cost = TextEditingController(text: _numText(widget.record?.cost));
  late final _notes = TextEditingController(text: widget.record?.notes ?? '');
  late List<RecordPhoto> _photos = [...?widget.record?.photos];
  bool _saving = false;
  bool _uploading = false;

  @override
  void dispose() {
    _title.dispose();
    _odometer.dispose();
    _cost.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<LogbookRepository>().saveRecord(
            widget.vehicleId,
            {
              'type': _type,
              'date': formatApiDay(_date),
              'title': _title.text.trim(),
              if (_odometer.text.trim().isNotEmpty) 'odometerKm': int.parse(_odometer.text.trim()),
              'cost': double.tryParse(_cost.text.trim()) ?? 0,
              'notes': _notes.text.trim(),
            },
            recordId: widget.record?.id,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        _showError(context, e);
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    if (!await confirmDelete(context, l10n.recordDeleteConfirm) || !mounted) return;
    try {
      await context.read<LogbookRepository>().deleteRecord(widget.vehicleId, widget.record!.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) _showError(context, e);
    }
  }

  Future<void> _addPhoto() async {
    final l10n = AppLocalizations.of(context)!;
    final fromCamera = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.navyMid,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.goldLight),
              title: Text(l10n.documentsTakePhoto, style: const TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.of(sheetContext).pop(true),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.goldLight),
              title: Text(l10n.documentsChooseExisting, style: const TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.of(sheetContext).pop(false),
            ),
          ],
        ),
      ),
    );
    if (fromCamera == null || !mounted) return;
    final file = await pickImage(fromCamera: fromCamera);
    if (file == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      final photo = await context.read<LogbookRepository>().uploadRecordPhoto(widget.vehicleId, widget.record!.id, file);
      if (!mounted) return;
      setState(() => _photos = [..._photos, photo]);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.recordPhotoUploaded)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is DioException ? ApiClient.messageFrom(e) : l10n.recordPhotoUploadFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _deletePhoto(RecordPhoto photo) async {
    final l10n = AppLocalizations.of(context)!;
    if (!await confirmDelete(context, '${l10n.commonDelete}?') || !mounted) return;
    try {
      await context.read<LogbookRepository>().deleteRecordPhoto(widget.vehicleId, widget.record!.id, photo.id);
      if (mounted) {
        setState(() => _photos = _photos.where((p) => p.id != photo.id).toList());
      }
    } catch (e) {
      if (mounted) _showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final editing = widget.record != null;
    return Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetHeader(title: editing ? l10n.recordsEdit : l10n.recordsAdd, onDelete: editing ? _delete : null),
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                for (final t in const ['service', 'repair', 'upgrade', 'fee'])
                  ButtonSegment(value: t, icon: Icon(categoryIcon(t), size: 18), tooltip: categoryLabel(l10n, t)),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 6),
            Text(categoryLabel(l10n, _type), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            TextFormField(
              controller: _title,
              maxLength: 200,
              decoration: InputDecoration(labelText: l10n.recordTitle, counterText: ''),
              validator: (v) => (v ?? '').trim().isEmpty ? '' : null,
            ),
            const SizedBox(height: 12),
            _DateField(label: l10n.recordDate, value: _date, onChanged: (d) => setState(() => _date = d)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _numberField(_odometer, l10n.recordOdometer)),
                const SizedBox(width: 12),
                Expanded(child: _numberField(_cost, l10n.recordCost, decimal: true)),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _notes, maxLines: 3, decoration: InputDecoration(labelText: l10n.recordNotes)),
            const SizedBox(height: 18),
            Text(l10n.recordPhotos, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (!editing)
              Text(l10n.recordSaveFirstForPhotos, style: Theme.of(context).textTheme.bodySmall)
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in _photos) _PhotoThumb(photo: p, onDelete: () => _deletePhoto(p)),
                  if (_photos.length < 6)
                    InkWell(
                      onTap: _uploading ? null : _addPhoto,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: _uploading
                            ? const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(strokeWidth: 2))
                            : Tooltip(
                                message: l10n.recordAddPhoto,
                                child: const Icon(Icons.add_a_photo_outlined, color: AppColors.goldLight),
                              ),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 20),
            GradientButton(label: l10n.commonSave, loading: _saving, onPressed: _saving ? null : _save),
          ],
        ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.photo, required this.onDelete});

  final RecordPhoto photo;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => launchUrl(Uri.parse(photo.viewUrl), mode: LaunchMode.externalApplication),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              photo.viewUrl,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 72,
                height: 72,
                color: AppColors.glassFill,
                child: const Icon(Icons.receipt_long_outlined, color: AppColors.textSecondary),
              ),
            ),
          ),
        ),
        PositionedDirectional(
          top: -8,
          end: -8,
          child: IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: AppLocalizations.of(context)!.commonDelete,
            onPressed: onDelete,
            icon: const CircleAvatar(
              radius: 11,
              backgroundColor: AppColors.navyDeep,
              child: Icon(Icons.close, size: 14, color: AppColors.textPrimary),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------- Fuel ----------

class _FuelForm extends StatefulWidget {
  const _FuelForm({required this.vehicleId, required this.currentOdometerKm, this.entry});

  final String vehicleId;
  final int currentOdometerKm;
  final FuelEntry? entry;

  @override
  State<_FuelForm> createState() => _FuelFormState();
}

class _FuelFormState extends State<_FuelForm> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _date = widget.entry?.date ?? DateTime.now();
  late final _odometer = TextEditingController(
    text: _numText(widget.entry?.odometerKm ?? (widget.currentOdometerKm > 0 ? widget.currentOdometerKm : null)),
  );
  late final _liters = TextEditingController(text: _numText(widget.entry?.liters));
  late final _cost = TextEditingController(text: _numText(widget.entry?.cost));
  late final _notes = TextEditingController(text: widget.entry?.notes ?? '');
  late bool _fullTank = widget.entry?.fullTank ?? true;
  late bool _missedPrevious = widget.entry?.missedPrevious ?? false;
  bool _saving = false;

  @override
  void dispose() {
    _odometer.dispose();
    _liters.dispose();
    _cost.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<LogbookRepository>().saveFuel(
            widget.vehicleId,
            {
              'date': formatApiDay(_date),
              'odometerKm': int.parse(_odometer.text.trim()),
              'liters': double.parse(_liters.text.trim()),
              'cost': double.tryParse(_cost.text.trim()) ?? 0,
              'fullTank': _fullTank,
              'missedPrevious': _missedPrevious,
              'notes': _notes.text.trim(),
            },
            entryId: widget.entry?.id,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        _showError(context, e);
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    if (!await confirmDelete(context, l10n.fuelDeleteConfirm) || !mounted) return;
    try {
      await context.read<LogbookRepository>().deleteFuel(widget.vehicleId, widget.entry!.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) _showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetHeader(title: widget.entry == null ? l10n.fuelAdd : l10n.fuelEdit, onDelete: widget.entry == null ? null : _delete),
          _DateField(label: l10n.recordDate, value: _date, onChanged: (d) => setState(() => _date = d)),
          const SizedBox(height: 12),
          _numberField(_odometer, l10n.recordOdometer, required: true),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _numberField(_liters, l10n.fuelLiters, decimal: true, required: true)),
              const SizedBox(width: 12),
              Expanded(child: _numberField(_cost, l10n.fuelTotalCost, decimal: true)),
            ],
          ),
          const SizedBox(height: 6),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _fullTank,
            onChanged: (v) => setState(() => _fullTank = v),
            title: Text(l10n.fuelFullTank, style: const TextStyle(color: AppColors.textPrimary)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _missedPrevious,
            onChanged: (v) => setState(() => _missedPrevious = v),
            title: Text(l10n.fuelMissedPrevious, style: const TextStyle(color: AppColors.textPrimary)),
          ),
          TextFormField(controller: _notes, maxLines: 2, decoration: InputDecoration(labelText: l10n.recordNotes)),
          const SizedBox(height: 20),
          GradientButton(label: l10n.commonSave, loading: _saving, onPressed: _saving ? null : _save),
        ],
      ),
    );
  }
}

// ---------- Reminder ----------

class _ReminderForm extends StatefulWidget {
  const _ReminderForm({required this.vehicleId, this.reminder});

  final String vehicleId;
  final Reminder? reminder;

  @override
  State<_ReminderForm> createState() => _ReminderFormState();
}

class _ReminderFormState extends State<_ReminderForm> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.reminder?.title ?? '');
  late DateTime? _dueDate = widget.reminder?.dueDate;
  late final _dueOdometer = TextEditingController(text: _numText(widget.reminder?.dueOdometerKm));
  late final _repeatMonths = TextEditingController(text: _numText(widget.reminder?.repeatMonths));
  late final _repeatKm = TextEditingController(text: _numText(widget.reminder?.repeatKm));
  late final _notes = TextEditingController(text: widget.reminder?.notes ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _dueOdometer.dispose();
    _repeatMonths.dispose();
    _repeatKm.dispose();
    _notes.dispose();
    super.dispose();
  }

  int? _intOrNull(TextEditingController c) => int.tryParse(c.text.trim());

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null && _intOrNull(_dueOdometer) == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.reminderNeedsTarget)));
      return;
    }
    setState(() => _saving = true);
    try {
      // Explicit nulls clear a target that was removed while editing.
      await context.read<LogbookRepository>().saveReminder(
            widget.vehicleId,
            {
              'title': _title.text.trim(),
              'dueDate': _dueDate == null ? null : formatApiDay(_dueDate!),
              'dueOdometerKm': _intOrNull(_dueOdometer),
              'repeatMonths': _intOrNull(_repeatMonths),
              'repeatKm': _intOrNull(_repeatKm),
              'notes': _notes.text.trim(),
            },
            reminderId: widget.reminder?.id,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        _showError(context, e);
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    if (!await confirmDelete(context, l10n.reminderDeleteConfirm) || !mounted) return;
    try {
      await context.read<LogbookRepository>().deleteReminder(widget.vehicleId, widget.reminder!.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) _showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetHeader(
            title: widget.reminder == null ? l10n.remindersAdd : l10n.remindersEdit,
            onDelete: widget.reminder == null ? null : _delete,
          ),
          TextFormField(
            controller: _title,
            maxLength: 200,
            decoration: InputDecoration(labelText: l10n.reminderTitle, counterText: ''),
            validator: (v) => (v ?? '').trim().isEmpty ? '' : null,
          ),
          const SizedBox(height: 12),
          _DateField(
            label: l10n.reminderDueDate,
            value: _dueDate,
            onChanged: (d) => setState(() => _dueDate = d),
            onClear: () => setState(() => _dueDate = null),
          ),
          const SizedBox(height: 12),
          _numberField(_dueOdometer, l10n.reminderDueOdometer),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _numberField(_repeatMonths, l10n.reminderRepeatMonths)),
              const SizedBox(width: 12),
              Expanded(child: _numberField(_repeatKm, l10n.reminderRepeatKm)),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(controller: _notes, maxLines: 2, decoration: InputDecoration(labelText: l10n.recordNotes)),
          const SizedBox(height: 20),
          GradientButton(label: l10n.commonSave, loading: _saving, onPressed: _saving ? null : _save),
        ],
      ),
    );
  }
}
