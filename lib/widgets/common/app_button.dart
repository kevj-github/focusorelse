import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

enum AppButtonVariant { primary, outline, ghost }

enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final Widget? icon;
  final bool fullWidth;

  EdgeInsets _getPadding() {
    return switch (size) {
      AppButtonSize.small => const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      AppButtonSize.medium => const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 12,
      ),
      AppButtonSize.large => const EdgeInsets.symmetric(
        horizontal: 32,
        vertical: 16,
      ),
    };
  }

  double _getHeight() {
    return switch (size) {
      AppButtonSize.small => 36,
      AppButtonSize.medium => 48,
      AppButtonSize.large => 56,
    };
  }

  TextStyle _getTextStyle() {
    return switch (size) {
      AppButtonSize.small => AppTypography.labelSmall,
      AppButtonSize.medium => AppTypography.labelLarge,
      AppButtonSize.large => AppTypography.titleSmall,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(
                variant == AppButtonVariant.primary
                    ? Colors.white
                    : AppColors.primary,
              ),
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: 8)],
              Text(label),
            ],
          );

    final buttonWidget = switch (variant) {
      AppButtonVariant.primary => _buildPrimaryButton(
        context,
        child,
        colorScheme,
        isDark,
      ),
      AppButtonVariant.outline => _buildOutlineButton(
        context,
        child,
        colorScheme,
        isDark,
      ),
      AppButtonVariant.ghost => _buildGhostButton(context, child, colorScheme),
    };

    return fullWidth
        ? SizedBox(
            width: double.infinity,
            height: _getHeight(),
            child: buttonWidget,
          )
        : SizedBox(height: _getHeight(), child: buttonWidget);
  }

  Widget _buildPrimaryButton(
    BuildContext context,
    Widget child,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        disabledBackgroundColor: isDark
            ? AppColors.darkBorder
            : AppColors.lightBorder,
        foregroundColor: Colors.white,
        disabledForegroundColor: isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight,
        elevation: 0,
        padding: _getPadding(),
        shape: RoundedRectangleBorder(borderRadius: AppElevation.buttonRadius),
        textStyle: _getTextStyle(),
      ),
      child: child,
    );
  }

  Widget _buildOutlineButton(
    BuildContext context,
    Widget child,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        disabledForegroundColor: isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight,
        side: BorderSide(
          color: isLoading
              ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
              : AppColors.primary,
          width: 1.5,
        ),
        padding: _getPadding(),
        shape: RoundedRectangleBorder(borderRadius: AppElevation.buttonRadius),
        textStyle: _getTextStyle(),
      ),
      child: child,
    );
  }

  Widget _buildGhostButton(
    BuildContext context,
    Widget child,
    ColorScheme colorScheme,
  ) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: _getPadding(),
        textStyle: _getTextStyle(),
      ),
      child: child,
    );
  }
}
