import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/state/auth_state.dart';
import '../../core/state/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/gradient_button.dart';
import '../../l10n/generated/app_localizations.dart';
import 'user_model.dart';
import 'user_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _profile;
  bool _loading = true;
  bool _savingProfile = false;
  bool _savingPassword = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final profile = await context.read<UserRepository>().fetchMe();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _nameController.text = profile.fullName;
        _emailController.text = profile.email;
        _phoneController.text = profile.phoneNumber ?? '';
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _savingProfile = true);
    try {
      final updated = await context.read<UserRepository>().updateMe(
            fullName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
          );
      if (!mounted) return;
      setState(() => _profile = updated);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.profileUpdated)));
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.messageFrom(e))));
      }
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    final l10n = AppLocalizations.of(context)!;
    if (_newPasswordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profilePasswordTooShort)),
      );
      return;
    }
    setState(() => _savingPassword = true);
    try {
      await context.read<UserRepository>().changePassword(
            _currentPasswordController.text,
            _newPasswordController.text,
          );
      if (!mounted) return;
      _currentPasswordController.clear();
      _newPasswordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.profilePasswordUpdated)));
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.messageFrom(e))));
      }
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  Future<void> _pickLanguage() async {
    final l10n = AppLocalizations.of(context)!;
    final localeController = context.read<LocaleController>();
    final selected = await showDialog<Locale>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        backgroundColor: AppColors.navyMid,
        title: Text(l10n.profileChooseLanguage, style: const TextStyle(color: AppColors.textPrimary)),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(dialogContext).pop(const Locale('en')),
            child: Text(l10n.profileLanguageEnglish, style: const TextStyle(color: AppColors.textPrimary)),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(dialogContext).pop(const Locale('ar')),
            child: Text(l10n.profileLanguageArabic, style: const TextStyle(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
    if (selected == null) return;
    await localeController.setLocale(selected);
    if (!mounted) return;
    try {
      await context.read<UserRepository>().updateMe(preferredLanguage: selected.languageCode);
    } catch (_) {
      // Local UI language already switched; syncing the preference to the
      // server is best-effort and shouldn't block the user.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: GradientBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Center(
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: const BoxDecoration(gradient: AppColors.goldGradient, shape: BoxShape.circle),
                        child: const Icon(Icons.person_outline, size: 36, color: AppColors.navyDeep),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(_profile?.fullName ?? '', style: Theme.of(context).textTheme.titleLarge),
                    ),
                    const SizedBox(height: 24),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(l10n.profileAccountDetails, style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _nameController,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: InputDecoration(labelText: l10n.profileFullName),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: InputDecoration(labelText: l10n.profileEmail),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: InputDecoration(labelText: l10n.profilePhoneNumber),
                          ),
                          const SizedBox(height: 18),
                          GradientButton(
                            label: l10n.profileSaveChanges,
                            loading: _savingProfile,
                            onPressed: _savingProfile ? null : _saveProfile,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(l10n.profileChangePassword, style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _currentPasswordController,
                            obscureText: true,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: InputDecoration(labelText: l10n.profileCurrentPassword),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _newPasswordController,
                            obscureText: true,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: InputDecoration(labelText: l10n.profileNewPassword),
                          ),
                          const SizedBox(height: 18),
                          GradientButton(
                            label: l10n.profileUpdatePassword,
                            loading: _savingPassword,
                            onPressed: _savingPassword ? null : _changePassword,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _MenuRow(icon: Icons.credit_card_outlined, label: l10n.profilePaymentMethods),
                          _MenuRow(icon: Icons.notifications_outlined, label: l10n.profileNotificationPreferences),
                          _MenuRow(icon: Icons.language_outlined, label: l10n.profileLanguageAndRegion, onTap: _pickLanguage),
                          _MenuRow(
                            icon: Icons.card_giftcard_outlined,
                            label: l10n.profileRewardsAndReferrals,
                            onTap: () => context.push('/rewards'),
                          ),
                          _MenuRow(icon: Icons.help_outline, label: l10n.profileSupport, onTap: () => context.push('/support')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => context.read<AuthState>().logout(),
                      icon: const Icon(Icons.logout, color: AppColors.statusRed),
                      label: Text(l10n.profileLogOut, style: const TextStyle(color: AppColors.statusRed)),
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

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
            Icon(
              Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
