import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api/api_client.dart';
import '../../core/api/file_pickers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/status_badge.dart';
import '../../l10n/generated/app_localizations.dart';
import 'garage_repository.dart';
import 'vehicle_document_model.dart';
import 'vehicle_model.dart';

class VehicleProfileScreen extends StatefulWidget {
  const VehicleProfileScreen({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  State<VehicleProfileScreen> createState() => _VehicleProfileScreenState();
}

class _VehicleProfileScreenState extends State<VehicleProfileScreen> {
  late Future<HealthScoreBreakdown> _healthFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _healthFuture = context.read<GarageRepository>().fetchHealthScore(widget.vehicleId);
  }

  String _statusFor(int score) {
    if (score >= 80) return 'green';
    if (score >= 60) return 'amber';
    return 'red';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.vehicleProfileTitle)),
      body: GradientBackground(
        child: SafeArea(
          child: FutureBuilder<HealthScoreBreakdown>(
            future: _healthFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return EmptyState(
                  icon: Icons.wifi_off,
                  title: l10n.vehicleProfileCouldNotLoad,
                  message: l10n.homeCheckConnection,
                  actionLabel: l10n.commonRetry,
                  onAction: () => setState(_reload),
                );
              }
              final health = snapshot.data!;
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  GlassCard(
                    glow: true,
                    child: Column(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: const BoxDecoration(gradient: AppColors.goldGradient, shape: BoxShape.circle),
                          child: Center(
                            child: Text(
                              '${health.overall}',
                              style: const TextStyle(color: AppColors.navyDeep, fontWeight: FontWeight.w800, fontSize: 30),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        StatusBadge(
                          status: _statusFor(health.overall),
                          label: '${l10n.vehicleProfileHealthLabel}: ${health.overall}/100',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.vehicleProfileBreakdown, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 16),
                        ...health.categories.entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(flex: 2, child: Text(_labelFor(l10n, e.key), style: Theme.of(context).textTheme.bodyMedium)),
                                Expanded(
                                  flex: 5,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: e.value / 100,
                                      minHeight: 8,
                                      backgroundColor: AppColors.glassFill,
                                      valueColor: const AlwaysStoppedAnimation(AppColors.goldMid),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text('${e.value}', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (health.recommendations.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.vehicleProfileRecommendations, style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 14),
                          ...health.recommendations.map(
                            (r) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.info_outline, size: 18, color: AppColors.goldLight),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(r, style: Theme.of(context).textTheme.bodyMedium)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _PhotoCard(vehicleId: widget.vehicleId),
                  const SizedBox(height: 20),
                  _DocumentsCard(vehicleId: widget.vehicleId),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _labelFor(AppLocalizations l10n, String key) {
    switch (key) {
      case 'inspection':
        return l10n.vehicleProfileCategoryInspection;
      case 'maintenance':
        return l10n.vehicleProfileCategoryMaintenance;
      case 'documents':
        return l10n.vehicleProfileCategoryDocuments;
      case 'ageMileage':
        return l10n.vehicleProfileCategoryAgeMileage;
      default:
        return key;
    }
  }
}

/// The vehicle's own photo, with an add/replace action.
class _PhotoCard extends StatefulWidget {
  const _PhotoCard({required this.vehicleId});

  final String vehicleId;

  @override
  State<_PhotoCard> createState() => _PhotoCardState();
}

class _PhotoCardState extends State<_PhotoCard> {
  late Future<Vehicle> _vehicleFuture;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _vehicleFuture = context.read<GarageRepository>().fetchVehicle(widget.vehicleId);
  }

  Future<void> _upload() async {
    final l10n = AppLocalizations.of(context)!;
    final file = await pickImage(fromCamera: false);
    if (file == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      await context.read<GarageRepository>().uploadVehiclePhoto(vehicleId: widget.vehicleId, file: file);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.vehiclePhotoUploaded)));
      setState(_reload);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is DioException ? ApiClient.messageFrom(e) : l10n.vehiclePhotoUploadFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<Vehicle>(
      future: _vehicleFuture,
      builder: (context, snapshot) {
        final photoUrl = snapshot.data?.primaryPhotoUrl;
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (photoUrl != null && photoUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    photoUrl,
                    height: 170,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      height: 170,
                      child: Center(child: Icon(Icons.broken_image_outlined, color: AppColors.textSecondary)),
                    ),
                  ),
                ),
              if (photoUrl != null && photoUrl.isNotEmpty) const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _uploading ? null : _upload,
                icon: const Icon(Icons.photo_camera_outlined, size: 18, color: AppColors.goldLight),
                label: Text(
                  _uploading
                      ? l10n.documentsUploading
                      : (photoUrl != null && photoUrl.isNotEmpty
                          ? l10n.vehiclePhotoReplace
                          : l10n.vehiclePhotoAdd),
                ),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.glassBorder)),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Vehicle documents — upload, list, and open. Loads independently of the
/// health score so a document upload doesn't re-fetch the whole screen.
class _DocumentsCard extends StatefulWidget {
  const _DocumentsCard({required this.vehicleId});

  final String vehicleId;

  @override
  State<_DocumentsCard> createState() => _DocumentsCardState();
}

class _DocumentsCardState extends State<_DocumentsCard> {
  late Future<List<VehicleDocument>> _documentsFuture;
  bool _uploading = false;

  static const _types = [
    'registration',
    'insurance',
    'warranty',
    'ownership_transfer',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _documentsFuture = context.read<GarageRepository>().fetchDocuments(widget.vehicleId);
  }

  String _typeLabel(AppLocalizations l10n, String type) {
    switch (type) {
      case 'registration':
        return l10n.documentsTypeRegistration;
      case 'insurance':
        return l10n.documentsTypeInsurance;
      case 'warranty':
        return l10n.documentsTypeWarranty;
      case 'ownership_transfer':
        return l10n.documentsTypeOwnershipTransfer;
      default:
        return l10n.documentsTypeOther;
    }
  }

  Future<void> _add() async {
    final l10n = AppLocalizations.of(context)!;
    final type = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        backgroundColor: AppColors.navyMid,
        title: Text(l10n.documentsChooseType, style: const TextStyle(color: AppColors.textPrimary)),
        children: _types
            .map(
              (t) => SimpleDialogOption(
                onPressed: () => Navigator.of(dialogContext).pop(t),
                child: Text(_typeLabel(l10n, t), style: const TextStyle(color: AppColors.textPrimary)),
              ),
            )
            .toList(),
      ),
    );
    if (type == null || !mounted) return;

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

    final file = await pickDocument(fromCamera: fromCamera);
    if (file == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      await context.read<GarageRepository>().uploadDocument(
            vehicleId: widget.vehicleId,
            type: type,
            file: file,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.documentsUploaded)));
      setState(_reload);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is DioException ? ApiClient.messageFrom(e) : l10n.documentsUploadFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _open(VehicleDocument doc) async {
    final l10n = AppLocalizations.of(context)!;
    final opened = await launchUrl(Uri.parse(doc.viewUrl), mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.documentsCouldNotOpen)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.documentsTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          FutureBuilder<List<VehicleDocument>>(
            future: _documentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Text(l10n.documentsCouldNotLoad, style: Theme.of(context).textTheme.bodyMedium);
              }
              final docs = snapshot.data!;
              if (docs.isEmpty) {
                return Text(l10n.documentsNoneYet, style: Theme.of(context).textTheme.bodyMedium);
              }
              return Column(
                children: docs
                    .map(
                      (doc) => InkWell(
                        onTap: () => _open(doc),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.description_outlined, size: 18, color: AppColors.goldLight),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_typeLabel(l10n, doc.type), style: Theme.of(context).textTheme.bodyLarge),
                                    if (doc.expiryDate != null)
                                      Text(
                                        '${l10n.documentsExpires} ${doc.expiryDate!.toLocal().toString().split(' ').first}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                  ],
                                ),
                              ),
                              if (doc.verified)
                                const Icon(Icons.verified_outlined, size: 18, color: AppColors.statusGreen),
                              Icon(
                                Directionality.of(context) == TextDirection.rtl
                                    ? Icons.chevron_left
                                    : Icons.chevron_right,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _uploading ? null : _add,
            icon: const Icon(Icons.upload_file_outlined, size: 18, color: AppColors.goldLight),
            label: Text(_uploading ? l10n.documentsUploading : l10n.documentsAdd),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.glassBorder)),
          ),
        ],
      ),
    );
  }
}
