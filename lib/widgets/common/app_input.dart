import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class AppInput extends StatelessWidget {
  const AppInput({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
        prefixIcon: const Icon(Icons.circle, size: 0),
        prefixIconConstraints: const BoxConstraints(minWidth: 12),
        suffixIcon: Icon(icon, color: AppColors.textSecondaryDark),
      ),
    );
  }
}
