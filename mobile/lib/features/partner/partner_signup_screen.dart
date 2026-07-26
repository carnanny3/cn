import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/state/auth_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/gradient_button.dart';

class PartnerSignupScreen extends StatefulWidget {
  const PartnerSignupScreen({super.key});

  @override
  State<PartnerSignupScreen> createState() => _PartnerSignupScreenState();
}

class _PartnerSignupScreenState extends State<PartnerSignupScreen> {
  bool _submitting = false;
  bool _obscurePassword = true;
  String _partnerType = 'garage';

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _businessNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final auth = context.read<AuthState>();
    final ok = await auth.registerPartner(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
      businessName: _businessNameController.text.trim(),
      partnerType: _partnerType,
      contactPhone: _phoneController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.lastError ?? 'Something went wrong.')),
      );
    }
    // On success, AuthState.status flips to signedIn and the router redirect
    // sends partner-role accounts straight to the partner shell.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Become a Partner')),
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: GlassCard(
              glow: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('List your garage or inspection business', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    'Your account will be reviewed before it goes live.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.glassFill,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _TypeSegment(label: 'Garage', selected: _partnerType == 'garage', onTap: () => setState(() => _partnerType = 'garage'))),
                        Expanded(child: _TypeSegment(label: 'Inspector', selected: _partnerType == 'inspector', onTap: () => setState(() => _partnerType = 'inspector'))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _businessNameController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Business name'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Your full name'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Contact phone (optional)'),
                  ),
                  const SizedBox(height: 20),
                  GradientButton(label: 'Submit for review', loading: _submitting, onPressed: _submitting ? null : _submit),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeSegment extends StatelessWidget {
  const _TypeSegment({required this.label, required this.selected, required this.onTap});

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
