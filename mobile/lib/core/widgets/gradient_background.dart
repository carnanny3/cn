import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Wraps a screen's body in the brand's signature navy->gold gradient.
/// Use instead of a plain Scaffold body for every top-level screen so the
/// gradient reads as one continuous surface behind glass cards.
class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: child,
    );
  }
}
