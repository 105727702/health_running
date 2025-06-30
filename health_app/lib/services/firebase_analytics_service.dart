import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Service class for Firebase Analytics
/// Provides methods for tracking user events and screen views
class FirebaseAnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver _observer = FirebaseAnalyticsObserver(
    analytics: _analytics,
  );

  /// Get the analytics observer for Navigator
  static FirebaseAnalyticsObserver get observer => _observer;

  /// Initialize Analytics with user properties
  static Future<void> initialize() async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(true);
      if (kDebugMode) {
        print('Firebase Analytics initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Firebase Analytics: $e');
      }
    }
  }

  /// Set user ID for analytics
  static Future<void> setUserId(String userId) async {
    try {
      await _analytics.setUserId(id: userId);
      if (kDebugMode) {
        print('Analytics user ID set: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting user ID: $e');
      }
    }
  }

  /// Set user properties
  static Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
      if (kDebugMode) {
        print('Analytics user property set: $name = $value');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting user property: $e');
      }
    }
  }

  /// Log screen view
  static Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
      if (kDebugMode) {
        print('Analytics screen view logged: $screenName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error logging screen view: $e');
      }
    }
  }

  /// Log custom event
  static Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
      if (kDebugMode) {
        print('Analytics event logged: $name with parameters: $parameters');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error logging event: $e');
      }
    }
  }

  /// Log login event
  static Future<void> logLogin({String? loginMethod}) async {
    await logEvent(
      name: 'login',
      parameters: {'method': loginMethod ?? 'unknown'},
    );
  }

  /// Log logout event
  static Future<void> logLogout() async {
    await logEvent(name: 'logout');
  }

  /// Log sign up event
  static Future<void> logSignUp({String? signUpMethod}) async {
    await logEvent(
      name: 'sign_up',
      parameters: {'method': signUpMethod ?? 'unknown'},
    );
  }

  /// Log workout start event
  static Future<void> logWorkoutStart({
    String? workoutType,
    String? location,
  }) async {
    await logEvent(
      name: 'workout_start',
      parameters: {
        'workout_type': workoutType ?? 'unknown',
        'location': location ?? 'unknown',
      },
    );
  }

  /// Log workout end event
  static Future<void> logWorkoutEnd({
    String? workoutType,
    int? duration,
    double? distance,
    int? calories,
  }) async {
    await logEvent(
      name: 'workout_end',
      parameters: {
        'workout_type': workoutType ?? 'unknown',
        'duration_seconds': duration ?? 0,
        'distance_meters': distance ?? 0.0,
        'calories': calories ?? 0,
      },
    );
  }

  /// Log goal achievement
  static Future<void> logGoalAchievement({
    required String goalType,
    required String goalValue,
  }) async {
    await logEvent(
      name: 'goal_achieved',
      parameters: {'goal_type': goalType, 'goal_value': goalValue},
    );
  }

  /// Log feature usage
  static Future<void> logFeatureUsage({
    required String featureName,
    Map<String, Object>? additionalParameters,
  }) async {
    final parameters = <String, Object>{'feature_name': featureName};

    if (additionalParameters != null) {
      parameters.addAll(additionalParameters);
    }

    await logEvent(name: 'feature_used', parameters: parameters);
  }

  /// Log error event
  static Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? screenName,
  }) async {
    await logEvent(
      name: 'error_occurred',
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage,
        'screen_name': screenName ?? 'unknown',
      },
    );
  }

  /// Reset analytics data (for testing)
  static Future<void> resetAnalyticsData() async {
    try {
      await _analytics.resetAnalyticsData();
      if (kDebugMode) {
        print('Analytics data reset');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error resetting analytics data: $e');
      }
    }
  }
}
