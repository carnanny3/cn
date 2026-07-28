import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Square listing image with a graceful placeholder — most listings have no
/// photo yet, and a broken-image box would look worse than a car icon.
class ListingThumbnail extends StatelessWidget {
  const ListingThumbnail({super.key, required this.url, this.size = 64});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.glassFillStrong,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.directions_car_outlined, color: AppColors.textSecondary),
    );

    if (url == null || url!.isEmpty) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}
