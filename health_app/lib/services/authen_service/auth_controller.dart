import 'firebase_auth_service.dart';

class AuthController {
  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService();

  // Login functionality using Firebase Auth
  Future<AuthResult> login(String email, String password) async {
    return await _firebaseAuthService.login(email, password);
  }

  // Sign up functionality using Firebase Auth
  Future<AuthResult> signUp(
    String username,
    String email,
    String password,
  ) async {
    return await _firebaseAuthService.signUp(username, email, password);
  }

  // Logout functionality
  Future<AuthResult> logout() async {
    return await _firebaseAuthService.logout();
  }

  // Check if user is currently logged in
  bool isLoggedIn() {
    return _firebaseAuthService.isLoggedIn();
  }

  // Get current logged in user
  String? getCurrentUser() {
    return _firebaseAuthService.getCurrentUser();
  }

  // Get current user email
  String? getCurrentUserEmail() {
    return _firebaseAuthService.getCurrentUserEmail();
  }

  // Reset password
  Future<AuthResult> resetPassword(String email) async {
    return await _firebaseAuthService.resetPassword(email);
  }

  // Get session info
  String getSessionInfo() {
    return _firebaseAuthService.getSessionInfo();
  }
}
