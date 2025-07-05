// ignore_for_file: file_names

import "package:flutter/material.dart";
import "../../services/authen_service/auth_controller.dart";
import "../../services/authen_service/google_auth_service.dart";
// import "./services/firebase_debug_service.dart"; // Uncomment for testing
import "../../widgets/login_form.dart";
import "../../widgets/signup_form.dart";
import "../../utils/snackbar_utils.dart";
import "main_screen.dart";
// 🧪 DEBUG IMPORT - Remove before production
// import "../debug/login_debug_widget.dart";

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController =
      TextEditingController(); // For signup
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthController _authController = AuthController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isSignUpMode = false;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  void _checkExistingSession() {
    // Check if user is already logged in
    if (_authController.isLoggedIn()) {
      // print(' User already logged in, navigating to MainScreen...'); // DEBUG - commented for production
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      });
    } else {
      // print('ℹ No existing session found'); // DEBUG - commented for production
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // print(' Login button pressed'); // DEBUG - commented for production
    if (_formKey.currentState!.validate()) {
      // print(' Form validation passed'); // DEBUG - commented for production
      setState(() {
        _isLoading = true;
      });
      // print(' Loading state set to true, calling auth controller...'); // DEBUG - commented for production

      try {
        final result = await _authController.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        // print(' Auth controller returned: ${result.isSuccess ? "SUCCESS" : "ERROR"} - ${result.message}'); // DEBUG - commented for production

        if (mounted) {
          SnackBarUtils.showAuthSnackBar(context, result);

          if (result.isSuccess) {
            // print(' Login successful, navigating to MainScreen...'); // DEBUG - commented for production
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
          } else {
            // print(' Login failed: ${result.message}'); // DEBUG - commented for production
          }
        }
      } catch (e) {
        // print(' Unexpected error during login: $e'); // DEBUG - commented for production
        if (mounted) {
          SnackBarUtils.showError(context, 'An unexpected error occurred');
        }
      } finally {
        // Always reset loading state
        if (mounted) {
          // print(' Setting loading state to false'); // DEBUG - commented for production
          setState(() {
            _isLoading = false;
          });
          // print(' Loading state set to false'); // DEBUG - commented for production
        }
      }
    } else {
      // print(' Form validation failed'); // DEBUG - commented for production
    }
  }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final result = await _authController.signUp(
        _usernameController.text,
        _emailController.text,
        _passwordController.text,
      );

      if (mounted) {
        SnackBarUtils.showAuthSnackBar(context, result);

        if (result.isSuccess) {
          setState(() {
            _isSignUpMode = false;
            _emailController.clear();
            _usernameController.clear();
            _passwordController.clear();
          });
        }
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _switchMode() {
    setState(() {
      _isSignUpMode = !_isSignUpMode;
      _emailController.clear();
      _usernameController.clear();
      _passwordController.clear();
    });
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      final userCredential = await GoogleAuthService.signInWithGoogle();

      if (userCredential != null && mounted) {
        // Google Sign In successful
        SnackBarUtils.showSuccess(
          context,
          'Welcome ${userCredential.user?.displayName ?? 'User'}!',
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else if (mounted) {
        // User canceled or sign in failed
        SnackBarUtils.showError(context, 'Google Sign In cancelled or failed');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          'Google Sign In failed: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade400,
              Colors.deepPurple.shade600,
              Colors.deepPurple.shade800,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                  ),
                  child: _isSignUpMode
                      ? SignUpForm(
                          usernameController: _usernameController,
                          emailController: _emailController,
                          passwordController: _passwordController,
                          formKey: _formKey,
                          onSignUp: _handleSignUp,
                          isLoading: _isLoading,
                          onSwitchToLogin: _switchMode,
                        )
                      : LoginForm(
                          usernameController:
                              _emailController, // Using for email in login
                          passwordController: _passwordController,
                          formKey: _formKey,
                          onLogin: _handleLogin,
                          onGoogleSignIn: _handleGoogleSignIn,
                          isLoading: _isLoading,
                          isGoogleLoading: _isGoogleLoading,
                          onSwitchToSignUp: _switchMode,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),

     
    );
  }
}
