import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../data_manage/session_service.dart';

// Firebase Auth Service
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SessionService _sessionService = SessionService.instance;

  // Login functionality using Firebase Auth
  Future<AuthResult> login(String email, String password) async {
    try {
      // print(' Attempting login for email: $email'); // DEBUG - commented for production

      if (email.isEmpty || password.isEmpty) {
        // print(' Empty email or password'); // DEBUG - commented for production
        return AuthResult.error('Email and password are required');
      }

      // print(' Calling Firebase signInWithEmailAndPassword...'); // DEBUG - commented for production
      // Sign in with Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // print(' Firebase auth successful, getting user data...'); // DEBUG - commented for production
      if (userCredential.user != null) {
        // Get additional user data from Firestore
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        String username = '';
        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          username = userData['username'] ?? '';
          // print(' Found username in Firestore: $username'); // DEBUG - commented for production
        } else {
          // print(' No user document found in Firestore for uid: ${userCredential.user!.uid}'); // DEBUG - commented for production
        }

        // Save session
        _sessionService.saveUserSession(
          username.isNotEmpty ? username : email.split('@')[0],
          email: email.trim(),
        );

        // print(' Login completed successfully'); // DEBUG - commented for production
        return AuthResult.success('Login successful!');
      } else {
        // print(' UserCredential.user is null'); // DEBUG - commented for production
        return AuthResult.error('Login failed');
      }
    } on FirebaseAuthException catch (e) {
      // print(' FirebaseAuthException: ${e.code} - ${e.message}'); // DEBUG - commented for production
      switch (e.code) {
        case 'user-not-found':
          return AuthResult.error('No user found with this email');
        case 'wrong-password':
          return AuthResult.error('Incorrect password');
        case 'invalid-email':
          return AuthResult.error('Invalid email format');
        case 'user-disabled':
          return AuthResult.error('This account has been disabled');
        case 'too-many-requests':
          return AuthResult.error('Too many failed attempts. Try again later');
        default:
          return AuthResult.error('Login error: ${e.message}');
      }
    } catch (e) {
      // print(' General error during login: $e'); // DEBUG - commented for production
      return AuthResult.error('Login error: $e');
    }
  }

  // Sign up functionality using Firebase Auth
  Future<AuthResult> signUp(
    String username,
    String email,
    String password,
  ) async {
    try {
      if (username.isEmpty || email.isEmpty || password.isEmpty) {
        return AuthResult.error('Username, email and password are required');
      }

      // Check if username already exists in Firestore
      QuerySnapshot existingUsers = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.trim())
          .get();

      if (existingUsers.docs.isNotEmpty) {
        return AuthResult.error('Username already exists');
      }

      // Create user with Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

      if (userCredential.user != null) {
        // Save additional user data to Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'username': username.trim(),
          'email': email.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'uid': userCredential.user!.uid,
        });

        // Update display name
        await userCredential.user!.updateDisplayName(username.trim());

        return AuthResult.success('Account created successfully!');
      } else {
        return AuthResult.error('Failed to create account');
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          return AuthResult.error('Password is too weak');
        case 'email-already-in-use':
          return AuthResult.error('Email is already registered');
        case 'invalid-email':
          return AuthResult.error('Invalid email format');
        case 'operation-not-allowed':
          return AuthResult.error('Email/password accounts are not enabled');
        default:
          return AuthResult.error('Sign up error: ${e.message}');
      }
    } catch (e) {
      return AuthResult.error('Sign up error: $e');
    }
  }

  // Logout functionality
  Future<AuthResult> logout() async {
    try {
      await _auth.signOut();
      _sessionService.clearUserSession();
      return AuthResult.success('Logged out successfully!');
    } catch (e) {
      return AuthResult.error('Logout error: $e');
    }
  }

  // Check if user is currently logged in
  bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  // Get current logged in user
  String? getCurrentUser() {
    User? user = _auth.currentUser;
    return user?.displayName ?? user?.email?.split('@')[0];
  }

  // Get current user email
  String? getCurrentUserEmail() {
    return _auth.currentUser?.email;
  }

  // Get current Firebase user
  User? getCurrentFirebaseUser() {
    return _auth.currentUser;
  }

  // Reset password with enhanced logging and validation
  Future<AuthResult> resetPassword(String email) async {
    try {
      if (email.isEmpty) {
        return AuthResult.error('Email is required');
      }

      // Validate email format first
      String pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
      RegExp regExp = RegExp(pattern);
      if (!regExp.hasMatch(email.trim())) {
        return AuthResult.error('Please enter a valid email address');
      }

      // ignore: avoid_print
      print(' Attempting to send password reset email to: ${email.trim()}');

      // Send password reset email via Firebase Auth
      await _auth.sendPasswordResetEmail(
        email: email.trim(),
        actionCodeSettings: ActionCodeSettings(
          // Customize the email template if needed
          url: 'https://health-app-9270b.firebaseapp.com', // Your app's domain
          handleCodeInApp: false,
        ),
      );

      // ignore: avoid_print
      print(' Password reset email sent successfully to: ${email.trim()}');
      return AuthResult.success(
        'Password reset email sent! Please check your inbox and spam folder.',
      );
    } on FirebaseAuthException catch (e) {
      // ignore: avoid_print
      print(' Firebase Auth Error: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'user-not-found':
          return AuthResult.error(
            'No account found with this email address. Please check the email or sign up first.',
          );
        case 'invalid-email':
          return AuthResult.error('Invalid email format');
        case 'too-many-requests':
          return AuthResult.error(
            'Too many reset attempts. Please wait a few minutes before trying again.',
          );
        case 'network-request-failed':
          return AuthResult.error(
            'Network error. Please check your internet connection.',
          );
        default:
          return AuthResult.error('Reset error: ${e.message}');
      }
    } catch (e) {
      // ignore: avoid_print
      print(' General Error: $e');
      return AuthResult.error('Reset error: $e');
    }
  }

  // Get session info
  String getSessionInfo() {
    final username = getCurrentUser();
    final duration = _sessionService.getFormattedSessionDuration();
    return 'User: $username | Session: $duration';
  }
}

// Result class to handle authentication outcomes
class AuthResult {
  final bool isSuccess;
  final String message;
  final AuthResultType type;

  AuthResult._(this.isSuccess, this.message, this.type);

  factory AuthResult.success(String message) {
    return AuthResult._(true, message, AuthResultType.success);
  }

  factory AuthResult.error(String message) {
    return AuthResult._(false, message, AuthResultType.error);
  }
}

enum AuthResultType { success, error }

// Extension to get snackbar colors
extension AuthResultExtension on AuthResult {
  Color get snackBarColor {
    switch (type) {
      case AuthResultType.success:
        return Colors.green;
      case AuthResultType.error:
        return Colors.red;
    }
  }
}
