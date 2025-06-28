import 'package:flutter/material.dart';
import '../utils/validation_utils.dart';
import '../widgets/forgot_password_dialog.dart';
import '../widgets/google_signin_button.dart';

class LoginForm extends StatelessWidget {
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final GlobalKey<FormState> formKey;
  final VoidCallback onLogin;
  final VoidCallback? onGoogleSignIn;
  final bool isLoading;
  final bool isGoogleLoading;
  final VoidCallback onSwitchToSignUp;

  const LoginForm({
    super.key,
    required this.usernameController,
    required this.passwordController,
    required this.formKey,
    required this.onLogin,
    this.onGoogleSignIn,
    required this.isLoading,
    this.isGoogleLoading = false,
    required this.onSwitchToSignUp,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          // App Logo/Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.deepPurple.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.health_and_safety,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 40),

          // App Title
          const Text(
            'Health App',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Track your fitness journey',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 40),

          // Login Form
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Email Field (Firebase Auth uses email)
                TextFormField(
                  controller: usernameController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    helperText: 'Enter your email address',
                  ),
                  validator: ValidationUtils.validateEmail,
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: ValidationUtils.validatePassword,
                ),
                const SizedBox(height: 12),

                // Forgot Password Link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const ForgotPasswordDialog(),
                      );
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: Colors.deepPurple, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'LOGIN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // OR Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),

                // Google Sign In Button
                if (onGoogleSignIn != null)
                  GoogleSignInButton(
                    onPressed: onGoogleSignIn!,
                    isLoading: isGoogleLoading,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Switch to Sign Up
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Don't have an account? ",
                style: TextStyle(color: Colors.grey),
              ),
              TextButton(
                onPressed: onSwitchToSignUp,
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
