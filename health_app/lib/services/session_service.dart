import 'package:firebase_auth/firebase_auth.dart';

class SessionService {
  static SessionService? _instance;
  static SessionService get instance => _instance ??= SessionService._();

  SessionService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Session data
  bool _isLoggedIn = false;
  String? _loggedInUsername;
  String? _loggedInEmail;
  DateTime? _loginTime;

  // Save user session
  void saveUserSession(String username, {String? email}) {
    _isLoggedIn = true;
    _loggedInUsername = username;
    _loggedInEmail = email ?? _auth.currentUser?.email;
    _loginTime = DateTime.now();
  }

  // Check if user is logged in (check both session and Firebase Auth)
  bool isLoggedIn() {
    return _isLoggedIn && _auth.currentUser != null;
  }

  // Get logged in username
  String? getLoggedInUsername() {
    if (isLoggedIn()) {
      return _loggedInUsername ??
          _auth.currentUser?.displayName ??
          _auth.currentUser?.email?.split('@')[0];
    }
    return null;
  }

  // Get logged in email
  String? getLoggedInEmail() {
    if (isLoggedIn()) {
      return _loggedInEmail ?? _auth.currentUser?.email;
    }
    return null;
  }

  // Get login time
  DateTime? getLoginTime() {
    return _loginTime;
  }

  // Clear user session (logout)
  void clearUserSession() {
    _isLoggedIn = false;
    _loggedInUsername = null;
    _loggedInEmail = null;
    _loginTime = null;
  }

  // Get session duration
  Duration? getSessionDuration() {
    if (_loginTime != null) {
      return DateTime.now().difference(_loginTime!);
    }
    return null;
  }

  // Get formatted session duration
  String getFormattedSessionDuration() {
    final duration = getSessionDuration();
    if (duration != null) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      if (hours > 0) {
        return '${hours}h ${minutes}m';
      } else {
        return '${minutes}m';
      }
    }
    return '0m';
  }
}
