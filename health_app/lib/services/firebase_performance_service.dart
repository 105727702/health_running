import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

/// Service class for Firebase Performance Monitoring
/// Provides methods for tracking app performance metrics
class FirebasePerformanceService {
  static final FirebasePerformance _performance = FirebasePerformance.instance;

  /// Initialize Performance Monitoring
  static Future<void> initialize() async {
    try {
      await _performance.setPerformanceCollectionEnabled(true);
      if (kDebugMode) {
        print('Firebase Performance initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Firebase Performance: $e');
      }
    }
  }

  /// Create a custom trace
  static Trace createTrace(String traceName) {
    return _performance.newTrace(traceName);
  }

  /// Start a custom trace and return it for manual control
  static Future<Trace> startTrace(String traceName) async {
    try {
      final trace = _performance.newTrace(traceName);
      await trace.start();
      if (kDebugMode) {
        print('Performance trace started: $traceName');
      }
      return trace;
    } catch (e) {
      if (kDebugMode) {
        print('Error starting trace: $e');
      }
      rethrow;
    }
  }

  /// Stop a trace
  static Future<void> stopTrace(Trace trace) async {
    try {
      await trace.stop();
      if (kDebugMode) {
        print('Performance trace stopped');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping trace: $e');
      }
    }
  }

  /// Set attribute for a trace
  static Future<void> setTraceAttribute(
    Trace trace,
    String attributeName,
    String value,
  ) async {
    try {
      trace.putAttribute(attributeName, value);
      if (kDebugMode) {
        print('Trace attribute set: $attributeName = $value');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting trace attribute: $e');
      }
    }
  }

  /// Set metric for a trace
  static Future<void> setTraceMetric(
    Trace trace,
    String metricName,
    int value,
  ) async {
    try {
      trace.setMetric(metricName, value);
      if (kDebugMode) {
        print('Trace metric set: $metricName = $value');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting trace metric: $e');
      }
    }
  }

  /// Increment a metric for a trace
  static Future<void> incrementTraceMetric(
    Trace trace,
    String metricName,
    int incrementBy,
  ) async {
    try {
      trace.incrementMetric(metricName, incrementBy);
      if (kDebugMode) {
        print('Trace metric incremented: $metricName by $incrementBy');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error incrementing trace metric: $e');
      }
    }
  }

  /// Create and execute a timed operation
  static Future<T> measureOperation<T>(
    String traceName,
    Future<T> Function() operation, {
    Map<String, String>? attributes,
    Map<String, int>? metrics,
  }) async {
    final trace = _performance.newTrace(traceName);

    try {
      await trace.start();

      // Set attributes if provided
      if (attributes != null) {
        for (final entry in attributes.entries) {
          trace.putAttribute(entry.key, entry.value);
        }
      }

      // Set metrics if provided
      if (metrics != null) {
        for (final entry in metrics.entries) {
          trace.setMetric(entry.key, entry.value);
        }
      }

      final result = await operation();
      await trace.stop();

      if (kDebugMode) {
        print('Performance operation completed: $traceName');
      }

      return result;
    } catch (e) {
      await trace.stop();
      if (kDebugMode) {
        print('Error in performance operation: $e');
      }
      rethrow;
    }
  }

  /// Track workout performance
  static Future<T> trackWorkoutOperation<T>(
    String operationType,
    Future<T> Function() operation, {
    String? workoutType,
    String? location,
  }) async {
    return measureOperation(
      'workout_$operationType',
      operation,
      attributes: {
        'operation_type': operationType,
        if (workoutType != null) 'workout_type': workoutType,
        if (location != null) 'location': location,
      },
    );
  }

  /// Track authentication performance
  static Future<T> trackAuthOperation<T>(
    String operationType,
    Future<T> Function() operation, {
    String? authMethod,
  }) async {
    return measureOperation(
      'auth_$operationType',
      operation,
      attributes: {
        'operation_type': operationType,
        if (authMethod != null) 'auth_method': authMethod,
      },
    );
  }

  /// Track location services performance
  static Future<T> trackLocationOperation<T>(
    String operationType,
    Future<T> Function() operation, {
    String? accuracy,
  }) async {
    return measureOperation(
      'location_$operationType',
      operation,
      attributes: {
        'operation_type': operationType,
        if (accuracy != null) 'accuracy': accuracy,
      },
    );
  }

  /// Track data synchronization performance
  static Future<T> trackSyncOperation<T>(
    String operationType,
    Future<T> Function() operation, {
    String? dataType,
    int? recordCount,
  }) async {
    return measureOperation(
      'sync_$operationType',
      operation,
      attributes: {
        'operation_type': operationType,
        if (dataType != null) 'data_type': dataType,
      },
      metrics: {if (recordCount != null) 'record_count': recordCount},
    );
  }

  /// Track UI performance
  static Future<T> trackUIOperation<T>(
    String screenName,
    String operationType,
    Future<T> Function() operation,
  ) async {
    return measureOperation(
      'ui_${screenName}_$operationType',
      operation,
      attributes: {'screen_name': screenName, 'operation_type': operationType},
    );
  }

  /// Track network request performance
  static Future<T> trackNetworkOperation<T>(
    String endpoint,
    String method,
    Future<T> Function() operation, {
    int? responseCode,
    int? payloadSize,
  }) async {
    return measureOperation(
      'network_request',
      operation,
      attributes: {
        'endpoint': endpoint,
        'method': method,
        if (responseCode != null) 'response_code': responseCode.toString(),
      },
      metrics: {if (payloadSize != null) 'payload_size_bytes': payloadSize},
    );
  }

  /// Track database operation performance
  static Future<T> trackDatabaseOperation<T>(
    String operationType,
    Future<T> Function() operation, {
    String? collection,
    int? documentCount,
  }) async {
    return measureOperation(
      'database_$operationType',
      operation,
      attributes: {
        'operation_type': operationType,
        if (collection != null) 'collection': collection,
      },
      metrics: {if (documentCount != null) 'document_count': documentCount},
    );
  }

  /// Track app startup performance
  static Future<void> trackAppStartup() async {
    final trace = _performance.newTrace('app_startup');
    await trace.start();

    // This should be called at the end of app initialization
    // You can call stopAppStartupTrace() when the app is fully loaded
    if (kDebugMode) {
      print('App startup tracking started');
    }
  }

  /// Stop app startup tracking
  static Future<void> stopAppStartupTrace() async {
    // Note: This is a simplified approach. In practice, you'd want to
    // store the trace instance and stop it when appropriate
    if (kDebugMode) {
      print('App startup tracking should be stopped manually');
    }
  }

  /// Enable/disable performance collection
  static Future<void> setPerformanceCollectionEnabled(bool enabled) async {
    try {
      await _performance.setPerformanceCollectionEnabled(enabled);
      if (kDebugMode) {
        print('Performance collection ${enabled ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting performance collection: $e');
      }
    }
  }

  /// Check if performance collection is enabled
  static Future<bool> isPerformanceCollectionEnabled() async {
    try {
      return await _performance.isPerformanceCollectionEnabled();
    } catch (e) {
      if (kDebugMode) {
        print('Error checking performance collection status: $e');
      }
      return false;
    }
  }
}
