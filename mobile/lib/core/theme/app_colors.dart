import 'package:flutter/material.dart';

/// Color tokens from the Car Nanny design system. Kept as static const so
/// both ThemeData and one-off widgets can reference the same source of
/// truth. The product's visual identity is a dark, gradient/glassmorphism
/// look (navy -> gold), used consistently across light and dark system
/// settings rather than swapping to a flat white theme in light mode.
class AppColors {
  AppColors._();

  static const navyDeep = Color(0xFF0B1420);
  static const navyMid = Color(0xFF1A2942);
  static const bronze = Color(0xFF3A2A0F);

  static const textPrimary = Color(0xFFF5F6F8);
  static const textSecondary = Color(0xFFA7B0BD);

  static const goldLight = Color(0xFFF6E2A8);
  static const goldMid = Color(0xFFD4AF6A);
  static const goldDeep = Color(0xFFA6791F);

  static const glassFill = Color(0x14FFFFFF); // white @ 8%
  static const glassFillStrong = Color(0x1FFFFFFF); // white @ 12%
  static const glassBorder = Color(0x26FFFFFF); // white @ 15%

  static const statusGreen = Color(0xFF3FB57C);
  static const statusAmber = Color(0xFFE0973C);
  static const statusRed = Color(0xFFE15C5C);

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldLight, goldMid, goldDeep],
  );

  static const backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.6, 1.0],
    colors: [navyMid, navyDeep, bronze],
  );

  static Color statusColor(String status) {
    switch (status) {
      case 'green':
        return statusGreen;
      case 'amber':
        return statusAmber;
      case 'red':
      default:
        return statusRed;
    }
  }
}
