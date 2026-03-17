import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

class AppInput extends StatefulWidget {
  const AppInput({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.hintText,
    this.maxLines = 1,
    this.keyboardType,
    this.obscureText = false,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final String? hintText;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (widget.label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.label,
              style: AppTypography.labelLarge.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        // Input Field
        Container(
          decoration: BoxDecoration(
            borderRadius: AppElevation.inputRadius,
            boxShadow: _isFocused ? AppElevation.shadowSmall : [],
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText,
            maxLines: widget.maxLines,
            onChanged: widget.onChanged,
            style: AppTypography.bodyLarge.copyWith(
              color: colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: secondaryText,
              ),
              labelStyle: AppTypography.labelLarge.copyWith(
                color: secondaryText,
              ),
              prefixIcon: widget.icon != null
                  ? Icon(
                      widget.icon,
                      color: _isFocused ? AppColors.primary : secondaryText,
                      size: 20,
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
              border: OutlineInputBorder(
                borderRadius: AppElevation.inputRadius,
                borderSide: BorderSide(
                  color: hasError
                      ? AppColors.error
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppElevation.inputRadius,
                borderSide: BorderSide(
                  color: hasError
                      ? AppColors.error
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppElevation.inputRadius,
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: AppElevation.inputRadius,
                borderSide: const BorderSide(
                  color: AppColors.error,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: AppElevation.inputRadius,
                borderSide: const BorderSide(color: AppColors.error, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              isCollapsed: false,
            ),
          ),
        ),
        // Error Message
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              widget.errorText!,
              style: AppTypography.labelSmall.copyWith(color: AppColors.error),
            ),
          ),
      ],
    );
  }
}
