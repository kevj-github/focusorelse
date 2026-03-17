import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_input.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset(AuthProvider authProvider) async {
    if (_emailController.text.trim().isEmpty) return;

    final success = await authProvider.resetPassword(
      _emailController.text.trim(),
    );
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Forgot password')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Text(
            'Enter your email and we will send a reset link.',
            style: AppTypography.bodyLarge.copyWith(color: secondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppInput(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Send reset link',
            isLoading: authProvider.isLoading,
            onPressed: () => _sendReset(authProvider),
          ),
          if (authProvider.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              authProvider.errorMessage!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }
}
