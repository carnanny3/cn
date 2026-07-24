import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Frosted-glass card: blurred backdrop + translucent fill + soft border +
/// a subtle gold-tinted glow. This is the primary surface unit of the
/// glassmorphism design language — used for every card-like grouping.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius,
    this.onTap,
    this.strong = false,
    this.glow = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final bool strong;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppTheme.radiusCard);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: strong ? AppColors.glassFillStrong : AppColors.glassFill,
            borderRadius: radius,
            border: Border.all(color: AppColors.glassBorder),
            boxShadow: glow
                ? [
                    BoxShadow(
                      color: AppColors.goldMid.withValues(alpha: 0.18),
                      blurRadius: 24,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
