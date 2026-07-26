import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/gradient_button.dart';
import '../services/services_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import 'partner_model.dart';
import 'partner_repository.dart';

class PartnerCatalogScreen extends StatefulWidget {
  const PartnerCatalogScreen({super.key});

  @override
  State<PartnerCatalogScreen> createState() => _PartnerCatalogScreenState();
}

class _PartnerCatalogScreenState extends State<PartnerCatalogScreen> {
  late Future<PartnerProfile> _profileFuture;
  String? _busyServiceId;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _profileFuture = context.read<PartnerRepository>().fetchMyProfile();
  }

  Future<void> _toggleActive(PartnerServiceItem service) async {
    setState(() => _busyServiceId = service.id);
    try {
      await context.read<PartnerRepository>().updateService(service.id, active: !service.active);
      if (mounted) setState(_reload);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not update this service.')));
      }
    } finally {
      if (mounted) setState(() => _busyServiceId = null);
    }
  }

  Future<void> _showAddServiceSheet() async {
    final l10n = AppLocalizations.of(context)!;
    String category = ServicesRepository.categoryKeys.first;
    final priceController = TextEditingController();
    final durationController = TextEditingController();
    bool submitting = false;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: GlassCard(
                strong: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add a service', style: Theme.of(sheetContext).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      dropdownColor: AppColors.navyMid,
                      style: const TextStyle(color: AppColors.textPrimary),
                      items: ServicesRepository.categoryKeys
                          .map((key) => DropdownMenuItem(value: key, child: Text(ServicesRepository.categoryLabel(l10n, key))))
                          .toList(),
                      onChanged: (value) => setSheetState(() => category = value ?? category),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(labelText: 'Price (AED)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: durationController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(labelText: 'Duration estimate (minutes, optional)'),
                    ),
                    const SizedBox(height: 20),
                    GradientButton(
                      label: 'Add Service',
                      loading: submitting,
                      onPressed: () async {
                        final price = double.tryParse(priceController.text.trim());
                        if (price == null) return;
                        setSheetState(() => submitting = true);
                        try {
                          await context.read<PartnerRepository>().addService(
                                serviceCategory: category,
                                price: price,
                                durationEstimateMinutes: int.tryParse(durationController.text.trim()),
                              );
                          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                          if (mounted) setState(_reload);
                        } catch (_) {
                          setSheetState(() => submitting = false);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('My Catalog'),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: _showAddServiceSheet)],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: FutureBuilder<PartnerProfile>(
            future: _profileFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return EmptyState(
                  icon: Icons.wifi_off,
                  title: 'Could not load your catalog',
                  message: 'Check your connection and try again.',
                  actionLabel: 'Retry',
                  onAction: () => setState(_reload),
                );
              }
              final services = snapshot.data!.services;
              if (services.isEmpty) {
                return EmptyState(
                  icon: Icons.build_outlined,
                  title: 'No services listed yet',
                  message: 'Add the services you offer so customers can find and book you.',
                  actionLabel: 'Add Service',
                  onAction: _showAddServiceSheet,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 96, 16, 32),
                itemCount: services.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final service = services[index];
                  final label = ServicesRepository.categoryLabel(AppLocalizations.of(context)!, service.serviceCategory);
                  final busy = _busyServiceId == service.id;
                  return GlassCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(label, style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 4),
                              Text('AED ${service.price.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        if (busy)
                          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        else
                          Switch(
                            value: service.active,
                            activeThumbColor: AppColors.goldMid,
                            onChanged: (_) => _toggleActive(service),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
