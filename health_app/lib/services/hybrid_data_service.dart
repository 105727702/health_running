import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tracking_state.dart';
import '../models/user_goals.dart';
import 'firebase_data_service.dart';

class HybridDataService {
  static final HybridDataService _instance = HybridDataService._internal();
  factory HybridDataService() => _instance;

  late final Future<void> _initializationFuture;

  HybridDataService._internal() {
    _initializationFuture = _initializeService();
  }

  // Services
  final FirebaseDataService _firebaseService = FirebaseDataService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get initialization future
  Future<void> get initialized => _initializationFuture;

  // Initialize service
  Future<void> _initializeService() async {
    await _loadLocalData();
    _checkAndResetDailyData();
    _startDailyResetTimer();
    _setupAuthListener();
  }

  // Stream controllers
  final StreamController<TrackingState> _trackingStateController =
      StreamController<TrackingState>.broadcast();
  final StreamController<bool> _dataChangeController =
      StreamController<bool>.broadcast();

  // Local data (stored in SharedPreferences)
  TrackingState _currentState = TrackingState();
  double _dailyDistance = 0.0;
  double _dailyCalories = 0.0;
  int _dailySteps = 0;
  List<TrackingSession> _todaySessions = [];
  UserGoals _userGoals = UserGoals();
  String _lastResetDate = "";
  Timer? _dailyResetTimer;

  // Offline sessions queue (to sync when online)
  List<Map<String, dynamic>> _offlineSessionsQueue = [];

  // Getters
  Stream<TrackingState> get trackingStateStream =>
      _trackingStateController.stream;
  Stream<bool> get dataChangeStream => _dataChangeController.stream;
  TrackingState get currentState => _currentState;
  double get dailyDistance => _dailyDistance;
  double get dailyCalories => _dailyCalories;
  int get dailySteps => _dailySteps;
  List<TrackingSession> get todaySessions => _todaySessions;
  UserGoals get userGoals => _userGoals;

  // Setup auth listener for sync
  void _setupAuthListener() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // User signed in - sync offline data
        _syncOfflineData();
      }
    });
  }

  // Update tracking state
  void updateTrackingState(TrackingState newState) {
    _currentState = newState;
    _trackingStateController.add(newState);

    if (newState.isTracking) {
      _updateDailyTotals(newState);
    }
  }

  // Save session (both local and Firebase)
  Future<void> saveSession(TrackingState finalState) async {
    if (finalState.totalDistance > 0) {
      final session = TrackingSession(
        distance: finalState.totalDistance,
        calories: finalState.totalCalories,
        duration: 30, // Should be calculated from actual tracking time
        activityType: finalState.activityType,
        startTime: DateTime.now().subtract(const Duration(minutes: 30)),
        endTime: DateTime.now(),
        route: finalState.route,
      );

      // Always save locally first
      _todaySessions.add(session);
      _updateDailyTotals(finalState);
      await _saveLocalData();

      // Try to save to Firebase if user is authenticated
      final user = _auth.currentUser;
      if (user != null) {
        try {
          await _firebaseService.saveTrackingSession(
            distance: session.distance,
            calories: session.calories,
            duration: session.duration,
            activityType: session.activityType,
            startTime: session.startTime,
            endTime: session.endTime,
            route: session.route,
          );

          // Also save daily summary to Firebase
          await _firebaseService.saveDailySummary(
            date: DateTime.now(),
            totalDistance: _dailyDistance,
            totalCalories: _dailyCalories,
            totalSteps: _dailySteps,
            sessionCount: _todaySessions.length,
          );
        } catch (e) {
          print('Failed to save to Firebase, adding to offline queue: $e');
          // Add to offline queue for later sync
          _offlineSessionsQueue.add(session.toJson());
          await _saveOfflineQueue();
        }
      } else {
        // User not authenticated, add to offline queue
        _offlineSessionsQueue.add(session.toJson());
        await _saveOfflineQueue();
      }

      _dataChangeController.add(true);
    }
  }

  // Get historical data (combine local and Firebase)
  Future<Map<String, DailySummary>> getHistoricalData() async {
    Map<String, DailySummary> combinedData = {};

    // Load local data first
    await _loadLocalHistoricalData();
    combinedData.addAll(_historicalData);

    // If user is authenticated, try to get Firebase data
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final now = DateTime.now();
        final thirtyDaysAgo = now.subtract(const Duration(days: 30));

        final firebaseSessions = await _firebaseService.getWeeklySessions(
          startDate: thirtyDaysAgo,
          endDate: now,
        );

        // Group Firebase sessions by date and merge with local data
        for (final sessionData in firebaseSessions) {
          final date = sessionData['date'] as String;

          if (combinedData.containsKey(date)) {
            // Merge with existing local data
            final existing = combinedData[date]!;
            final distance =
                existing.totalDistance +
                (sessionData['distance'] ?? 0).toDouble();
            final calories =
                existing.totalCalories +
                (sessionData['calories'] ?? 0).toDouble();
            final steps =
                existing.totalSteps +
                ((sessionData['distance'] ?? 0).toDouble() * 1300).round();

            combinedData[date] = DailySummary(
              date: date,
              totalDistance: distance,
              totalCalories: calories,
              totalSteps: steps.round(),
              sessionCount: existing.sessionCount + 1,
              sessions: [
                ...existing.sessions,
                TrackingSession.fromJson(sessionData),
              ],
            );
          } else {
            // Create new entry from Firebase data
            combinedData[date] = DailySummary(
              date: date,
              totalDistance: (sessionData['distance'] ?? 0).toDouble(),
              totalCalories: (sessionData['calories'] ?? 0).toDouble(),
              totalSteps: ((sessionData['distance'] ?? 0).toDouble() * 1300)
                  .round(),
              sessionCount: 1,
              sessions: [TrackingSession.fromJson(sessionData)],
            );
          }
        }
      } catch (e) {
        print('Error loading Firebase historical data: $e');
        // Continue with local data only
      }
    }

    return combinedData;
  }

  // Get weekly summary (combine local and Firebase)
  Future<WeeklySummary> getWeeklySummary() async {
    final now = DateTime.now();
    double totalDistance = _dailyDistance;
    double totalCalories = _dailyCalories;
    double totalStepsDouble = _dailySteps.toDouble();
    int activeDays = _todaySessions.isNotEmpty ? 1 : 0;

    // Get historical data (already combines local and Firebase)
    final historicalData = await getHistoricalData();

    // Add data from last 6 days
    for (int i = 1; i <= 6; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = _formatDate(date);
      final dayData = historicalData[dateKey];

      if (dayData != null) {
        totalDistance += dayData.totalDistance;
        totalCalories += dayData.totalCalories;
        totalStepsDouble += dayData.totalSteps.toDouble();
        if (dayData.sessionCount > 0) activeDays++;
      }
    }

    return WeeklySummary(
      totalDistance: totalDistance,
      totalCalories: totalCalories,
      totalSteps: totalStepsDouble.round(),
      activeDays: activeDays,
      averageDistance: totalDistance / 7,
      averageCalories: totalCalories / 7,
    );
  }

  // Sync offline data to Firebase
  Future<void> _syncOfflineData() async {
    if (_offlineSessionsQueue.isNotEmpty) {
      try {
        await _firebaseService.syncOfflineData(_offlineSessionsQueue);
        _offlineSessionsQueue.clear();
        await _saveOfflineQueue();
        print('Offline data synced successfully');
      } catch (e) {
        print('Error syncing offline data: $e');
      }
    }
  }

  // Goals management (stored locally)
  Future<void> updateUserGoals(UserGoals newGoals) async {
    _userGoals = newGoals;
    await _saveGoals();
    _trackingStateController.add(_currentState);
  }

  Future<void> updateDailyGoals({
    double? distanceGoal,
    double? caloriesGoal,
    int? stepsGoal,
  }) async {
    _userGoals = _userGoals.copyWith(
      dailyDistanceGoal: distanceGoal,
      dailyCaloriesGoal: caloriesGoal,
      dailyStepsGoal: stepsGoal,
    );
    await _saveGoals();
    _trackingStateController.add(_currentState);
  }

  Future<void> updateWeeklyGoals({
    double? distanceGoal,
    double? caloriesGoal,
    int? stepsGoal,
    int? activeDaysGoal,
  }) async {
    _userGoals = _userGoals.copyWith(
      weeklyDistanceGoal: distanceGoal,
      weeklyCaloriesGoal: caloriesGoal,
      weeklyStepsGoal: stepsGoal,
      weeklyActiveDaysGoal: activeDaysGoal,
    );
    await _saveGoals();
    _trackingStateController.add(_currentState);
  }

  // Data management methods
  Future<void> clearTodayData() async {
    try {
      _todaySessions.clear();
      _dailyDistance = 0.0;
      _dailyCalories = 0.0;
      _dailySteps = 0;
      _currentState = TrackingState();

      await _saveLocalData();
      _trackingStateController.add(_currentState);
      _dataChangeController.add(true);

      print('Today\'s data cleared successfully');
    } catch (e) {
      print('Error clearing today\'s data: $e');
      throw Exception('Failed to clear today\'s data');
    }
  }

  Future<void> clearAllData() async {
    try {
      // Clear local data
      _historicalData.clear();
      _todaySessions.clear();
      _dailyDistance = 0.0;
      _dailyCalories = 0.0;
      _dailySteps = 0;
      _currentState = TrackingState();
      _offlineSessionsQueue.clear();

      await _saveLocalData();
      await _saveOfflineQueue();

      // Clear Firebase data if user is authenticated
      final user = _auth.currentUser;
      if (user != null) {
        try {
          await _firebaseService.clearAllUserData();
        } catch (e) {
          print('Error clearing Firebase data: $e');
          // Continue even if Firebase clear fails
        }
      }

      _trackingStateController.add(_currentState);
      _dataChangeController.add(true);

      print('All data cleared successfully');
    } catch (e) {
      print('Error clearing all data: $e');
      throw Exception('Failed to clear all data');
    }
  }

  // Private methods
  Map<String, DailySummary> _historicalData = {};

  void _updateDailyTotals(TrackingState state) {
    _dailyDistance = state.totalDistance;
    _dailyCalories = state.totalCalories;
    _dailySteps = (_dailyDistance * 1300).round();
  }

  void _updateDailyTotalsFromSessions() {
    _dailyDistance = _todaySessions.fold(
      0.0,
      (sum, session) => sum + session.distance,
    );
    _dailyCalories = _todaySessions.fold(
      0.0,
      (sum, session) => sum + session.calories,
    );
    _dailySteps = (_dailyDistance * 1300).round();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _checkAndResetDailyData() {
    final today = _formatDate(DateTime.now());
    if (_lastResetDate != today) {
      _performDailyReset();
    }
  }

  void _performDailyReset() {
    final yesterday = _formatDate(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    // Save yesterday's data to history
    if (_dailyDistance > 0 || _todaySessions.isNotEmpty) {
      _historicalData[yesterday] = DailySummary(
        date: yesterday,
        totalDistance: _dailyDistance,
        totalCalories: _dailyCalories,
        totalSteps: _dailySteps,
        sessionCount: _todaySessions.length,
        sessions: List.from(_todaySessions),
      );
    }

    // Reset today's data
    _dailyDistance = 0.0;
    _dailyCalories = 0.0;
    _dailySteps = 0;
    _todaySessions.clear();
    _lastResetDate = _formatDate(DateTime.now());

    _saveLocalData();
    print('Daily data reset completed for ${DateTime.now()}');
  }

  void _startDailyResetTimer() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);

    _dailyResetTimer = Timer(timeUntilMidnight, () {
      _performDailyReset();
      _dailyResetTimer = Timer.periodic(const Duration(days: 1), (timer) {
        _performDailyReset();
      });
    });
  }

  // Local data storage methods
  Future<void> _loadLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load basic daily data
      _dailyDistance = prefs.getDouble('daily_distance') ?? 0.0;
      _dailyCalories = prefs.getDouble('daily_calories') ?? 0.0;
      _dailySteps = prefs.getInt('daily_steps') ?? 0;
      _lastResetDate =
          prefs.getString('last_reset_date') ?? _formatDate(DateTime.now());

      // Load today's sessions
      final String? todaySessionsJson = prefs.getString('today_sessions');
      if (todaySessionsJson != null) {
        final List<dynamic> sessionsData = jsonDecode(todaySessionsJson);
        _todaySessions = sessionsData
            .map((json) => TrackingSession.fromJson(json))
            .toList();
        _updateDailyTotalsFromSessions();
      }

      // Load offline queue
      final String? offlineQueueJson = prefs.getString(
        'offline_sessions_queue',
      );
      if (offlineQueueJson != null) {
        final List<dynamic> queueData = jsonDecode(offlineQueueJson);
        _offlineSessionsQueue = queueData.cast<Map<String, dynamic>>();
      }

      // Load goals
      await _loadGoals();
    } catch (e) {
      print('Error loading local data: $e');
      _loadMockData();
    }
  }

  Future<void> _loadLocalHistoricalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historicalJson = prefs.getString('historical_data');
      if (historicalJson != null) {
        final Map<String, dynamic> data = jsonDecode(historicalJson);
        _historicalData = data.map(
          (key, value) => MapEntry(key, DailySummary.fromJson(value)),
        );
      }
    } catch (e) {
      print('Error loading local historical data: $e');
    }
  }

  Future<void> _saveLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save basic daily data
      await prefs.setDouble('daily_distance', _dailyDistance);
      await prefs.setDouble('daily_calories', _dailyCalories);
      await prefs.setInt('daily_steps', _dailySteps);
      await prefs.setString('last_reset_date', _lastResetDate);

      // Save historical data
      final historicalJson = jsonEncode(
        _historicalData.map((key, value) => MapEntry(key, value.toJson())),
      );
      await prefs.setString('historical_data', historicalJson);

      // Save today's sessions
      final todaySessionsJson = jsonEncode(
        _todaySessions.map((session) => session.toJson()).toList(),
      );
      await prefs.setString('today_sessions', todaySessionsJson);
    } catch (e) {
      print('Error saving local data: $e');
    }
  }

  Future<void> _saveOfflineQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = jsonEncode(_offlineSessionsQueue);
      await prefs.setString('offline_sessions_queue', queueJson);
    } catch (e) {
      print('Error saving offline queue: $e');
    }
  }

  Future<void> _saveGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_goals', jsonEncode(_userGoals.toJson()));
    } catch (e) {
      print('Error saving goals: $e');
    }
  }

  Future<void> _loadGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? goalsJson = prefs.getString('user_goals');
      if (goalsJson != null) {
        final Map<String, dynamic> data = jsonDecode(goalsJson);
        _userGoals = UserGoals.fromJson(data);
      }
    } catch (e) {
      print('Error loading goals: $e');
      _userGoals = UserGoals();
    }
  }

  void _loadMockData() {
    _todaySessions = [
      TrackingSession(
        distance: 1.2,
        calories: 85.0,
        duration: 15,
        activityType: 'walking',
        startTime: DateTime.now().subtract(const Duration(hours: 2)),
        endTime: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
        route: [],
      ),
    ];
    _updateDailyTotalsFromSessions();
  }

  // Goal progress methods
  Map<String, double> getDailyGoalsProgress() {
    return {
      'distance': _userGoals.getDailyProgress('distance', _dailyDistance),
      'calories': _userGoals.getDailyProgress('calories', _dailyCalories),
      'steps': _userGoals.getDailyProgress('steps', _dailySteps.toDouble()),
    };
  }

  Map<String, bool> getDailyGoalsAchieved() {
    return {
      'distance': _userGoals.isDailyGoalAchieved('distance', _dailyDistance),
      'calories': _userGoals.isDailyGoalAchieved('calories', _dailyCalories),
      'steps': _userGoals.isDailyGoalAchieved('steps', _dailySteps.toDouble()),
    };
  }

  void refreshData() {
    _trackingStateController.add(_currentState);
    _dataChangeController.add(true);
  }

  void dispose() {
    _dailyResetTimer?.cancel();
    _trackingStateController.close();
    _dataChangeController.close();
  }
}

// Data models (reused from original service)
class TrackingSession {
  final double distance;
  final double calories;
  final int duration;
  final String activityType;
  final DateTime startTime;
  final DateTime endTime;
  final List<dynamic> route;

  TrackingSession({
    required this.distance,
    required this.calories,
    required this.duration,
    required this.activityType,
    required this.startTime,
    required this.endTime,
    required this.route,
  });

  Map<String, dynamic> toJson() {
    return {
      'distance': distance,
      'calories': calories,
      'duration': duration,
      'activityType': activityType,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'route': route,
    };
  }

  factory TrackingSession.fromJson(Map<String, dynamic> json) {
    return TrackingSession(
      distance: json['distance']?.toDouble() ?? 0.0,
      calories: json['calories']?.toDouble() ?? 0.0,
      duration: json['duration'] ?? 0,
      activityType: json['activityType'] ?? 'walking',
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      route: json['route'] ?? [],
    );
  }
}

class DailySummary {
  final String date;
  final double totalDistance;
  final double totalCalories;
  final int totalSteps;
  final int sessionCount;
  final List<TrackingSession> sessions;

  DailySummary({
    required this.date,
    required this.totalDistance,
    required this.totalCalories,
    required this.totalSteps,
    required this.sessionCount,
    required this.sessions,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'totalDistance': totalDistance,
      'totalCalories': totalCalories,
      'totalSteps': totalSteps,
      'sessionCount': sessionCount,
      'sessions': sessions.map((session) => session.toJson()).toList(),
    };
  }

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      date: json['date'] ?? '',
      totalDistance: json['totalDistance']?.toDouble() ?? 0.0,
      totalCalories: json['totalCalories']?.toDouble() ?? 0.0,
      totalSteps: json['totalSteps'] ?? 0,
      sessionCount: json['sessionCount'] ?? 0,
      sessions:
          (json['sessions'] as List<dynamic>?)
              ?.map((sessionJson) => TrackingSession.fromJson(sessionJson))
              .toList() ??
          [],
    );
  }
}

class WeeklySummary {
  final double totalDistance;
  final double totalCalories;
  final int totalSteps;
  final int activeDays;
  final double averageDistance;
  final double averageCalories;

  WeeklySummary({
    required this.totalDistance,
    required this.totalCalories,
    required this.totalSteps,
    required this.activeDays,
    required this.averageDistance,
    required this.averageCalories,
  });
}
