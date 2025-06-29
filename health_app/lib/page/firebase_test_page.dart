import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_data_service.dart';

class FirebaseTestPage extends StatefulWidget {
  const FirebaseTestPage({super.key});

  @override
  State<FirebaseTestPage> createState() => _FirebaseTestPageState();
}

class _FirebaseTestPageState extends State<FirebaseTestPage> {
  final FirebaseDataService _firebaseService = FirebaseDataService();
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
                  ElevatedButton(
                    onPressed: user == null ? null : _testSaveSession,
                    child: const Text('Test Save Session'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: user == null ? null : _testSaveDailySummary,
                    child: const Text('Test Save Daily Summary'),
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
      _status = 'Saving session to Firebase...';
    });

    try {
      await _firebaseService.saveTrackingSession(
        distance: 2.5,
        calories: 150,
        duration: 30,
        activityType: 'walking',
        startTime: DateTime.now().subtract(const Duration(minutes: 30)),
        endTime: DateTime.now(),
        route: [
          {'latitude': 10.762622, 'longitude': 106.660172},
          {'latitude': 10.762722, 'longitude': 106.660272},
        ],
      );

      setState(() {
        _status =
            'Session saved successfully! Check Firebase Console -> users/{your-uid}/activities';
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
      _status = 'Saving daily summary to Firebase...';
    });

    try {
      await _firebaseService.saveDailySummary(
        date: DateTime.now(),
        totalDistance: 2.5,
        totalCalories: 150,
        totalSteps: 3250,
        sessionCount: 1,
      );

      setState(() {
        _status =
            'Daily summary saved! Check Firebase Console -> users/{your-uid}/daily_summaries';
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
}
