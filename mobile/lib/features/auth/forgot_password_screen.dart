import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/state/auth_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/gradient_button.dart';

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
    setState(() {
      _submitting = false;
      _codeRequested = ok;
    });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.lastError ?? 'Something went wrong.')));
    }
  }

  Future<void> _confirmReset() async {
    setState(() => _submitting = true);
    final auth = context.read<AuthState>();
    final ok = await auth.confirmPasswordReset(_codeController.text.trim(), _newPasswordController.text);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _done = ok;
    });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.lastError ?? 'Something went wrong.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
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
                        Text('Password reset', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                          'Your password has been updated. Go back and log in with your new password.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        GradientButton(label: 'Back to login', onPressed: () => Navigator.of(context).pop()),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _codeRequested ? 'Enter the code we sent you' : 'Enter your account email',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        if (!_codeRequested) ...[
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: const InputDecoration(labelText: 'Email'),
                          ),
                          const SizedBox(height: 20),
                          GradientButton(label: 'Send reset code', loading: _submitting, onPressed: _submitting ? null : _requestCode),
                        ] else ...[
                          if (auth.devResetCodeHint != null) ...[
                            Text(
                              'Dev mode code: ${auth.devResetCodeHint}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.goldLight),
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextField(
                            controller: _codeController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: const InputDecoration(labelText: '6-digit code'),
                          ),
                          TextField(
                            controller: _newPasswordController,
                            obscureText: true,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: const InputDecoration(labelText: 'New password'),
                          ),
                          const SizedBox(height: 12),
                          GradientButton(label: 'Reset password', loading: _submitting, onPressed: _submitting ? null : _confirmReset),
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
