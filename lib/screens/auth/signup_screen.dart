import 'dart:async';

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
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  Timer? _usernameDebounce;
  bool _checkingUsername = false;
  bool? _isUsernameAvailable;
  String? _usernameError;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController
      ..removeListener(_onUsernameChanged)
      ..dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _usernameDebounce?.cancel();
    super.dispose();
  }

  String _normalizeUsernameInput(String input) {
    final lower = input.trim().toLowerCase();
    final withoutPrefix = lower.startsWith('@') ? lower.substring(1) : lower;
    return withoutPrefix.replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  void _onUsernameChanged() {
    _usernameDebounce?.cancel();
    final raw = _usernameController.text;
    final normalized = _normalizeUsernameInput(raw);
    if (raw != normalized) {
      _usernameController.value = _usernameController.value.copyWith(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    }

    if (normalized.length < 3) {
      setState(() {
        _isUsernameAvailable = null;
        _checkingUsername = false;
        _usernameError = normalized.isEmpty
            ? null
            : 'Username must be at least 3 characters.';
      });
      return;
    }

    setState(() {
      _checkingUsername = true;
      _usernameError = null;
    });

    _usernameDebounce = Timer(const Duration(milliseconds: 450), () async {
      final authProvider = context.read<AuthProvider>();
      final isAvailable = await authProvider.isUsernameAvailable(normalized);

      if (!mounted) return;
      setState(() {
        _checkingUsername = false;
        _isUsernameAvailable = isAvailable;
        _usernameError = isAvailable ? null : 'Username is already taken.';
      });
    });
  }

  Future<void> _register(AuthProvider authProvider) async {
    final normalizedUsername = _normalizeUsernameInput(
      _usernameController.text,
    );

    if (_displayNameController.text.trim().isEmpty ||
        normalizedUsername.isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      return;
    }

    if (normalizedUsername.length < 3 || _isUsernameAvailable != true) {
      setState(() {
        if (normalizedUsername.length < 3) {
          _usernameError = 'Username must be at least 3 characters.';
        } else if (_isUsernameAvailable == false) {
          _usernameError = 'Username is already taken.';
        } else {
          _usernameError = 'Check username availability before continuing.';
        }
      });
      return;
    }

    final success = await authProvider.registerWithEmailPassword(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _displayNameController.text.trim(),
      normalizedUsername,
    );

    if (!mounted) return;
    if (success) {
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
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + keyboardInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                'Sign up to start your first pact.',
                style: TextStyle(color: secondary),
              ),
              const SizedBox(height: 24),
              AppInput(
                controller: _displayNameController,
                label: 'Display name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 14),
              AppInput(
                controller: _usernameController,
                label: 'Username',
                icon: Icons.alternate_email,
                hintText: 'lowercase, numbers, underscore',
              ),
              if (_checkingUsername ||
                  _usernameError != null ||
                  _isUsernameAvailable == true)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    _checkingUsername
                        ? 'Checking username...'
                        : _usernameError ?? 'Username is available.',
                    style: TextStyle(
                      color: _checkingUsername
                          ? secondary
                          : (_usernameError != null
                                ? AppColors.primary
                                : AppColors.accent),
                      fontSize: 12,
                    ),
                  ),
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
                child: Text(
                  'Already have an account? Sign in',
                  style: TextStyle(color: secondary),
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
