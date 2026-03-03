import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/colors.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_input.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register(AuthProvider authProvider) async {
    if (_displayNameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      return;
    }

    final success = await authProvider.registerWithEmailPassword(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _displayNameController.text.trim(),
    );

    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Sign up to start your first pact.',
                style: TextStyle(color: AppColors.textSecondaryDark),
              ),
              const SizedBox(height: 24),
              AppInput(
                controller: _displayNameController,
                label: 'Display name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 14),
              AppInput(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              AppInput(
                controller: _passwordController,
                label: 'Password',
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Create account',
                isLoading: authProvider.isLoading,
                onPressed: () => _register(authProvider),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: authProvider.isLoading
                    ? null
                    : () => Navigator.pop(context),
                child: const Text(
                  'Already have an account? Sign in',
                  style: TextStyle(color: AppColors.textSecondaryDark),
                ),
              ),
              if (authProvider.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  authProvider.errorMessage!,
                  style: const TextStyle(color: AppColors.primary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
