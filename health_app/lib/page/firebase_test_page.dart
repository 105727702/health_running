import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_data_service.dart';
import '../services/hybrid_data_service.dart';

class FirebaseTestPage extends StatefulWidget {
  const FirebaseTestPage({super.key});

  @override
  State<FirebaseTestPage> createState() => _FirebaseTestPageState();
}

class _FirebaseTestPageState extends State<FirebaseTestPage> {
  final FirebaseDataService _firebaseService = FirebaseDataService();
  final HybridDataService _hybridService = HybridDataService();
  bool _isLoading = false;
  String _status = 'Ready to test Firebase';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Test'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Status',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text('Signed in: ${user != null}'),
                    if (user != null) ...[
                      Text('UID: ${user.uid}'),
                      Text('Email: ${user.email ?? 'No email'}'),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Firebase Status',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Buttons
            Expanded(
              child: ListView(
                children: [
                  ElevatedButton.icon(
                    onPressed: _showCurrentData,
                    icon: const Icon(Icons.info),
                    label: const Text('Show Current App Data'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: user == null ? null : _testSaveSession,
                    child: const Text('Test Save Session (Real Data)'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: user == null ? null : _testSaveDailySummary,
                    child: const Text('Test Save Daily Summary (Real Data)'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: user == null ? null : _testGetDailySessions,
                    child: const Text('Test Get Daily Sessions'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: user == null ? null : _testGetUserStatistics,
                    child: const Text('Test Get User Statistics'),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Instructions:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    '1. Make sure you are signed in\n'
                    '2. Run tests to create data\n'
                    '3. Check Firebase Console to see the data\n'
                    '4. Navigate to: users/{your-uid}/activities\n'
                    '5. Also check: users/{your-uid}/daily_summaries',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testSaveSession() async {
    setState(() {
      _isLoading = true;
      _status = 'Getting current app data and saving to Firebase...';
    });

    try {
      // Lấy dữ liệu thực tế từ hybrid service
      final dailyDistance = _hybridService.dailyDistance;
      final dailyCalories = _hybridService.dailyCalories;
      final dailySteps = _hybridService.dailySteps;

      // Tạo route mẫu dựa trên dữ liệu thực tế (giả lập)
      final routePoints = <Map<String, dynamic>>[];
      if (dailyDistance > 0) {
        // Tạo route points dựa trên khoảng cách thực tế
        final numPoints = (dailyDistance * 4).round().clamp(2, 20); // 4 điểm/km
        for (int i = 0; i < numPoints; i++) {
          routePoints.add({
            'latitude': 10.762622 + (i * 0.001), // Tọa độ TP.HCM với offset nhỏ
            'longitude': 106.660172 + (i * 0.001),
          });
        }
      } else {
        // Nếu chưa có dữ liệu, tạo route mẫu ngắn
        routePoints.addAll([
          {'latitude': 10.762622, 'longitude': 106.660172},
          {'latitude': 10.762722, 'longitude': 106.660272},
        ]);
      }

      await _firebaseService.saveTrackingSession(
        distance: dailyDistance > 0 ? dailyDistance : 1.5,
        calories: dailyCalories > 0 ? dailyCalories : 120,
        duration: dailyDistance > 0
            ? (dailyDistance * 12).round()
            : 18, // ~12 phút/km
        activityType: 'walking',
        startTime: DateTime.now().subtract(
          Duration(
            minutes: dailyDistance > 0 ? (dailyDistance * 12).round() : 18,
          ),
        ),
        endTime: DateTime.now(),
        route: routePoints,
      );

      setState(() {
        _status =
            'Session saved successfully!\n'
            'Distance: ${dailyDistance > 0 ? dailyDistance.toStringAsFixed(2) : '1.50'} km\n'
            'Calories: ${dailyCalories > 0 ? dailyCalories.round() : 120}\n'
            'Steps: $dailySteps\n'
            'Route points: ${routePoints.length}\n\n'
            'Check Firebase Console -> users/{your-uid}/activities';
      });
    } catch (e) {
      setState(() {
        _status = 'Error saving session: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testSaveDailySummary() async {
    setState(() {
      _isLoading = true;
      _status = 'Getting current daily data and saving to Firebase...';
    });

    try {
      // Lấy dữ liệu thực tế từ hybrid service
      final dailyDistance = _hybridService.dailyDistance;
      final dailyCalories = _hybridService.dailyCalories;
      final dailySteps = _hybridService.dailySteps;
      final todaySessions = _hybridService.todaySessions;

      await _firebaseService.saveDailySummary(
        date: DateTime.now(),
        totalDistance: dailyDistance,
        totalCalories: dailyCalories,
        totalSteps: dailySteps,
        sessionCount: todaySessions.length,
      );

      setState(() {
        _status =
            'Daily summary saved!\n'
            'Distance: ${dailyDistance.toStringAsFixed(2)} km\n'
            'Calories: ${dailyCalories.round()}\n'
            'Steps: $dailySteps\n'
            'Sessions: ${todaySessions.length}\n\n'
            'Check Firebase Console -> users/{your-uid}/daily_summaries';
      });
    } catch (e) {
      setState(() {
        _status = 'Error saving daily summary: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testGetDailySessions() async {
    setState(() {
      _isLoading = true;
      _status = 'Getting daily sessions from Firebase...';
    });

    try {
      final sessions = await _firebaseService.getDailySessions(DateTime.now());

      setState(() {
        _status = 'Found ${sessions.length} sessions for today';
      });
    } catch (e) {
      setState(() {
        _status = 'Error getting daily sessions: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testGetUserStatistics() async {
    setState(() {
      _isLoading = true;
      _status = 'Getting user statistics from Firebase...';
    });

    try {
      final stats = await _firebaseService.getUserStatistics();

      setState(() {
        _status = 'Stats: ${stats.toString()}';
      });
    } catch (e) {
      setState(() {
        _status = 'Error getting user statistics: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showCurrentData() {
    final dailyDistance = _hybridService.dailyDistance;
    final dailyCalories = _hybridService.dailyCalories;
    final dailySteps = _hybridService.dailySteps;
    final todaySessions = _hybridService.todaySessions;

    setState(() {
      _status =
          'Current App Data:\n'
          '📏 Distance: ${dailyDistance.toStringAsFixed(2)} km\n'
          '🔥 Calories: ${dailyCalories.round()}\n'
          '👣 Steps: $dailySteps\n'
          '📊 Sessions today: ${todaySessions.length}\n\n'
          'This data will be used when you test Firebase save functions.';
    });
  }
}
