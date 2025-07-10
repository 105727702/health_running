// Enhanced data models for comprehensive data platform

import 'dart:convert';

/// Enhanced event model for comprehensive tracking
class DataPlatformEvent {
  final String eventId;
  final String eventType;
  final String category;
  final DateTime timestamp;
  final String userId;
  final String sessionId;
  final Map<String, dynamic> properties;
  final Map<String, dynamic> context;
  final List<String> tags;

  const DataPlatformEvent({
    required this.eventId,
    required this.eventType,
    required this.category,
    required this.timestamp,
    required this.userId,
    required this.sessionId,
    required this.properties,
    required this.context,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'eventType': eventType,
      'category': category,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'sessionId': sessionId,
      'properties': properties,
      'context': context,
      'tags': tags,
    };
  }

  factory DataPlatformEvent.fromJson(Map<String, dynamic> json) {
    return DataPlatformEvent(
      eventId: json['eventId'],
      eventType: json['eventType'],
      category: json['category'],
      timestamp: DateTime.parse(json['timestamp']),
      userId: json['userId'],
      sessionId: json['sessionId'],
      properties: json['properties'] ?? {},
      context: json['context'] ?? {},
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}

/// Health metrics with enhanced tracking
class HealthMetrics {
  final String userId;
  final DateTime timestamp;
  final double? heartRate;
  final double? steps;
  final double? calories;
  final double? distance;
  final double? speed;
  final double? elevation;
  final Map<String, dynamic> location;
  final String workoutType;
  final Map<String, dynamic> additionalMetrics;

  const HealthMetrics({
    required this.userId,
    required this.timestamp,
    this.heartRate,
    this.steps,
    this.calories,
    this.distance,
    this.speed,
    this.elevation,
    this.location = const {},
    this.workoutType = 'unknown',
    this.additionalMetrics = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
      'heartRate': heartRate,
      'steps': steps,
      'calories': calories,
      'distance': distance,
      'speed': speed,
      'elevation': elevation,
      'location': location,
      'workoutType': workoutType,
      'additionalMetrics': additionalMetrics,
    };
  }

  factory HealthMetrics.fromJson(Map<String, dynamic> json) {
    return HealthMetrics(
      userId: json['userId'],
      timestamp: DateTime.parse(json['timestamp']),
      heartRate: json['heartRate']?.toDouble(),
      steps: json['steps']?.toDouble(),
      calories: json['calories']?.toDouble(),
      distance: json['distance']?.toDouble(),
      speed: json['speed']?.toDouble(),
      elevation: json['elevation']?.toDouble(),
      location: json['location'] ?? {},
      workoutType: json['workoutType'] ?? 'unknown',
      additionalMetrics: json['additionalMetrics'] ?? {},
    );
  }
}

/// User behavior tracking
class UserBehaviorEvent {
  final String userId;
  final String sessionId;
  final DateTime timestamp;
  final String action;
  final String screen;
  final Map<String, dynamic> properties;
  final int duration;

  const UserBehaviorEvent({
    required this.userId,
    required this.sessionId,
    required this.timestamp,
    required this.action,
    required this.screen,
    required this.properties,
    this.duration = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'sessionId': sessionId,
      'timestamp': timestamp.toIso8601String(),
      'action': action,
      'screen': screen,
      'properties': properties,
      'duration': duration,
    };
  }
}

/// Data quality metrics
class DataQualityMetrics {
  final String dataSource;
  final DateTime timestamp;
  final int totalRecords;
  final int validRecords;
  final int invalidRecords;
  final double completenessScore;
  final double accuracyScore;
  final List<String> issues;

  const DataQualityMetrics({
    required this.dataSource,
    required this.timestamp,
    required this.totalRecords,
    required this.validRecords,
    required this.invalidRecords,
    required this.completenessScore,
    required this.accuracyScore,
    this.issues = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'dataSource': dataSource,
      'timestamp': timestamp.toIso8601String(),
      'totalRecords': totalRecords,
      'validRecords': validRecords,
      'invalidRecords': invalidRecords,
      'completenessScore': completenessScore,
      'accuracyScore': accuracyScore,
      'issues': issues,
    };
  }
}

/// Real-time analytics snapshot
class AnalyticsSnapshot {
  final DateTime timestamp;
  final int activeUsers;
  final int totalSessions;
  final Map<String, int> eventCounts;
  final Map<String, double> metrics;
  final List<String> topScreens;

  const AnalyticsSnapshot({
    required this.timestamp,
    required this.activeUsers,
    required this.totalSessions,
    required this.eventCounts,
    required this.metrics,
    required this.topScreens,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'activeUsers': activeUsers,
      'totalSessions': totalSessions,
      'eventCounts': eventCounts,
      'metrics': metrics,
      'topScreens': topScreens,
    };
  }
}
