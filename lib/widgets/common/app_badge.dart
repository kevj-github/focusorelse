import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class AppBadge extends StatelessWidget {
  const AppBadge({super.key, required this.label, this.highlight = false});

  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primary.withValues(alpha: 0.2)
            : AppColors.darkBorder,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: highlight ? AppColors.primary : AppColors.textSecondaryDark,
        ),
      ),
    );
  }
}
