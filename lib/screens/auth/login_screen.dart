import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  final _displayNameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0B),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Title
                const Text(
                  'Focus or Else',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF2659),
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Hold yourself accountable',
                  style: TextStyle(fontSize: 16, color: Color(0xFF9BA1A6)),
                ),
                const SizedBox(height: 60),

                // Error message
                if (authProvider.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF2659).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFF2659).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Color(0xFFFF2659),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authProvider.errorMessage!,
                            style: const TextStyle(
                              color: Color(0xFFFF2659),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Display name field (only for sign up)
                if (_isSignUp) ...[
                  _buildTextField(
                    controller: _displayNameController,
                    label: 'Display Name',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                ],

                // Email field
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // Password field
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),
                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading
                        ? null
                        : () => _handleEmailAuth(authProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF2659),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: authProvider.isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            _isSignUp ? 'Sign Up' : 'Sign In',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Toggle sign in/sign up
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isSignUp = !_isSignUp;
                      authProvider.clearError();
                    });
                  },
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Sign In'
                        : 'Don\'t have an account? Sign Up',
                    style: const TextStyle(
                      color: Color(0xFF9BA1A6),
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: const Color(0xFF1E1E20),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Color(0xFF9BA1A6),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: const Color(0xFF1E1E20),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Google Sign In button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: authProvider.isLoading
                        ? null
                        : () => _handleGoogleSignIn(authProvider),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(
                        color: Color(0xFF1E1E20),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.g_mobiledata,
                            size: 20,
                            color: Color(0xFF4285F4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Continue with Google',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF9BA1A6)),
        prefixIcon: Icon(icon, color: Color(0xFF9BA1A6)),
        filled: true,
        fillColor: const Color(0xFF1E1E20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E1E20)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF2659), width: 2),
        ),
      ),
    );
  }

  Future<void> _handleEmailAuth(AuthProvider authProvider) async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      return;
    }

    if (_isSignUp && _displayNameController.text.isEmpty) {
      return;
    }

    bool success;
    if (_isSignUp) {
      success = await authProvider.registerWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _displayNameController.text.trim(),
      );
    } else {
      success = await authProvider.signInWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    }

    if (success && mounted) {
      // Navigation is handled by AuthWrapper in main.dart
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
          backgroundColor: const Color(0xFFFF2659),
        ),
      );
    }
  }
}
