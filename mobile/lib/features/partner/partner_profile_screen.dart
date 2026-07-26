import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/state/auth_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/status_badge.dart';
import 'partner_model.dart';
import 'partner_repository.dart';

class PartnerProfileScreen extends StatefulWidget {
  const PartnerProfileScreen({super.key});

  @override
  State<PartnerProfileScreen> createState() => _PartnerProfileScreenState();
}

class _PartnerProfileScreenState extends State<PartnerProfileScreen> {
  PartnerProfile? _profile;
  bool _loading = true;
  bool _saving = false;

  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final profile = await context.read<PartnerRepository>().fetchMyProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _businessNameController.text = profile.businessName;
        _phoneController.text = profile.contactPhone ?? '';
        _emailController.text = profile.contactEmail ?? '';
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<PartnerRepository>().updateMyProfile(
            businessName: _businessNameController.text.trim(),
            contactPhone: _phoneController.text.trim(),
            contactEmail: _emailController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Business profile updated.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save changes. Try again.')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _statusColorKey(String status) {
    switch (status) {
      case 'verified':
        return 'green';
      case 'rejected':
      case 'suspended':
        return 'red';
      default:
        return 'amber';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Profile')),
      body: GradientBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_profile != null)
                      Center(child: StatusBadge(status: _statusColorKey(_profile!.status), label: _profile!.status.toUpperCase())),
                    const SizedBox(height: 20),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Business details', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _businessNameController,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: const InputDecoration(labelText: 'Business name'),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: const InputDecoration(labelText: 'Contact phone'),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: const InputDecoration(labelText: 'Contact email'),
                          ),
                          const SizedBox(height: 18),
                          GradientButton(label: 'Save changes', loading: _saving, onPressed: _saving ? null : _save),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () => context.read<AuthState>().logout(),
                      icon: const Icon(Icons.logout, color: AppColors.statusRed),
                      label: const Text('Log out', style: TextStyle(color: AppColors.statusRed)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        side: const BorderSide(color: AppColors.glassBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }
}
