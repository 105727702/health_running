import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/data_platform_models.dart';

/// Data Quality and Validation Service
/// Ensures data integrity and tracks quality metrics
class DataQualityService {
  static final DataQualityService _instance = DataQualityService._internal();
  factory DataQualityService() => _instance;
  DataQualityService._internal();

  // Quality tracking
  final Map<String, List<String>> _validationRules = {};
  final Map<String, DataQualityMetrics> _qualityHistory = {};
  final StreamController<DataQualityMetrics> _qualityStreamController =
      StreamController<DataQualityMetrics>.broadcast();

  /// Initialize data validation rules
  void initialize() {
    _setupValidationRules();
    _startQualityMonitoring();

    if (kDebugMode) {
      print('✅ Data Quality Service initialized');
    }
  }

  /// Setup validation rules for different data types
  void _setupValidationRules() {
    // Health metrics validation rules
    _validationRules['health_metrics'] = [
      'heart_rate_range_check',
      'steps_positive_check',
      'calories_positive_check',
      'distance_positive_check',
      'speed_reasonable_check',
      'timestamp_recent_check',
    ];

    // User behavior validation rules
    _validationRules['user_behavior'] = [
      'session_id_format_check',
      'action_not_empty_check',
      'screen_valid_check',
      'duration_positive_check',
    ];

    // Event validation rules
    _validationRules['events'] = [
      'event_type_not_empty_check',
      'category_valid_check',
      'user_id_format_check',
      'timestamp_valid_check',
      'properties_structure_check',
    ];
  }

  /// Validate health metrics data
  ValidationResult validateHealthMetrics(HealthMetrics metrics) {
    final issues = <String>[];

    // Heart rate validation (30-220 bpm)
    if (metrics.heartRate != null &&
        (metrics.heartRate! < 30 || metrics.heartRate! > 220)) {
      issues.add(
        'Heart rate out of valid range (30-220): ${metrics.heartRate}',
      );
    }

    // Steps validation (non-negative)
    if (metrics.steps != null && metrics.steps! < 0) {
      issues.add('Steps cannot be negative: ${metrics.steps}');
    }

    // Calories validation (non-negative)
    if (metrics.calories != null && metrics.calories! < 0) {
      issues.add('Calories cannot be negative: ${metrics.calories}');
    }

    // Distance validation (non-negative, reasonable max)
    if (metrics.distance != null &&
        (metrics.distance! < 0 || metrics.distance! > 100000)) {
      issues.add('Distance out of valid range (0-100km): ${metrics.distance}');
    }

    // Speed validation (0-30 m/s for running)
    if (metrics.speed != null && (metrics.speed! < 0 || metrics.speed! > 30)) {
      issues.add('Speed out of valid range (0-30 m/s): ${metrics.speed}');
    }

    // Timestamp validation (not in future, not too old)
    final now = DateTime.now();
    final hourAgo = now.subtract(const Duration(hours: 24));
    if (metrics.timestamp.isAfter(now) || metrics.timestamp.isBefore(hourAgo)) {
      issues.add('Timestamp outside valid range: ${metrics.timestamp}');
    }

    return ValidationResult(
      isValid: issues.isEmpty,
      issues: issues,
      score: _calculateValidationScore(issues.length, 6),
    );
  }

  /// Validate event data
  ValidationResult validateEvent(DataPlatformEvent event) {
    final issues = <String>[];

    // Event type validation
    if (event.eventType.isEmpty) {
      issues.add('Event type cannot be empty');
    }

    // Category validation
    final validCategories = ['session', 'health', 'behavior', 'system', 'user'];
    if (!validCategories.contains(event.category)) {
      issues.add('Invalid event category: ${event.category}');
    }

    // User ID format validation
    if (event.userId.isEmpty || event.userId.length < 3) {
      issues.add('Invalid user ID format: ${event.userId}');
    }

    // Session ID format validation
    if (event.sessionId.isEmpty) {
      issues.add('Session ID cannot be empty');
    }

    // Timestamp validation
    final now = DateTime.now();
    final dayAgo = now.subtract(const Duration(days: 1));
    if (event.timestamp.isAfter(now) || event.timestamp.isBefore(dayAgo)) {
      issues.add('Event timestamp outside valid range: ${event.timestamp}');
    }

    // Properties structure validation
    if (event.properties.containsKey('null') ||
        event.properties.values.any((v) => v == null)) {
      issues.add('Event properties contain null values');
    }

    return ValidationResult(
      isValid: issues.isEmpty,
      issues: issues,
      score: _calculateValidationScore(issues.length, 5),
    );
  }

  /// Validate user behavior data
  ValidationResult validateUserBehavior(UserBehaviorEvent behavior) {
    final issues = <String>[];

    // Action validation
    if (behavior.action.isEmpty) {
      issues.add('Action cannot be empty');
    }

    // Screen validation
    if (behavior.screen.isEmpty) {
      issues.add('Screen cannot be empty');
    }

    // Duration validation
    if (behavior.duration < 0 || behavior.duration > 3600) {
      issues.add('Duration out of valid range (0-3600s): ${behavior.duration}');
    }

    // Session ID validation
    if (behavior.sessionId.isEmpty) {
      issues.add('Session ID cannot be empty');
    }

    return ValidationResult(
      isValid: issues.isEmpty,
      issues: issues,
      score: _calculateValidationScore(issues.length, 4),
    );
  }

  /// Generate data quality metrics for a dataset
  Future<DataQualityMetrics> generateQualityMetrics({
    required String dataSource,
    required List<dynamic> data,
  }) async {
    int totalRecords = data.length;
    int validRecords = 0;
    final allIssues = <String>[];

    // Validate each record based on data source
    for (final record in data) {
      ValidationResult result;

      switch (dataSource) {
        case 'health_metrics':
          if (record is HealthMetrics) {
            result = validateHealthMetrics(record);
          } else {
            result = ValidationResult(
              isValid: false,
              issues: ['Invalid data type'],
              score: 0.0,
            );
          }
          break;
        case 'events':
          if (record is DataPlatformEvent) {
            result = validateEvent(record);
          } else {
            result = ValidationResult(
              isValid: false,
              issues: ['Invalid data type'],
              score: 0.0,
            );
          }
          break;
        case 'user_behavior':
          if (record is UserBehaviorEvent) {
            result = validateUserBehavior(record);
          } else {
            result = ValidationResult(
              isValid: false,
              issues: ['Invalid data type'],
              score: 0.0,
            );
          }
          break;
        default:
          result = ValidationResult(
            isValid: false,
            issues: ['Unknown data source'],
            score: 0.0,
          );
      }

      if (result.isValid) {
        validRecords++;
      } else {
        allIssues.addAll(result.issues);
      }
    }

    final metrics = DataQualityMetrics(
      dataSource: dataSource,
      timestamp: DateTime.now(),
      totalRecords: totalRecords,
      validRecords: validRecords,
      invalidRecords: totalRecords - validRecords,
      completenessScore: totalRecords > 0 ? validRecords / totalRecords : 0.0,
      accuracyScore: _calculateAccuracyScore(allIssues, totalRecords),
      issues: _getUniqueIssues(allIssues),
    );

    // Store metrics history
    _qualityHistory['${dataSource}_${DateTime.now().millisecondsSinceEpoch}'] =
        metrics;

    // Stream metrics for real-time monitoring
    _qualityStreamController.add(metrics);

    return metrics;
  }

  /// Start continuous quality monitoring
  void _startQualityMonitoring() {
    Timer.periodic(const Duration(minutes: 5), (timer) {
      _performQualityCheck();
    });
  }

  /// Perform periodic quality checks
  Future<void> _performQualityCheck() async {
    try {
      // This would typically check recent data quality
      // For now, just log that monitoring is active
      if (kDebugMode) {
        print('🔍 Performing data quality check...');
      }

      // You can implement checks for:
      // - Data freshness
      // - Schema compliance
      // - Anomaly detection
      // - Completeness trends
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in quality monitoring: $e');
      }
    }
  }

  /// Calculate validation score based on number of issues
  double _calculateValidationScore(int issues, int totalChecks) {
    if (totalChecks == 0) return 1.0;
    final passedChecks = totalChecks - issues;
    return passedChecks / totalChecks;
  }

  /// Calculate accuracy score based on issues and total records
  double _calculateAccuracyScore(List<String> issues, int totalRecords) {
    if (totalRecords == 0) return 1.0;
    final uniqueIssueTypes = issues.toSet().length;
    return 1.0 - (uniqueIssueTypes / (totalRecords * 0.1)); // Weighted scoring
  }

  /// Get unique issues from list
  List<String> _getUniqueIssues(List<String> allIssues) {
    final issueTypes = <String, int>{};

    for (final issue in allIssues) {
      final issueType = issue.split(':')[0]; // Get issue type before details
      issueTypes[issueType] = (issueTypes[issueType] ?? 0) + 1;
    }

    return issueTypes.entries
        .map((e) => '${e.key} (${e.value} occurrences)')
        .toList();
  }

  /// Get quality metrics history
  Map<String, DataQualityMetrics> get qualityHistory =>
      Map.from(_qualityHistory);

  /// Get quality stream for real-time monitoring
  Stream<DataQualityMetrics> get qualityStream =>
      _qualityStreamController.stream;

  /// Clean up resources
  void dispose() {
    _qualityStreamController.close();
  }
}

/// Validation result model
class ValidationResult {
  final bool isValid;
  final List<String> issues;
  final double score;

  const ValidationResult({
    required this.isValid,
    required this.issues,
    required this.score,
  });

  @override
  String toString() {
    return 'ValidationResult(isValid: $isValid, issues: ${issues.length}, score: $score)';
  }
}
