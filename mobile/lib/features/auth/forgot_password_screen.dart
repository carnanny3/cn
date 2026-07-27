import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/state/auth_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/gradient_button.dart';
import '../../l10n/generated/app_localizations.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _codeRequested = false;
  bool _submitting = false;
  bool _done = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    setState(() => _submitting = true);
    final auth = context.read<AuthState>();
    final ok = await auth.requestPasswordReset(_emailController.text.trim());
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _submitting = false;
      _codeRequested = ok;
    });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.lastError ?? l10n.commonSomethingWentWrong)));
    }
  }

  Future<void> _confirmReset() async {
    setState(() => _submitting = true);
    final auth = context.read<AuthState>();
    final ok = await auth.confirmPasswordReset(_codeController.text.trim(), _newPasswordController.text);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _submitting = false;
      _done = ok;
    });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.lastError ?? l10n.commonSomethingWentWrong)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.authForgotPasswordTitle)),
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: GlassCard(
              child: _done
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.check_circle_outline, color: AppColors.statusGreen, size: 40),
                        const SizedBox(height: 12),
                        Text(l10n.authForgotPasswordSuccessTitle, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                          l10n.authForgotPasswordSuccessMessage,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        GradientButton(label: l10n.authForgotPasswordBackToLogin, onPressed: () => Navigator.of(context).pop()),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _codeRequested ? l10n.authForgotPasswordEnterCode : l10n.authForgotPasswordEnterEmail,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        if (!_codeRequested) ...[
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: InputDecoration(labelText: l10n.authForgotPasswordEmailLabel),
                          ),
                          const SizedBox(height: 20),
                          GradientButton(label: l10n.authForgotPasswordSendCode, loading: _submitting, onPressed: _submitting ? null : _requestCode),
                        ] else ...[
                          if (auth.devResetCodeHint != null) ...[
                            Text(
                              '${l10n.authForgotPasswordDevCodeLabel}: ${auth.devResetCodeHint}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.goldLight),
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextField(
                            controller: _codeController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: InputDecoration(labelText: l10n.authForgotPasswordCodeLabel),
                          ),
                          TextField(
                            controller: _newPasswordController,
                            obscureText: true,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: InputDecoration(labelText: l10n.authForgotPasswordNewPasswordLabel),
                          ),
                          const SizedBox(height: 12),
                          GradientButton(label: l10n.authForgotPasswordTitle, loading: _submitting, onPressed: _submitting ? null : _confirmReset),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
