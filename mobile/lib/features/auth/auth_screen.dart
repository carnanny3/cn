import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/state/auth_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/gradient_button.dart';
import '../../l10n/generated/app_localizations.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isRegister = true;
  bool _submitting = false;
  bool _obscurePassword = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _referralCodeController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final auth = context.read<AuthState>();
    final ok = _isRegister
        ? await auth.register(
            _emailController.text.trim(),
            _passwordController.text,
            _nameController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            referralCode: _referralCodeController.text.trim(),
          )
        : await auth.login(_emailController.text.trim(), _passwordController.text);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.lastError ?? AppLocalizations.of(context)!.commonSomethingWentWrong)),
      );
    }
    // On success, AuthState.status flips to signedIn and the router's
    // redirect (reacting to refreshListenable) takes it from here — no
    // manual navigation needed.
  }

  void _showGoogleComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.authGoogleComingSoon)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Center(
                  child: Column(
                    children: [
                      Image.asset('assets/images/logo_icon.png', height: 96, width: 96),
                      const SizedBox(height: 16),
                      ShaderMask(
                        shaderCallback: (bounds) => AppColors.goldGradient.createShader(bounds),
                        child: Text(l10n.appTitle, style: Theme.of(context).textTheme.displayLarge?.copyWith(color: Colors.white)),
                      ),
                      const SizedBox(height: 6),
                      Text(l10n.appTagline, style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                GlassCard(
                  glow: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ModeToggle(
                        isRegister: _isRegister,
                        onChanged: (v) => setState(() => _isRegister = v),
                        signUpLabel: l10n.authSignUp,
                        logInLabel: l10n.authLogIn,
                      ),
                      const SizedBox(height: 20),
                      if (_isRegister) ...[
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(labelText: l10n.authFullName),
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(labelText: l10n.authEmail),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: l10n.authPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      if (_isRegister) ...[
                        const SizedBox(height: 14),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(labelText: l10n.authPhoneOptional),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _referralCodeController,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(labelText: l10n.authReferralCodeOptional),
                        ),
                      ],
                      if (!_isRegister) ...[
                        const SizedBox(height: 4),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton(
                            onPressed: () => context.push('/auth/forgot-password'),
                            child: Text(l10n.authForgotPassword),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      GradientButton(
                        label: _isRegister ? l10n.authCreateAccount : l10n.authLogIn,
                        loading: _submitting,
                        onPressed: _submitting ? null : _submit,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Expanded(child: Divider(color: AppColors.glassBorder)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(l10n.authOr, style: Theme.of(context).textTheme.bodySmall),
                          ),
                          const Expanded(child: Divider(color: AppColors.glassBorder)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _showGoogleComingSoon,
                        icon: const Icon(Icons.g_mobiledata, size: 26),
                        label: Text(l10n.authContinueWithGoogle),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.glassBorder),
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () => context.push('/partner-signup'),
                    child: Text(l10n.authBecomePartner),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.isRegister,
    required this.onChanged,
    required this.signUpLabel,
    required this.logInLabel,
  });

  final bool isRegister;
  final ValueChanged<bool> onChanged;
  final String signUpLabel;
  final String logInLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Expanded(child: _ModeSegment(label: signUpLabel, selected: isRegister, onTap: () => onChanged(true))),
          Expanded(child: _ModeSegment(label: logInLabel, selected: !isRegister, onTap: () => onChanged(false))),
        ],
      ),
    );
  }
}

class _ModeSegment extends StatelessWidget {
  const _ModeSegment({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.goldGradient : null,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.navyDeep : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
