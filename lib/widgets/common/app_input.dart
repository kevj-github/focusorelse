import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class AppInput extends StatelessWidget {
  const AppInput({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.hintText,
    this.maxLines = 1,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final String? hintText;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
        prefixIcon: const Icon(Icons.circle, size: 0),
        prefixIconConstraints: const BoxConstraints(minWidth: 12),
        suffixIcon: icon != null
            ? Icon(icon, color: AppColors.textSecondaryDark)
            : null,
      ),
    );
  }
}
