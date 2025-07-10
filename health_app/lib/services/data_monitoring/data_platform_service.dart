// ignore_for_file: unused_field

import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../models/data_platform_models.dart';
import 'firebase_analytics_service.dart';

/// Comprehensive Data Platform Service
/// Extends Firebase Analytics with advanced data engineering capabilities
class DataPlatformService {
  static final DataPlatformService _instance = DataPlatformService._internal();
  factory DataPlatformService() => _instance;
  DataPlatformService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final Uuid _uuid = const Uuid();

  // Real-time data streams
  final StreamController<DataPlatformEvent> _eventStreamController =
      StreamController<DataPlatformEvent>.broadcast();
  final StreamController<HealthMetrics> _healthStreamController =
      StreamController<HealthMetrics>.broadcast();
  final StreamController<AnalyticsSnapshot> _snapshotStreamController =
      StreamController<AnalyticsSnapshot>.broadcast();

  // Session management
  String? _currentSessionId;
  DateTime? _sessionStartTime;
  Timer? _sessionTimer;

  // Data quality tracking
  final Map<String, DataQualityMetrics> _qualityMetrics = {};

  // Event buffering for batch processing
  final List<DataPlatformEvent> _eventBuffer = [];
  Timer? _batchTimer;
  static const int _batchSize = 50;
  static const Duration _batchInterval = Duration(seconds: 30);

  /// Initialize the comprehensive data platform
  Future<void> initialize() async {
    try {
      await _startSession();
      _initializeBatchProcessing();
      _initializeRealTimeAnalytics();

      if (kDebugMode) {
        print('🚀 Data Platform Service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing Data Platform Service: $e');
      }
    }
  }

  /// Start a new user session
  Future<void> _startSession() async {
    _currentSessionId = _uuid.v4();
    _sessionStartTime = DateTime.now();

    // Log session start event
    await trackEvent(
      eventType: 'session_start',
      category: 'session',
      properties: {
        'app_version': '1.0.0',
        'platform': defaultTargetPlatform.name,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    // Start session timeout timer
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      _endSession();
    });
  }

  /// End current session
  Future<void> _endSession() async {
    if (_currentSessionId != null && _sessionStartTime != null) {
      final sessionDuration = DateTime.now().difference(_sessionStartTime!);

      await trackEvent(
        eventType: 'session_end',
        category: 'session',
        properties: {
          'session_duration': sessionDuration.inSeconds,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    }

    _sessionTimer?.cancel();
    await _flushEventBuffer();
  }

  /// Track enhanced events with comprehensive metadata
  Future<void> trackEvent({
    required String eventType,
    required String category,
    Map<String, dynamic> properties = const {},
    List<String> tags = const [],
    String? userId,
  }) async {
    try {
      final event = DataPlatformEvent(
        eventId: _uuid.v4(),
        eventType: eventType,
        category: category,
        timestamp: DateTime.now(),
        userId: userId ?? 'anonymous',
        sessionId: _currentSessionId ?? 'unknown',
        properties: properties,
        context: await _buildEventContext(),
        tags: tags,
      );

      // Add to buffer for batch processing
      _eventBuffer.add(event);

      // Stream for real-time processing
      _eventStreamController.add(event);

      // Log to Firebase Analytics (backward compatibility)
      await FirebaseAnalyticsService.logEvent(
        name: eventType,
        parameters: _sanitizeParameters(properties),
      );

      // Check if buffer needs flushing
      if (_eventBuffer.length >= _batchSize) {
        await _flushEventBuffer();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error tracking event: $e');
      }
    }
  }

  /// Track health metrics with real-time streaming
  Future<void> trackHealthMetrics(HealthMetrics metrics) async {
    try {
      // Store in Firestore for persistence
      await _firestore
          .collection('health_metrics')
          .doc('${metrics.userId}_${metrics.timestamp.millisecondsSinceEpoch}')
          .set(metrics.toJson());

      // Stream for real-time processing
      _healthStreamController.add(metrics);

      // Track as analytics event
      await trackEvent(
        eventType: 'health_metric_recorded',
        category: 'health',
        userId: metrics.userId,
        properties: {
          'workout_type': metrics.workoutType,
          'has_heart_rate': metrics.heartRate != null,
          'has_location': metrics.location.isNotEmpty,
          'metric_count': _countNonNullMetrics(metrics),
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error tracking health metrics: $e');
      }
    }
  }

  /// Track user behavior patterns
  Future<void> trackUserBehavior({
    required String action,
    required String screen,
    Map<String, dynamic> properties = const {},
    int duration = 0,
  }) async {
    final behaviorEvent = UserBehaviorEvent(
      userId: 'current_user', // Get from auth service
      sessionId: _currentSessionId ?? 'unknown',
      timestamp: DateTime.now(),
      action: action,
      screen: screen,
      properties: properties,
      duration: duration,
    );

    try {
      // Store behavior event
      await _firestore.collection('user_behavior').add(behaviorEvent.toJson());

      // Track as analytics event
      await trackEvent(
        eventType: 'user_behavior',
        category: 'behavior',
        properties: {
          'action': action,
          'screen': screen,
          'duration': duration,
          ...properties,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error tracking user behavior: $e');
      }
    }
  }

  /// Generate real-time analytics snapshot
  Future<AnalyticsSnapshot> generateSnapshot() async {
    try {
      final now = DateTime.now();
      final hourAgo = now.subtract(const Duration(hours: 1));

      // Get active users count
      final activeUsersQuery = await _firestore
          .collection('user_sessions')
          .where('lastActivity', isGreaterThan: hourAgo)
          .get();

      // Get event counts
      final eventsQuery = await _firestore
          .collection('events')
          .where('timestamp', isGreaterThan: hourAgo)
          .get();

      final eventCounts = <String, int>{};
      for (final doc in eventsQuery.docs) {
        final eventType = doc.data()['eventType'] as String;
        eventCounts[eventType] = (eventCounts[eventType] ?? 0) + 1;
      }

      final snapshot = AnalyticsSnapshot(
        timestamp: now,
        activeUsers: activeUsersQuery.docs.length,
        totalSessions: activeUsersQuery.docs.length,
        eventCounts: eventCounts,
        metrics: await _calculateRealTimeMetrics(),
        topScreens: await _getTopScreens(),
      );

      _snapshotStreamController.add(snapshot);
      return snapshot;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating snapshot: $e');
      }

      return AnalyticsSnapshot(
        timestamp: DateTime.now(),
        activeUsers: 0,
        totalSessions: 0,
        eventCounts: {},
        metrics: {},
        topScreens: [],
      );
    }
  }

  /// Initialize batch processing for events
  void _initializeBatchProcessing() {
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(_batchInterval, (timer) {
      _flushEventBuffer();
    });
  }

  /// Initialize real-time analytics
  void _initializeRealTimeAnalytics() {
    // Generate snapshots every minute
    Timer.periodic(const Duration(minutes: 1), (timer) {
      generateSnapshot();
    });
  }

  /// Flush event buffer to persistent storage
  Future<void> _flushEventBuffer() async {
    if (_eventBuffer.isEmpty) return;

    try {
      final batch = _firestore.batch();
      final events = List<DataPlatformEvent>.from(_eventBuffer);
      _eventBuffer.clear();

      for (final event in events) {
        final docRef = _firestore.collection('events').doc(event.eventId);
        batch.set(docRef, event.toJson());
      }

      await batch.commit();

      if (kDebugMode) {
        print('✅ Flushed ${events.length} events to storage');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error flushing event buffer: $e');
      }
      // Re-add events to buffer for retry
      _eventBuffer.addAll(_eventBuffer);
    }
  }

  /// Build comprehensive event context
  Future<Map<String, dynamic>> _buildEventContext() async {
    return {
      'app_version': '1.0.0',
      'platform': defaultTargetPlatform.name,
      'session_id': _currentSessionId,
      'timestamp': DateTime.now().toIso8601String(),
      'timezone': DateTime.now().timeZoneName,
      'locale': 'vi_VN', // Get from app settings
    };
  }

  /// Sanitize parameters for Firebase Analytics
  Map<String, Object> _sanitizeParameters(Map<String, dynamic> parameters) {
    final sanitized = <String, Object>{};

    for (final entry in parameters.entries) {
      if (entry.value is String || entry.value is num || entry.value is bool) {
        sanitized[entry.key] = entry.value;
      } else {
        sanitized[entry.key] = entry.value.toString();
      }
    }

    return sanitized;
  }

  /// Count non-null metrics in health data
  int _countNonNullMetrics(HealthMetrics metrics) {
    int count = 0;
    if (metrics.heartRate != null) count++;
    if (metrics.steps != null) count++;
    if (metrics.calories != null) count++;
    if (metrics.distance != null) count++;
    if (metrics.speed != null) count++;
    if (metrics.elevation != null) count++;
    return count;
  }

  /// Calculate real-time metrics
  Future<Map<String, double>> _calculateRealTimeMetrics() async {
    // Implement real-time metric calculations
    return {
      'avg_session_duration': 0.0,
      'events_per_session': 0.0,
      'user_engagement_score': 0.0,
    };
  }

  /// Get top screens from recent activity
  Future<List<String>> _getTopScreens() async {
    // Implement top screens calculation
    return ['home', 'workout', 'profile'];
  }

  /// Streams for real-time data access
  Stream<DataPlatformEvent> get eventStream => _eventStreamController.stream;
  Stream<HealthMetrics> get healthStream => _healthStreamController.stream;
  Stream<AnalyticsSnapshot> get snapshotStream =>
      _snapshotStreamController.stream;

  /// Cleanup resources
  void dispose() {
    _sessionTimer?.cancel();
    _batchTimer?.cancel();
    _eventStreamController.close();
    _healthStreamController.close();
    _snapshotStreamController.close();
  }
}
