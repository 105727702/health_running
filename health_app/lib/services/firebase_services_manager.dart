import 'package:flutter/foundation.dart';
import 'firebase_analytics_service.dart';
import 'firebase_crashlytics_service.dart';
import 'firebase_performance_service.dart';

/// Main Firebase Services Manager
/// Coordinates all Firebase services initialization and provides unified access
class FirebaseServicesManager {
  static bool _isInitialized = false;

  /// Initialize all Firebase services
  static Future<void> initializeAll() async {
    if (_isInitialized) {
      if (kDebugMode) {
        print('Firebase services already initialized');
      }
      return;
    }

    try {
      if (kDebugMode) {
        print('Initializing Firebase services...');
      }

      // Initialize services in parallel for better performance
      await Future.wait([
        FirebaseAnalyticsService.initialize(),
        FirebaseCrashlyticsService.initialize(),
        FirebasePerformanceService.initialize(),
      ]);

      _isInitialized = true;

      if (kDebugMode) {
        print('All Firebase services initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Firebase services: $e');
      }
      // Log the initialization error to Crashlytics if available
      try {
        await FirebaseCrashlyticsService.recordError(
          e,
          StackTrace.current,
          reason: 'Failed to initialize Firebase services',
        );
      } catch (crashlyticsError) {
        if (kDebugMode) {
          print('Could not log to Crashlytics: $crashlyticsError');
        }
      }
      rethrow;
    }
  }

  /// Set user information across all services
  static Future<void> setUser({
    required String userId,
    String? email,
    String? displayName,
    Map<String, String>? customProperties,
  }) async {
    try {
      // Set user ID for Analytics
      await FirebaseAnalyticsService.setUserId(userId);

      // Set user ID for Crashlytics
      await FirebaseCrashlyticsService.setUserId(userId);

      // Set user properties for Analytics
      if (email != null) {
        await FirebaseAnalyticsService.setUserProperty(
          name: 'email',
          value: email,
        );
      }

      if (displayName != null) {
        await FirebaseAnalyticsService.setUserProperty(
          name: 'display_name',
          value: displayName,
        );
      }

      // Set custom properties
      if (customProperties != null) {
        for (final entry in customProperties.entries) {
          await FirebaseAnalyticsService.setUserProperty(
            name: entry.key,
            value: entry.value,
          );
          await FirebaseCrashlyticsService.setCustomKey(entry.key, entry.value);
        }
      }

      if (kDebugMode) {
        print('User information set across all Firebase services');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting user information: $e');
      }
      await FirebaseCrashlyticsService.recordError(
        e,
        StackTrace.current,
        reason: 'Failed to set user information',
      );
    }
  }

  /// Log user login across services
  static Future<void> logUserLogin({
    required String method,
    required String userId,
  }) async {
    try {
      // Log to Analytics
      await FirebaseAnalyticsService.logLogin(loginMethod: method);

      // Log to Crashlytics for context
      await FirebaseCrashlyticsService.logUserAction(
        'login',
        context: {'method': method, 'user_id': userId},
      );

      if (kDebugMode) {
        print('User login logged across Firebase services');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error logging user login: $e');
      }
      await FirebaseCrashlyticsService.recordError(
        e,
        StackTrace.current,
        reason: 'Failed to log user login',
      );
    }
  }

  /// Log user logout across services
  static Future<void> logUserLogout() async {
    try {
      // Log to Analytics
      await FirebaseAnalyticsService.logLogout();

      // Log to Crashlytics for context
      await FirebaseCrashlyticsService.logUserAction('logout');

      if (kDebugMode) {
        print('User logout logged across Firebase services');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error logging user logout: $e');
      }
      await FirebaseCrashlyticsService.recordError(
        e,
        StackTrace.current,
        reason: 'Failed to log user logout',
      );
    }
  }

  /// Log workout events with performance tracking
  static Future<T> logAndTrackWorkout<T>({
    required String workoutType,
    required String operation,
    required Future<T> Function() workoutOperation,
    String? location,
    Map<String, Object?>? additionalParams,
  }) async {
    try {
      // Start performance tracking
      return await FirebasePerformanceService.trackWorkoutOperation(
        operation,
        workoutOperation,
        workoutType: workoutType,
        location: location,
      );
    } catch (e) {
      // Log error to Crashlytics
      await FirebaseCrashlyticsService.logWorkoutError(operation, e.toString());

      // Log error event to Analytics
      await FirebaseAnalyticsService.logError(
        errorType: 'workout_error',
        errorMessage: e.toString(),
        screenName: 'workout',
      );

      rethrow;
    }
  }

  /// Log screen view with performance tracking
  static Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      // Track screen view performance
      await FirebasePerformanceService.measureOperation(
        'screen_view_$screenName',
        () async {
          // Log screen view to Analytics
          await FirebaseAnalyticsService.logScreenView(
            screenName: screenName,
            screenClass: screenClass,
          );
        },
        attributes: {
          'screen_name': screenName,
          if (screenClass != null) 'screen_class': screenClass,
        },
      );

      // Log to Crashlytics for context
      await FirebaseCrashlyticsService.logUserAction(
        'screen_view',
        context: {'screen_name': screenName},
      );

      if (kDebugMode) {
        print('Screen view logged: $screenName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error logging screen view: $e');
      }
      await FirebaseCrashlyticsService.recordError(
        e,
        StackTrace.current,
        reason: 'Failed to log screen view',
      );
    }
  }

  /// Handle and log errors across all services
  static Future<void> handleError({
    required dynamic error,
    required StackTrace stackTrace,
    required String errorType,
    String? screenName,
    String? userId,
    Map<String, String>? context,
  }) async {
    try {
      // Log to Crashlytics
      await FirebaseCrashlyticsService.recordError(
        error,
        stackTrace,
        reason: errorType,
      );

      // Log to Analytics
      await FirebaseAnalyticsService.logError(
        errorType: errorType,
        errorMessage: error.toString(),
        screenName: screenName,
      );

      // Add context if provided
      if (context != null) {
        for (final entry in context.entries) {
          await FirebaseCrashlyticsService.setCustomKey(entry.key, entry.value);
        }
      }

      if (kDebugMode) {
        print('Error handled across Firebase services: $errorType');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling error: $e');
      }
    }
  }

  /// Log feature usage with analytics and context
  static Future<void> logFeatureUsage({
    required String featureName,
    Map<String, Object>? parameters,
    Map<String, String>? context,
  }) async {
    try {
      // Log to Analytics
      await FirebaseAnalyticsService.logFeatureUsage(
        featureName: featureName,
        additionalParameters: parameters,
      );

      // Log to Crashlytics for context
      await FirebaseCrashlyticsService.logUserAction(
        'feature_used',
        context: {'feature_name': featureName, ...?context},
      );

      if (kDebugMode) {
        print('Feature usage logged: $featureName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error logging feature usage: $e');
      }
      await FirebaseCrashlyticsService.recordError(
        e,
        StackTrace.current,
        reason: 'Failed to log feature usage',
      );
    }
  }

  /// Get initialization status
  static bool get isInitialized => _isInitialized;

  /// Reset initialization status (for testing)
  static void resetInitialization() {
    _isInitialized = false;
  }
}
