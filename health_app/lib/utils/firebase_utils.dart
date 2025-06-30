import '../services/data_manage/firebase_services_manager.dart';
import '../services/data_monitoring/firebase_analytics_service.dart';
import '../services/data_monitoring/firebase_crashlytics_service.dart';
import '../services/data_monitoring/firebase_performance_service.dart';

/// Utility class for easy access to Firebase services
/// Provides convenient methods for common Firebase operations
class FirebaseUtils {
  /// Track page/screen view
  static Future<void> trackScreenView(String screenName) async {
    await FirebaseServicesManager.logScreenView(screenName: screenName);
  }

  /// Track page/screen navigation (alias for trackScreenView)
  static Future<void> trackNavigation(String screenName) async {
    await FirebaseServicesManager.logScreenView(screenName: screenName);
  }

  /// Track button or action tap
  static Future<void> trackButtonTap(
    String buttonName, {
    String? screenName,
  }) async {
    await FirebaseAnalyticsService.logEvent(
      name: 'button_tap',
      parameters: {
        'button_name': buttonName,
        if (screenName != null) 'screen_name': screenName,
      },
    );
  }

  /// Track form submission
  static Future<void> trackFormSubmission(
    String formName, {
    bool success = true,
  }) async {
    await FirebaseAnalyticsService.logEvent(
      name: 'form_submission',
      parameters: {'form_name': formName, 'success': success},
    );
  }

  /// Track search action
  static Future<void> trackSearch(String searchTerm, {String? category}) async {
    await FirebaseAnalyticsService.logEvent(
      name: 'search',
      parameters: {
        'search_term': searchTerm,
        if (category != null) 'category': category,
      },
    );
  }

  /// Track workout session
  static Future<void> trackWorkoutSession({
    required String workoutType,
    required int durationSeconds,
    double? distance,
    int? calories,
    String? location,
  }) async {
    await FirebaseAnalyticsService.logEvent(
      name: 'workout_session',
      parameters: {
        'workout_type': workoutType,
        'duration_seconds': durationSeconds,
        if (distance != null) 'distance_meters': distance,
        if (calories != null) 'calories': calories,
        if (location != null) 'location': location,
      },
    );
  }

  /// Track goal setting
  static Future<void> trackGoalSet({
    required String goalType,
    required String goalValue,
    String? timeframe,
  }) async {
    await FirebaseAnalyticsService.logEvent(
      name: 'goal_set',
      parameters: {
        'goal_type': goalType,
        'goal_value': goalValue,
        if (timeframe != null) 'timeframe': timeframe,
      },
    );
  }

  /// Track user preferences change
  static Future<void> trackPreferenceChange(
    String preferenceName,
    String newValue,
  ) async {
    await FirebaseAnalyticsService.logEvent(
      name: 'preference_change',
      parameters: {'preference_name': preferenceName, 'new_value': newValue},
    );
  }

  /// Track share action
  static Future<void> trackShare(String contentType, {String? platform}) async {
    await FirebaseAnalyticsService.logEvent(
      name: 'share',
      parameters: {
        'content_type': contentType,
        if (platform != null) 'platform': platform,
      },
    );
  }

  /// Track tutorial completion
  static Future<void> trackTutorialComplete(String tutorialName) async {
    await FirebaseAnalyticsService.logEvent(
      name: 'tutorial_complete',
      parameters: {'tutorial_name': tutorialName},
    );
  }

  /// Track app rating
  static Future<void> trackAppRating(int rating) async {
    await FirebaseAnalyticsService.logEvent(
      name: 'app_rating',
      parameters: {'rating': rating},
    );
  }

  /// Track performance for async operations
  static Future<T> trackAsyncOperation<T>(
    String operationName,
    Future<T> Function() operation, {
    Map<String, String>? attributes,
  }) async {
    return await FirebasePerformanceService.measureOperation(
      operationName,
      operation,
      attributes: attributes,
    );
  }

  /// Log and track authentication operations
  static Future<T> trackAuthOperation<T>(
    String operationType,
    Future<T> Function() operation, {
    String? method,
  }) async {
    return await FirebasePerformanceService.trackAuthOperation(
      operationType,
      operation,
      authMethod: method,
    );
  }

  /// Log and track location operations
  static Future<T> trackLocationOperation<T>(
    String operationType,
    Future<T> Function() operation, {
    String? accuracy,
  }) async {
    return await FirebasePerformanceService.trackLocationOperation(
      operationType,
      operation,
      accuracy: accuracy,
    );
  }

  /// Log and track database operations
  static Future<T> trackDatabaseOperation<T>(
    String operationType,
    Future<T> Function() operation, {
    String? collection,
  }) async {
    return await FirebasePerformanceService.trackDatabaseOperation(
      operationType,
      operation,
      collection: collection,
    );
  }

  /// Log non-fatal error with context
  static Future<void> logNonFatalError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    String? screenName,
    Map<String, String>? additionalInfo,
  }) async {
    // Add context information
    if (context != null) {
      await FirebaseCrashlyticsService.setCustomKey('error_context', context);
    }

    if (screenName != null) {
      await FirebaseCrashlyticsService.setCustomKey('screen_name', screenName);
    }

    if (additionalInfo != null) {
      for (final entry in additionalInfo.entries) {
        await FirebaseCrashlyticsService.setCustomKey(entry.key, entry.value);
      }
    }

    await FirebaseCrashlyticsService.recordError(
      error,
      stackTrace ?? StackTrace.current,
      reason: context,
    );
  }

  /// Log custom message for debugging
  static Future<void> logCustomMessage(String message) async {
    await FirebaseCrashlyticsService.log(message);
  }

  /// Set user session information
  static Future<void> setUserSession({
    required String userId,
    String? email,
    String? displayName,
    String? userType,
    String? subscriptionStatus,
  }) async {
    await FirebaseServicesManager.setUser(
      userId: userId,
      email: email,
      displayName: displayName,
      customProperties: {
        if (userType != null) 'user_type': userType,
        if (subscriptionStatus != null)
          'subscription_status': subscriptionStatus,
      },
    );
  }

  /// Clear user session
  static Future<void> clearUserSession() async {
    await FirebaseAnalyticsService.setUserId('');
    await FirebaseCrashlyticsService.setUserId('');
  }

  /// Force crash for testing (DEBUG ONLY)
  static void forceCrashForTesting() {
    assert(() {
      FirebaseCrashlyticsService.forceCrash();
      return true;
    }());
  }

  /// Check if all Firebase services are initialized
  static bool get isInitialized => FirebaseServicesManager.isInitialized;

  /// Initialize all Firebase services
  static Future<void> initialize() async {
    await FirebaseServicesManager.initializeAll();
  }
}
