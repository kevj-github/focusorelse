import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';

enum AppCardVariant { elevated, outlined, filled }

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.variant = AppCardVariant.outlined,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final AppCardVariant variant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = _getBackgroundColor(context);
    final borderColor = _getBorderColor(isDark);
    final shadow = _getShadow();

    final container = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppElevation.cardRadius,
        border: variant != AppCardVariant.elevated
            ? Border.all(color: borderColor, width: 1.5)
            : null,
        boxShadow: shadow,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppElevation.cardRadius,
          child: container,
        ),
      );
    }

    return container;
  }

  Color _getBackgroundColor(BuildContext context) {
    return switch (variant) {
      AppCardVariant.elevated => Theme.of(context).colorScheme.surface,
      AppCardVariant.outlined => Theme.of(context).colorScheme.surface,
      AppCardVariant.filled => Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest,
    };
  }

  Color _getBorderColor(bool isDark) {
    return switch (variant) {
      AppCardVariant.elevated => Colors.transparent,
      AppCardVariant.outlined =>
        isDark ? AppColors.darkBorder : AppColors.lightBorder,
      AppCardVariant.filled => Colors.transparent,
    };
  }

  List<BoxShadow> _getShadow() {
    return switch (variant) {
      AppCardVariant.elevated => AppElevation.shadowSmall,
      AppCardVariant.outlined => [],
      AppCardVariant.filled => [],
    };
  }
}
