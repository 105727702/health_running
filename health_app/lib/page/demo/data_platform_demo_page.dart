import 'package:flutter/material.dart';
import '../../services/data_monitoring/data_platform_manager.dart';
import '../../models/data_platform_models.dart';

/// Demo page showing how to use the Comprehensive Data Platform
class DataPlatformDemoPage extends StatefulWidget {
  const DataPlatformDemoPage({super.key});

  @override
  State<DataPlatformDemoPage> createState() => _DataPlatformDemoPageState();
}

class _DataPlatformDemoPageState extends State<DataPlatformDemoPage> {
  final DataPlatformManager _dataPlatform = DataPlatformManager();
  AnalyticsSnapshot? _latestSnapshot;
  DataQualityMetrics? _latestQuality;
  PlatformHealthStatus? _healthStatus;

  @override
  void initState() {
    super.initState();
    _setupStreams();
  }

  void _setupStreams() {
    // Listen to real-time analytics
    _dataPlatform.analyticsStream.listen((snapshot) {
      if (mounted) {
        setState(() {
          _latestSnapshot = snapshot;
        });
      }
    });

    // Listen to quality metrics
    _dataPlatform.qualityStream.listen((quality) {
      if (mounted) {
        setState(() {
          _latestQuality = quality;
        });
      }
    });

    // Listen to platform health
    _dataPlatform.healthStream.listen((health) {
      if (mounted) {
        setState(() {
          _healthStatus = health;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Platform Demo'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlatformStatus(),
            const SizedBox(height: 20),
            _buildActionButtons(),
            const SizedBox(height: 20),
            _buildAnalyticsSnapshot(),
            const SizedBox(height: 20),
            _buildQualityMetrics(),
            const SizedBox(height: 20),
            _buildDemoDescription(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Platform Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  _dataPlatform.isHealthy ? Icons.check_circle : Icons.error,
                  color: _dataPlatform.isHealthy ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  _dataPlatform.isInitialized
                      ? (_dataPlatform.isHealthy ? 'Healthy' : 'Unhealthy')
                      : 'Not Initialized',
                  style: TextStyle(
                    color: _dataPlatform.isHealthy ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (_healthStatus != null) ...[
              const SizedBox(height: 10),
              Text(
                'Last Health Check: ${_formatTime(_healthStatus!.timestamp)}',
              ),
              if (_healthStatus!.unhealthyServices.isNotEmpty)
                Text(
                  'Unhealthy Services: ${_healthStatus!.unhealthyServices.join(', ')}',
                  style: const TextStyle(color: Colors.red),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Demo Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: _simulateHealthData,
                  icon: const Icon(Icons.health_and_safety),
                  label: const Text('Track Health'),
                ),
                ElevatedButton.icon(
                  onPressed: _simulateWorkoutEvent,
                  icon: const Icon(Icons.fitness_center),
                  label: const Text('Track Workout'),
                ),
                ElevatedButton.icon(
                  onPressed: _simulateUserBehavior,
                  icon: const Icon(Icons.person_outline),
                  label: const Text('Track Behavior'),
                ),
                ElevatedButton.icon(
                  onPressed: _generateSnapshot,
                  icon: const Icon(Icons.analytics),
                  label: const Text('Get Snapshot'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsSnapshot() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Real-time Analytics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (_latestSnapshot != null) ...[
              _buildMetricRow(
                'Active Users',
                _latestSnapshot!.activeUsers.toString(),
              ),
              _buildMetricRow(
                'Total Sessions',
                _latestSnapshot!.totalSessions.toString(),
              ),
              _buildMetricRow(
                'Last Update',
                _formatTime(_latestSnapshot!.timestamp),
              ),
              if (_latestSnapshot!.eventCounts.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text(
                  'Event Counts:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                ..._latestSnapshot!.eventCounts.entries.map(
                  (entry) =>
                      _buildMetricRow('  ${entry.key}', entry.value.toString()),
                ),
              ],
              if (_latestSnapshot!.topScreens.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text(
                  'Top Screens:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text('  ${_latestSnapshot!.topScreens.join(', ')}'),
              ],
            ] else
              const Text('No analytics data available'),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityMetrics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Quality Metrics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (_latestQuality != null) ...[
              _buildMetricRow('Data Source', _latestQuality!.dataSource),
              _buildMetricRow(
                'Total Records',
                _latestQuality!.totalRecords.toString(),
              ),
              _buildMetricRow(
                'Valid Records',
                _latestQuality!.validRecords.toString(),
              ),
              _buildMetricRow(
                'Invalid Records',
                _latestQuality!.invalidRecords.toString(),
              ),
              _buildMetricRow(
                'Completeness Score',
                '${(_latestQuality!.completenessScore * 100).toStringAsFixed(1)}%',
              ),
              _buildMetricRow(
                'Accuracy Score',
                '${(_latestQuality!.accuracyScore * 100).toStringAsFixed(1)}%',
              ),
              if (_latestQuality!.issues.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text(
                  'Issues:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                ..._latestQuality!.issues.map(
                  (issue) => Text(
                    '  • $issue',
                    style: const TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            ] else
              const Text('No quality metrics available'),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoDescription() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comprehensive Data Platform Features',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              '🔄 Real-time Data Streaming\n'
              '📊 Advanced Analytics & ML Ready\n'
              '🔍 Data Quality Monitoring\n'
              '⚡ Event-driven Architecture\n'
              '📈 Batch & Stream Processing\n'
              '🏗️ Scalable Infrastructure\n'
              '💓 Health Monitoring\n'
              '🔐 Data Validation & Governance',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 15),
            const Text(
              'This comprehensive data platform extends your Firebase Analytics into a full-scale data engineering solution with real-time processing, quality monitoring, and advanced analytics capabilities.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }

  Future<void> _simulateHealthData() async {
    try {
      await _dataPlatform.trackHealthMetrics(
        userId: 'demo_user',
        heartRate: 75 + (DateTime.now().second % 20),
        steps: 1000 + (DateTime.now().second * 10),
        calories: 50 + (DateTime.now().second % 30),
        distance: 500 + (DateTime.now().second * 5),
        speed: 2.5 + (DateTime.now().second % 5),
        workoutType: 'running',
        location: {
          'latitude': 21.0285 + (DateTime.now().second * 0.001),
          'longitude': 105.8542 + (DateTime.now().second * 0.001),
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Health data tracked successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error tracking health data: $e')));
    }
  }

  Future<void> _simulateWorkoutEvent() async {
    try {
      await _dataPlatform.trackEvent(
        eventType: 'workout_completed',
        category: 'health',
        properties: {
          'workout_type': 'running',
          'duration': 1800 + (DateTime.now().second * 10),
          'distance': 3000 + (DateTime.now().second * 50),
          'calories': 200 + (DateTime.now().second % 50),
        },
        tags: ['demo', 'workout', 'running'],
        userId: 'demo_user',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workout event tracked successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error tracking workout event: $e')),
      );
    }
  }

  Future<void> _simulateUserBehavior() async {
    try {
      await _dataPlatform.trackUserBehavior(
        action: 'view_demo',
        screen: 'data_platform_demo',
        properties: {
          'demo_section': 'user_behavior',
          'timestamp': DateTime.now().toIso8601String(),
        },
        duration: 30 + (DateTime.now().second % 60),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User behavior tracked successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error tracking user behavior: $e')),
      );
    }
  }

  Future<void> _generateSnapshot() async {
    try {
      final snapshot = await _dataPlatform.getAnalyticsSnapshot();
      setState(() {
        _latestSnapshot = snapshot;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Analytics snapshot generated!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating snapshot: $e')));
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
