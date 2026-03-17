import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_input.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // FoE logo
                SizedBox(
                  height: 150,
                  width: 150,
                  child: Image.asset(
                    'assets/images/full.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Title
                Text(
                  'Focus or Else',
                  style: AppTypography.displaySmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Subtitle
                Text(
                  'Hold yourself accountable',
                  style: AppTypography.bodyLarge.copyWith(color: secondary),
                ),
                const SizedBox(height: AppSpacing.xxxl),

                // Error message
                if (authProvider.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: AppElevation.cardRadius,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            authProvider.errorMessage!,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Email Input
                AppInput(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Password Input
                AppInput(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: true,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Sign in Button
                AppButton(
                  label: 'Sign in',
                  isLoading: authProvider.isLoading,
                  onPressed: () => _handleEmailSignIn(authProvider),
                ),

                const SizedBox(height: AppSpacing.md),

                // Forgot password
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/forgot-password'),
                  child: Text(
                    'Forgot password?',
                    style: AppTypography.bodyMedium.copyWith(color: secondary),
                  ),
                ),

                const SizedBox(height: AppSpacing.xxxl),

                // Divider with text
                Row(
                  children: [
                    Expanded(child: Container(height: 1, color: border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Text(
                        'OR',
                        style: AppTypography.caption.copyWith(color: secondary),
                      ),
                    ),
                    Expanded(child: Container(height: 1, color: border)),
                  ],
                ),

                const SizedBox(height: AppSpacing.xxxl),

                // Google sign in
                AppButton(
                  label: 'Continue with Google',
                  variant: AppButtonVariant.outline,
                  isLoading: authProvider.isLoading,
                  onPressed: () => _handleGoogleSignIn(authProvider),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Sign up link
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Don\'t have an account? ',
                        style: AppTypography.bodyMedium.copyWith(
                          color: secondary,
                        ),
                      ),
                      Text(
                        'Sign up',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleEmailSignIn(AuthProvider authProvider) async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      return;
    }

    final success = await authProvider.signInWithEmailPassword(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success && mounted) {
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _handleGoogleSignIn(AuthProvider authProvider) async {
    final success = await authProvider.signInWithGoogle();

    if (!success && mounted) {
      // Show error if sign-in failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? 'Failed to sign in with Google',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }
}
