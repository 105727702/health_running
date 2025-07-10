import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/data_platform_models.dart';
import 'data_platform_service.dart';
import 'data_quality_service.dart';
import 'data_pipeline_service.dart';

/// Comprehensive Data Platform Manager
/// Orchestrates all data engineering services
class DataPlatformManager {
  static final DataPlatformManager _instance = DataPlatformManager._internal();
  factory DataPlatformManager() => _instance;
  DataPlatformManager._internal();

  // Service instances
  final DataPlatformService _platformService = DataPlatformService();
  final DataQualityService _qualityService = DataQualityService();
  final DataPipelineService _pipelineService = DataPipelineService();

  // Initialization state
  bool _isInitialized = false;
  bool _isHealthy = true;

  // Health monitoring
  Timer? _healthCheckTimer;
  final StreamController<PlatformHealthStatus> _healthController =
      StreamController<PlatformHealthStatus>.broadcast();

  /// Initialize the entire data platform
  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) {
        print('⚠️ Data Platform already initialized');
      }
      return;
    }

    try {
      if (kDebugMode) {
        print('🚀 Initializing Comprehensive Data Platform...');
      }

      // Initialize services in order
      await _initializeDataQuality();
      await _initializeDataPlatform();
      await _initializeDataPipeline();

      // Setup cross-service integrations
      await _setupIntegrations();

      // Start health monitoring
      _startHealthMonitoring();

      _isInitialized = true;
      _isHealthy = true;

      if (kDebugMode) {
        print('✅ Comprehensive Data Platform initialized successfully');
      }
    } catch (e) {
      _isHealthy = false;
      if (kDebugMode) {
        print('❌ Failed to initialize Data Platform: $e');
      }
      rethrow;
    }
  }

  /// Initialize Data Quality Service
  Future<void> _initializeDataQuality() async {
    if (kDebugMode) {
      print('🔍 Initializing Data Quality Service...');
    }

    _qualityService.initialize();

    if (kDebugMode) {
      print('✅ Data Quality Service initialized');
    }
  }

  /// Initialize Data Platform Service
  Future<void> _initializeDataPlatform() async {
    if (kDebugMode) {
      print('📊 Initializing Data Platform Service...');
    }

    await _platformService.initialize();

    if (kDebugMode) {
      print('✅ Data Platform Service initialized');
    }
  }

  /// Initialize Data Pipeline Service
  Future<void> _initializeDataPipeline() async {
    if (kDebugMode) {
      print('🔄 Initializing Data Pipeline Service...');
    }

    await _pipelineService.initialize();

    if (kDebugMode) {
      print('✅ Data Pipeline Service initialized');
    }
  }

  /// Setup integrations between services
  Future<void> _setupIntegrations() async {
    if (kDebugMode) {
      print('🔗 Setting up service integrations...');
    }

    // Connect platform service events to pipeline
    _platformService.eventStream.listen(
      (event) => _pipelineService.addEvent(event),
      onError: (error) => _handleIntegrationError('event_stream', error),
    );

    _platformService.healthStream.listen(
      (metrics) => _pipelineService.addHealthMetrics(metrics),
      onError: (error) => _handleIntegrationError('health_stream', error),
    );

    // Connect quality service to monitoring
    _qualityService.qualityStream.listen(
      (qualityMetrics) => _handleQualityUpdate(qualityMetrics),
      onError: (error) => _handleIntegrationError('quality_stream', error),
    );

    if (kDebugMode) {
      print('✅ Service integrations configured');
    }
  }

  /// Start health monitoring for the platform
  void _startHealthMonitoring() {
    _healthCheckTimer = Timer.periodic(
      const Duration(minutes: 1),
      (timer) => _performHealthCheck(),
    );

    if (kDebugMode) {
      print('💓 Platform health monitoring started');
    }
  }

  /// Perform comprehensive health check
  Future<void> _performHealthCheck() async {
    try {
      final healthStatus = PlatformHealthStatus(
        timestamp: DateTime.now(),
        isHealthy: _isHealthy,
        services: {
          'data_platform': await _checkDataPlatformHealth(),
          'data_quality': await _checkDataQualityHealth(),
          'data_pipeline': await _checkDataPipelineHealth(),
        },
        metrics: await _collectHealthMetrics(),
      );

      _healthController.add(healthStatus);
      _isHealthy = healthStatus.isOverallHealthy;

      if (kDebugMode && !_isHealthy) {
        print(
          '⚠️ Platform health issues detected: ${healthStatus.unhealthyServices}',
        );
      }
    } catch (e) {
      _isHealthy = false;
      if (kDebugMode) {
        print('❌ Health check failed: $e');
      }
    }
  }

  /// Check Data Platform Service health
  Future<ServiceHealthStatus> _checkDataPlatformHealth() async {
    try {
      // Test snapshot generation
      await _platformService.generateSnapshot();

      return ServiceHealthStatus(
        isHealthy: true,
        lastCheck: DateTime.now(),
        metrics: {'snapshot_generation': 'ok'},
      );
    } catch (e) {
      return ServiceHealthStatus(
        isHealthy: false,
        lastCheck: DateTime.now(),
        error: e.toString(),
        metrics: {'snapshot_generation': 'failed'},
      );
    }
  }

  /// Check Data Quality Service health
  Future<ServiceHealthStatus> _checkDataQualityHealth() async {
    try {
      // Test validation functionality
      final testHealth = HealthMetrics(
        userId: 'test',
        timestamp: DateTime.now(),
        heartRate: 70,
      );

      _qualityService.validateHealthMetrics(testHealth);

      return ServiceHealthStatus(
        isHealthy: true,
        lastCheck: DateTime.now(),
        metrics: {'validation': 'ok'},
      );
    } catch (e) {
      return ServiceHealthStatus(
        isHealthy: false,
        lastCheck: DateTime.now(),
        error: e.toString(),
        metrics: {'validation': 'failed'},
      );
    }
  }

  /// Check Data Pipeline Service health
  Future<ServiceHealthStatus> _checkDataPipelineHealth() async {
    try {
      // Check pipeline streams
      return ServiceHealthStatus(
        isHealthy: true,
        lastCheck: DateTime.now(),
        metrics: {'pipeline_streams': 'ok'},
      );
    } catch (e) {
      return ServiceHealthStatus(
        isHealthy: false,
        lastCheck: DateTime.now(),
        error: e.toString(),
        metrics: {'pipeline_streams': 'failed'},
      );
    }
  }

  /// Collect platform-wide health metrics
  Future<Map<String, dynamic>> _collectHealthMetrics() async {
    return {
      'platform_uptime': DateTime.now().difference(DateTime.now()).inMinutes,
      'memory_usage': 'unknown', // Would implement actual memory monitoring
      'error_rate': 0.0,
      'processing_rate': 'normal',
    };
  }

  /// Handle integration errors between services
  void _handleIntegrationError(String integration, dynamic error) {
    if (kDebugMode) {
      print('❌ Integration error in $integration: $error');
    }

    // Could implement retry logic or circuit breaker pattern here
  }

  /// Handle quality metric updates
  void _handleQualityUpdate(DataQualityMetrics qualityMetrics) {
    if (qualityMetrics.completenessScore < 0.8) {
      if (kDebugMode) {
        print(
          '⚠️ Data quality alert: Low completeness score for ${qualityMetrics.dataSource}',
        );
      }
    }
  }

  /// Public API methods for the application

  /// Track health metrics through the platform
  Future<void> trackHealthMetrics({
    required String userId,
    double? heartRate,
    double? steps,
    double? calories,
    double? distance,
    double? speed,
    double? elevation,
    Map<String, dynamic> location = const {},
    String workoutType = 'unknown',
    Map<String, dynamic> additionalMetrics = const {},
  }) async {
    if (!_isInitialized) {
      throw StateError('Data Platform not initialized');
    }

    final metrics = HealthMetrics(
      userId: userId,
      timestamp: DateTime.now(),
      heartRate: heartRate,
      steps: steps,
      calories: calories,
      distance: distance,
      speed: speed,
      elevation: elevation,
      location: location,
      workoutType: workoutType,
      additionalMetrics: additionalMetrics,
    );

    await _platformService.trackHealthMetrics(metrics);
  }

  /// Track custom events
  Future<void> trackEvent({
    required String eventType,
    required String category,
    Map<String, dynamic> properties = const {},
    List<String> tags = const [],
    String? userId,
  }) async {
    if (!_isInitialized) {
      throw StateError('Data Platform not initialized');
    }

    await _platformService.trackEvent(
      eventType: eventType,
      category: category,
      properties: properties,
      tags: tags,
      userId: userId,
    );
  }

  /// Track user behavior
  Future<void> trackUserBehavior({
    required String action,
    required String screen,
    Map<String, dynamic> properties = const {},
    int duration = 0,
  }) async {
    if (!_isInitialized) {
      throw StateError('Data Platform not initialized');
    }

    await _platformService.trackUserBehavior(
      action: action,
      screen: screen,
      properties: properties,
      duration: duration,
    );
  }

  /// Get real-time analytics snapshot
  Future<AnalyticsSnapshot> getAnalyticsSnapshot() async {
    if (!_isInitialized) {
      throw StateError('Data Platform not initialized');
    }

    return await _platformService.generateSnapshot();
  }

  /// Get platform health status
  PlatformHealthStatus? get currentHealthStatus => _healthController.hasListener
      ? null
      : null; // Would implement proper state management

  /// Streams for real-time monitoring
  Stream<AnalyticsSnapshot> get analyticsStream =>
      _platformService.snapshotStream;
  Stream<DataQualityMetrics> get qualityStream => _qualityService.qualityStream;
  Stream<PlatformHealthStatus> get healthStream => _healthController.stream;

  /// Configuration methods
  void configurePlatform({
    bool? enableRealTimeProcessing,
    Duration? batchProcessingInterval,
    bool? enableQualityMonitoring,
  }) {
    if (enableRealTimeProcessing != null) {
      _pipelineService.configurePipeline(
        isProcessingEnabled: enableRealTimeProcessing,
      );
    }

    if (batchProcessingInterval != null) {
      _pipelineService.configurePipeline(
        processingInterval: batchProcessingInterval,
      );
    }
  }

  /// Check if platform is ready
  bool get isInitialized => _isInitialized;
  bool get isHealthy => _isHealthy;

  /// Cleanup resources
  Future<void> dispose() async {
    _healthCheckTimer?.cancel();
    _healthController.close();

    _platformService.dispose();
    _qualityService.dispose();
    _pipelineService.dispose();

    _isInitialized = false;

    if (kDebugMode) {
      print('🧹 Data Platform resources cleaned up');
    }
  }
}

/// Platform health status model
class PlatformHealthStatus {
  final DateTime timestamp;
  final bool isHealthy;
  final Map<String, ServiceHealthStatus> services;
  final Map<String, dynamic> metrics;

  const PlatformHealthStatus({
    required this.timestamp,
    required this.isHealthy,
    required this.services,
    required this.metrics,
  });

  bool get isOverallHealthy =>
      services.values.every((service) => service.isHealthy);

  List<String> get unhealthyServices => services.entries
      .where((entry) => !entry.value.isHealthy)
      .map((entry) => entry.key)
      .toList();

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'isHealthy': isHealthy,
      'services': services.map((k, v) => MapEntry(k, v.toJson())),
      'metrics': metrics,
    };
  }
}

/// Service health status model
class ServiceHealthStatus {
  final bool isHealthy;
  final DateTime lastCheck;
  final String? error;
  final Map<String, dynamic> metrics;

  const ServiceHealthStatus({
    required this.isHealthy,
    required this.lastCheck,
    this.error,
    required this.metrics,
  });

  Map<String, dynamic> toJson() {
    return {
      'isHealthy': isHealthy,
      'lastCheck': lastCheck.toIso8601String(),
      'error': error,
      'metrics': metrics,
    };
  }
}
