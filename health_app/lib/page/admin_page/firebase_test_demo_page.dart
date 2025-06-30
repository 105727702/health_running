import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../models/tracking_state.dart';
import '../../utils/firebase_utils.dart';
import '../../services/data_monitoring/firebase_analytics_service.dart';
import '../../services/data_monitoring/firebase_crashlytics_service.dart';
import '../../services/data_manage/firebase_services_manager.dart';

class FirebaseTestPage extends StatefulWidget {
  const FirebaseTestPage({super.key});

  @override
  State<FirebaseTestPage> createState() => _FirebaseTestPageState();
}

class _FirebaseTestPageState extends State<FirebaseTestPage> {
  TrackingState _trackingState = TrackingState();
  bool _isLoading = false;
  String _lastAction = '';
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    FirebaseUtils.trackNavigation('firebase_test_page');
    _addLog('🔥 Firebase Test Page initialized');
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(
        0,
        '${DateTime.now().toLocal().toString().substring(11, 19)} - $message',
      );
      if (_logs.length > 20) {
        _logs.removeLast();
      }
    });
  }

  void _setLoading(bool loading, String action) {
    setState(() {
      _isLoading = loading;
      _lastAction = action;
    });
  }

  // Test Analytics
  Future<void> _testAnalytics() async {
    _setLoading(true, 'Testing Analytics...');
    _addLog('📊 Testing Firebase Analytics');

    try {
      // Test screen view
      await FirebaseUtils.trackNavigation('test_screen');
      _addLog('✅ Screen view tracked');

      // Test button tap
      await FirebaseUtils.trackButtonTap(
        'test_button',
        screenName: 'firebase_test',
      );
      _addLog('✅ Button tap tracked');

      // Test custom event
      await FirebaseAnalyticsService.logEvent(
        name: 'test_custom_event',
        parameters: {
          'test_parameter': 'test_value',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      _addLog('✅ Custom event logged');

      // Test user properties
      await FirebaseAnalyticsService.setUserProperty(
        name: 'test_user_type',
        value: 'firebase_tester',
      );
      _addLog('✅ User property set');

      _addLog('🎉 Analytics test completed successfully!');
    } catch (e) {
      _addLog('❌ Analytics test failed: $e');
    } finally {
      _setLoading(false, '');
    }
  }

  // Test Crashlytics
  Future<void> _testCrashlytics() async {
    _setLoading(true, 'Testing Crashlytics...');
    _addLog('💥 Testing Firebase Crashlytics');

    try {
      // Test custom message
      await FirebaseUtils.logCustomMessage(
        'Testing Crashlytics from Firebase Test Page',
      );
      _addLog('✅ Custom message logged');

      // Test custom keys
      await FirebaseCrashlyticsService.setCustomKey('test_key', 'test_value');
      await FirebaseCrashlyticsService.setCustomKey(
        'user_action',
        'testing_crashlytics',
      );
      _addLog('✅ Custom keys set');

      // Test non-fatal error
      await FirebaseUtils.logNonFatalError(
        Exception('Test non-fatal error'),
        StackTrace.current,
        context: 'Testing Crashlytics functionality',
        screenName: 'firebase_test_page',
        additionalInfo: {
          'test_type': 'non_fatal_error',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      _addLog('✅ Non-fatal error logged');

      // Test user action logging
      await FirebaseCrashlyticsService.logUserAction(
        'test_action',
        context: {
          'screen': 'firebase_test_page',
          'feature': 'crashlytics_testing',
        },
      );
      _addLog('✅ User action logged');

      _addLog('🎉 Crashlytics test completed successfully!');
    } catch (e) {
      _addLog('❌ Crashlytics test failed: $e');
    } finally {
      _setLoading(false, '');
    }
  }

  // Test Performance
  Future<void> _testPerformance() async {
    _setLoading(true, 'Testing Performance...');
    _addLog('⚡ Testing Firebase Performance');

    try {
      // Test simple async operation
      await FirebaseUtils.trackAsyncOperation(
        'test_async_operation',
        () async {
          await Future.delayed(const Duration(milliseconds: 500));
          return 'Test completed';
        },
        attributes: {'operation_type': 'test', 'screen': 'firebase_test_page'},
      );
      _addLog('✅ Async operation tracked');

      // Test auth operation simulation
      await FirebaseUtils.trackAuthOperation('test_auth', () async {
        await Future.delayed(const Duration(milliseconds: 300));
        return 'Auth test completed';
      }, method: 'test_method');
      _addLog('✅ Auth operation tracked');

      // Test location operation simulation
      await FirebaseUtils.trackLocationOperation('test_location', () async {
        await Future.delayed(const Duration(milliseconds: 200));
        return 'Location test completed';
      }, accuracy: 'high');
      _addLog('✅ Location operation tracked');

      // Test database operation simulation
      await FirebaseUtils.trackDatabaseOperation('test_database', () async {
        await Future.delayed(const Duration(milliseconds: 400));
        return 'Database test completed';
      }, collection: 'test_collection');
      _addLog('✅ Database operation tracked');

      _addLog('🎉 Performance test completed successfully!');
    } catch (e) {
      _addLog('❌ Performance test failed: $e');
    } finally {
      _setLoading(false, '');
    }
  }

  // Test Tracking State with Firebase
  Future<void> _testTrackingState() async {
    _setLoading(true, 'Testing Tracking State...');
    _addLog('🏃 Testing TrackingState with Firebase');

    try {
      // Start tracking
      _trackingState = _trackingState.startTracking();
      _addLog('✅ Tracking started');

      // Simulate adding positions
      final positions = [
        LatLng(21.0285, 105.8542), // Hanoi
        LatLng(21.0295, 105.8552), // Slightly moved
        LatLng(21.0305, 105.8562), // Further moved
      ];

      for (int i = 0; i < positions.length; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        _trackingState = await _trackingState.addPosition(positions[i]);
        _addLog(
          '✅ Position ${i + 1} added: ${positions[i].latitude.toStringAsFixed(4)}, ${positions[i].longitude.toStringAsFixed(4)}',
        );
      }

      // Stop tracking
      _trackingState = _trackingState.stopTracking();
      _addLog('✅ Tracking stopped');

      // Log workout summary
      final summary = _trackingState.getWorkoutSummary();
      _addLog('📊 Workout Summary: ${summary.toString()}');

      _addLog('🎉 TrackingState test completed successfully!');
    } catch (e) {
      _addLog('❌ TrackingState test failed: $e');
      await FirebaseUtils.logNonFatalError(
        e,
        StackTrace.current,
        context: 'TrackingState test error',
        screenName: 'firebase_test_page',
      );
    } finally {
      _setLoading(false, '');
    }
  }

  // Test error simulation
  Future<void> _testErrorSimulation() async {
    _setLoading(true, 'Testing Error Simulation...');
    _addLog('🔥 Testing Error Handling');

    try {
      // Simulate different types of errors
      await FirebaseServicesManager.handleError(
        error: Exception('Simulated network error'),
        stackTrace: StackTrace.current,
        errorType: 'network_error',
        screenName: 'firebase_test_page',
        context: {'error_simulation': 'true', 'test_type': 'network_timeout'},
      );
      _addLog('✅ Network error simulated and logged');

      await FirebaseServicesManager.handleError(
        error: Exception('Simulated auth error'),
        stackTrace: StackTrace.current,
        errorType: 'auth_error',
        screenName: 'firebase_test_page',
        context: {'error_simulation': 'true', 'test_type': 'auth_failure'},
      );
      _addLog('✅ Auth error simulated and logged');

      _addLog('🎉 Error simulation completed successfully!');
    } catch (e) {
      _addLog('❌ Error simulation failed: $e');
    } finally {
      _setLoading(false, '');
    }
  }

  // Test all services
  Future<void> _testAllServices() async {
    _addLog('🚀 Starting comprehensive Firebase test...');
    await _testAnalytics();
    await Future.delayed(const Duration(milliseconds: 500));
    await _testCrashlytics();
    await Future.delayed(const Duration(milliseconds: 500));
    await _testPerformance();
    await Future.delayed(const Duration(milliseconds: 500));
    await _testTrackingState();
    await Future.delayed(const Duration(milliseconds: 500));
    await _testErrorSimulation();
    _addLog('🎉 All Firebase services tested successfully!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Services Test'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Status Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Firebase Services Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Initialized: ${FirebaseUtils.isInitialized ? '✅' : '❌'}',
                    ),
                    if (_isLoading) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(_lastAction),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testAnalytics,
                  icon: const Icon(Icons.analytics),
                  label: const Text('Test Analytics'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testCrashlytics,
                  icon: const Icon(Icons.bug_report),
                  label: const Text('Test Crashlytics'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testPerformance,
                  icon: const Icon(Icons.speed),
                  label: const Text('Test Performance'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testTrackingState,
                  icon: const Icon(Icons.directions_run),
                  label: const Text('Test Tracking'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testErrorSimulation,
                  icon: const Icon(Icons.error),
                  label: const Text('Test Errors'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testAllServices,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Test All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Logs
            Expanded(
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Test Logs',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _logs.clear();
                              });
                            },
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _logs.isEmpty
                          ? const Center(
                              child: Text(
                                'No logs yet. Run some tests to see results!',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _logs.length,
                              itemBuilder: (context, index) {
                                final log = _logs[index];
                                Color textColor = Colors.black87;
                                if (log.contains('❌')) {
                                  textColor = Colors.red;
                                } else if (log.contains('✅')) {
                                  textColor = Colors.green;
                                } else if (log.contains('🎉')) {
                                  textColor = Colors.blue;
                                }

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 4.0,
                                  ),
                                  child: Text(
                                    log,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
