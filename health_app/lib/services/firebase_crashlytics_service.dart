import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Service class for Firebase Crashlytics
/// Provides methods for crash reporting and error logging
class FirebaseCrashlyticsService {
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  /// Initialize Crashlytics
  static Future<void> initialize() async {
    try {
      // Enable crashlytics collection
      await _crashlytics.setCrashlyticsCollectionEnabled(true);

      // Set up automatic crash reporting
      FlutterError.onError = (FlutterErrorDetails details) {
        _crashlytics.recordFlutterFatalError(details);
      };

      // Handle platform-specific errors
      PlatformDispatcher.instance.onError = (error, stack) {
        _crashlytics.recordError(error, stack, fatal: true);
        return true;
      };

      if (kDebugMode) {
        print('Firebase Crashlytics initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Firebase Crashlytics: $e');
      }
    }
  }

  /// Set user identifier for crash reports
  static Future<void> setUserId(String userId) async {
    try {
      await _crashlytics.setUserIdentifier(userId);
      if (kDebugMode) {
        print('Crashlytics user ID set: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting user ID: $e');
      }
    }
  }

  /// Set custom key-value pairs for crash reports
  static Future<void> setCustomKey(String key, Object value) async {
    try {
      await _crashlytics.setCustomKey(key, value);
      if (kDebugMode) {
        print('Crashlytics custom key set: $key = $value');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting custom key: $e');
      }
    }
  }

  /// Log a non-fatal error
  static Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
    Iterable<Object> information = const [],
  }) async {
    try {
      await _crashlytics.recordError(
        exception,
        stackTrace,
        reason: reason,
        fatal: fatal,
        information: information,
      );
      if (kDebugMode) {
        print('Crashlytics error recorded: $exception');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error recording crash: $e');
      }
    }
  }

  /// Log a message to Crashlytics
  static Future<void> log(String message) async {
    try {
      await _crashlytics.log(message);
      if (kDebugMode) {
        print('Crashlytics log: $message');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error logging message: $e');
      }
    }
  }

  /// Record a Flutter error
  static Future<void> recordFlutterError(FlutterErrorDetails details) async {
    try {
      await _crashlytics.recordFlutterError(details);
      if (kDebugMode) {
        print('Flutter error recorded to Crashlytics');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error recording Flutter error: $e');
      }
    }
  }

  /// Force a crash (for testing purposes only)
  static void forceCrash() {
    if (kDebugMode) {
      print(
        'WARNING: Force crash called - this should only be used for testing!',
      );
    }
    _crashlytics.crash();
  }

  /// Check if crash reporting is enabled
  static Future<bool> isCrashlyticsCollectionEnabled() async {
    try {
      return _crashlytics.isCrashlyticsCollectionEnabled;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking crashlytics status: $e');
      }
      return false;
    }
  }

  /// Send any unsent crash reports
  static Future<void> sendUnsentReports() async {
    try {
      await _crashlytics.sendUnsentReports();
      if (kDebugMode) {
        print('Unsent crash reports sent');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending unsent reports: $e');
      }
    }
  }

  /// Delete any unsent crash reports
  static Future<void> deleteUnsentReports() async {
    try {
      await _crashlytics.deleteUnsentReports();
      if (kDebugMode) {
        print('Unsent crash reports deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting unsent reports: $e');
      }
    }
  }

  /// Handle and log authentication errors
  static Future<void> logAuthError(String errorType, String message) async {
    await setCustomKey('error_type', 'authentication');
    await setCustomKey('auth_error_type', errorType);
    await log('Auth Error: $errorType - $message');
    await recordError(
      Exception('Authentication Error: $errorType'),
      StackTrace.current,
      reason: message,
    );
  }

  /// Handle and log workout errors
  static Future<void> logWorkoutError(String errorType, String message) async {
    await setCustomKey('error_type', 'workout');
    await setCustomKey('workout_error_type', errorType);
    await log('Workout Error: $errorType - $message');
    await recordError(
      Exception('Workout Error: $errorType'),
      StackTrace.current,
      reason: message,
    );
  }

  /// Handle and log location errors
  static Future<void> logLocationError(String errorType, String message) async {
    await setCustomKey('error_type', 'location');
    await setCustomKey('location_error_type', errorType);
    await log('Location Error: $errorType - $message');
    await recordError(
      Exception('Location Error: $errorType'),
      StackTrace.current,
      reason: message,
    );
  }

  /// Handle and log network errors
  static Future<void> logNetworkError(String errorType, String message) async {
    await setCustomKey('error_type', 'network');
    await setCustomKey('network_error_type', errorType);
    await log('Network Error: $errorType - $message');
    await recordError(
      Exception('Network Error: $errorType'),
      StackTrace.current,
      reason: message,
    );
  }

  /// Log user actions for context
  static Future<void> logUserAction(
    String action, {
    Map<String, String>? context,
  }) async {
    await log('User Action: $action');
    if (context != null) {
      for (final entry in context.entries) {
        await setCustomKey('action_${entry.key}', entry.value);
      }
    }
  }
}
