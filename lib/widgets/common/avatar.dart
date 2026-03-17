import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    this.radius = 18,
    this.showBorder = false,
  });

  final String? imageUrl;
  final double radius;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = Theme.of(context).colorScheme.surface;
    final muted = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Container(
      decoration: showBorder
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 2,
              ),
            )
          : null,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: surface,
        backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
        child: imageUrl == null
            ? Icon(Icons.person, color: muted, size: radius * 0.7)
            : null,
      ),
    );
  }
}
