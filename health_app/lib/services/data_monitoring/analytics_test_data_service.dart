import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../authen_service/role_service.dart';

class AnalyticsTestDataService {
  static final AnalyticsTestDataService _instance =
      AnalyticsTestDataService._internal();
  factory AnalyticsTestDataService() => _instance;
  AnalyticsTestDataService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate mock data for testing
  Future<void> generateTestData() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Check if user is admin
    final role = await RoleService().getCurrentUserRole();
    if (role != UserRole.admin) {
      throw Exception('Only admins can generate test data');
    }

    try {
      await _generateMockUsers();
      await _generateMockWorkoutSessions();
      await _generateMockAppEvents();
      await _generateMockCrashReports();
      print('✅ Test data generated successfully');
    } catch (e) {
      print('❌ Error generating test data: $e');
      throw e;
    }
  }

  Future<void> _generateMockUsers() async {
    final mockUsers = [
      {
        'email': 'user1@test.com',
        'displayName': 'Alice Johnson',
        'createdAt': _randomDate(days: 45),
        'lastActive': _randomDate(days: 2),
      },
      {
        'email': 'user2@test.com',
        'displayName': 'Bob Smith',
        'createdAt': _randomDate(days: 30),
        'lastActive': _randomDate(days: 1),
      },
      {
        'email': 'user3@test.com',
        'displayName': 'Carol Davis',
        'createdAt': _randomDate(days: 60),
        'lastActive': _randomDate(days: 5),
      },
      {
        'email': 'user4@test.com',
        'displayName': 'David Wilson',
        'createdAt': _randomDate(days: 15),
        'lastActive': _randomDate(days: 0),
      },
      {
        'email': 'user5@test.com',
        'displayName': 'Eva Brown',
        'createdAt': _randomDate(days: 90),
        'lastActive': _randomDate(days: 3),
      },
    ];

    final batch = _firestore.batch();

    for (int i = 0; i < mockUsers.length; i++) {
      final userId = 'mock_user_$i';
      final userRef = _firestore.collection('users').doc(userId);
      batch.set(userRef, mockUsers[i]);
    }

    await batch.commit();
    print('✅ Generated ${mockUsers.length} mock users');
  }

  Future<void> _generateMockWorkoutSessions() async {
    final mockSessions = <Map<String, dynamic>>[];

    // Generate sessions for the last 30 days
    for (int day = 0; day < 30; day++) {
      final date = DateTime.now().subtract(Duration(days: day));
      final sessionsPerDay = _randomInt(0, 5); // 0-4 sessions per day

      for (int session = 0; session < sessionsPerDay; session++) {
        final userId = 'mock_user_${_randomInt(0, 5)}'; // 0-4 users
        final workoutTypes = ['running', 'walking', 'cycling'];
        mockSessions.add({
          'userId': userId,
          'date': date,
          'distance': _randomDouble(1.0, 15.0), // 1-15 km
          'duration': _randomDouble(300, 3600), // 5-60 minutes in seconds
          'calories': _randomDouble(100, 800), // 100-800 calories
          'type': workoutTypes[_randomInt(0, workoutTypes.length)],
          'createdAt': date,
        });
      }
    }

    final batch = _firestore.batch();

    for (int i = 0; i < mockSessions.length; i++) {
      final sessionRef = _firestore.collection('workout_sessions').doc();
      batch.set(sessionRef, mockSessions[i]);
    }

    await batch.commit();
    print('✅ Generated ${mockSessions.length} mock workout sessions');
  }

  Future<void> _generateMockAppEvents() async {
    final eventTypes = [
      'screen_view',
      'button_tap',
      'workout_start',
      'workout_end',
      'login',
      'logout',
      'settings_opened',
      'profile_updated',
    ];

    final screenNames = [
      'main_screen',
      'workout_page',
      'profile_page',
      'settings_page',
      'login_screen',
      'map_page',
    ];

    final mockEvents = <Map<String, dynamic>>[];

    // Generate events for the last 7 days
    for (int day = 0; day < 7; day++) {
      final date = DateTime.now().subtract(Duration(days: day));
      final eventsPerDay = _randomInt(10, 50);

      for (int event = 0; event < eventsPerDay; event++) {
        final userId = 'mock_user_${_randomInt(0, 5)}';
        final eventTime = date.add(
          Duration(hours: _randomInt(6, 23), minutes: _randomInt(0, 59)),
        );

        mockEvents.add({
          'event_name': eventTypes[_randomInt(0, eventTypes.length)],
          'screen_name': screenNames[_randomInt(0, screenNames.length)],
          'user_id': userId,
          'user_email': 'user${_randomInt(1, 6)}@test.com',
          'parameters': {'source': 'mobile_app', 'platform': 'android'},
          'timestamp': eventTime,
        });
      }
    }

    final batch = _firestore.batch();

    for (int i = 0; i < mockEvents.length; i++) {
      final eventRef = _firestore.collection('app_events').doc();
      batch.set(eventRef, mockEvents[i]);
    }

    await batch.commit();
    print('✅ Generated ${mockEvents.length} mock app events');
  }

  Future<void> _generateMockCrashReports() async {
    final crashTypes = [
      'NullPointerException',
      'IndexOutOfBoundsException',
      'NetworkException',
      'DatabaseException',
      'PermissionException',
    ];

    final screenNames = [
      'workout_page',
      'map_page',
      'profile_page',
      'settings_page',
      'login_screen',
    ];

    final mockCrashes = <Map<String, dynamic>>[];

    // Generate some crashes for the last 30 days
    for (int day = 0; day < 30; day++) {
      if (_randomInt(0, 10) < 3) {
        // 30% chance of crash on any day
        final date = DateTime.now().subtract(Duration(days: day));
        final crashTime = date.add(
          Duration(hours: _randomInt(6, 23), minutes: _randomInt(0, 59)),
        );

        mockCrashes.add({
          'error_type': crashTypes[_randomInt(0, crashTypes.length)],
          'screen_name': screenNames[_randomInt(0, screenNames.length)],
          'user_id': 'mock_user_${_randomInt(0, 5)}',
          'error_message': 'Mock crash report for testing',
          'stack_trace': 'Mock stack trace...',
          'timestamp': crashTime,
          'app_version': '1.0.0',
          'platform': 'android',
        });
      }
    }

    if (mockCrashes.isNotEmpty) {
      final batch = _firestore.batch();

      for (int i = 0; i < mockCrashes.length; i++) {
        final crashRef = _firestore.collection('crash_reports').doc();
        batch.set(crashRef, mockCrashes[i]);
      }

      await batch.commit();
      print('✅ Generated ${mockCrashes.length} mock crash reports');
    }
  }

  // Clear all test data
  Future<void> clearTestData() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Check if user is admin
    final role = await RoleService().getCurrentUserRole();
    if (role != UserRole.admin) {
      throw Exception('Only admins can clear test data');
    }

    try {
      await _clearCollection('users', startsWith: 'mock_user_');
      await _clearCollection(
        'workout_sessions',
        userIdStartsWith: 'mock_user_',
      );
      await _clearCollection('app_events', userIdStartsWith: 'mock_user_');
      await _clearCollection('crash_reports', userIdStartsWith: 'mock_user_');
      print('✅ Test data cleared successfully');
    } catch (e) {
      print('❌ Error clearing test data: $e');
      throw e;
    }
  }

  Future<void> _clearCollection(
    String collectionName, {
    String? startsWith,
    String? userIdStartsWith,
  }) async {
    Query query = _firestore.collection(collectionName);

    if (userIdStartsWith != null) {
      query = query.where('userId', isGreaterThanOrEqualTo: userIdStartsWith);
    }

    final snapshot = await query.get();
    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      if (startsWith != null && !doc.id.startsWith(startsWith)) continue;
      if (userIdStartsWith != null) {
        final data = doc.data() as Map<String, dynamic>?;
        final userId = data?['userId'] as String?;
        if (userId == null || !userId.startsWith(userIdStartsWith)) continue;
      }

      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Helper methods
  DateTime _randomDate({required int days}) {
    final now = DateTime.now();
    final randomDays = _randomInt(0, days);
    return now.subtract(Duration(days: randomDays));
  }

  int _randomInt(int min, int max) {
    if (max <= min) return min; // Prevent division by zero
    final range = max - min;
    return min + (DateTime.now().millisecondsSinceEpoch % range);
  }

  double _randomDouble(double min, double max) {
    if (max <= min) return min; // Prevent invalid range
    final random = (DateTime.now().microsecondsSinceEpoch % 1000) / 1000.0;
    return min + (random * (max - min));
  }
}
