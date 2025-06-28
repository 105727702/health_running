import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tracking_state.dart';
import '../models/user_goals.dart';

class TrackingDataService {
  static final TrackingDataService _instance = TrackingDataService._internal();
  factory TrackingDataService() => _instance;

  late final Future<void> _initializationFuture;

  TrackingDataService._internal() {
    _initializationFuture = _initializeService();
  }

  // Get initialization future
  Future<void> get initialized => _initializationFuture;

  // Initialize service and load saved data
  Future<void> _initializeService() async {
    await _loadSavedData();
    _checkAndResetDailyData();
    _startDailyResetTimer();
  }

  // Stream controller for tracking state updates
  final StreamController<TrackingState> _trackingStateController =
      StreamController<TrackingState>.broadcast();

  // Stream controller for data changes (for UI refresh)
  final StreamController<bool> _dataChangeController =
      StreamController<bool>.broadcast();

  // Current tracking state
  TrackingState _currentState = TrackingState();

  // Daily summary data
  double _dailyDistance = 0.0;
  double _dailyCalories = 0.0;
  int _dailySteps = 0;
  List<TrackingSession> _todaySessions = [];

  // Historical data storage
  Map<String, DailySummary> _historicalData = {}; // Key: "yyyy-MM-dd"
  String _lastResetDate = "";

  // User goals
  UserGoals _userGoals = UserGoals();

  // Timer for daily reset
  Timer? _dailyResetTimer;

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

  // Update tracking state
  void updateTrackingState(TrackingState newState) {
    _currentState = newState;
    _trackingStateController.add(newState);

    // Update daily totals if tracking is active
    if (newState.isTracking) {
      _updateDailyTotals(newState);
    }

    // Force UI update by emitting current state
    _trackingStateController.add(_currentState);
  }

  // Save session when tracking stops
  void saveSession(TrackingState finalState) {
    if (finalState.totalDistance > 0) {
      final session = TrackingSession(
        distance: finalState.totalDistance,
        calories: finalState.totalCalories,
        duration: 30, // Mock duration - in real app this would be calculated
        activityType: finalState.activityType,
        startTime: DateTime.now().subtract(Duration(minutes: 30)), // Mock data
        endTime: DateTime.now(),
        route: finalState.route,
      );

      _todaySessions.add(session);
      _updateDailyTotals(finalState);

      // Save data to storage
      _saveData();
    }
  }

  // Update daily totals
  void _updateDailyTotals(TrackingState state) {
    _updateDailyTotalsFromSessions();
  }

  // Update daily totals from sessions
  void _updateDailyTotalsFromSessions() {
    _dailyDistance = _todaySessions.fold(
      0.0,
      (sum, session) => sum + session.distance,
    );
    _dailyCalories = _todaySessions.fold(
      0.0,
      (sum, session) => sum + session.calories,
    );
    _dailySteps = (_dailyDistance * 1300)
        .round(); // Approximate steps (1300 steps per km)
  }

  // Get weekly summary
  WeeklySummary getWeeklySummary() {
    final now = DateTime.now();
    double totalDistance = _dailyDistance;
    double totalCalories = _dailyCalories;
    double totalStepsDouble = _dailySteps.toDouble();
    int activeDays = _todaySessions.isNotEmpty ? 1 : 0;

    // Add data from last 6 days
    for (int i = 1; i <= 6; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = _formatDate(date);
      final dayData = _historicalData[dateKey];

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

  // Load saved data from SharedPreferences
  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load historical data
      final String? historicalJson = prefs.getString('historical_data');
      if (historicalJson != null) {
        final Map<String, dynamic> data = jsonDecode(historicalJson);
        _historicalData = data.map(
          (key, value) => MapEntry(key, DailySummary.fromJson(value)),
        );
      }

      // Load last reset date
      _lastResetDate =
          prefs.getString('last_reset_date') ?? _formatDate(DateTime.now());

      // Load today's sessions if exist
      final String? todaySessionsJson = prefs.getString('today_sessions');
      if (todaySessionsJson != null) {
        final List<dynamic> sessionsData = jsonDecode(todaySessionsJson);
        _todaySessions = sessionsData
            .map((json) => TrackingSession.fromJson(json))
            .toList();
        _updateDailyTotalsFromSessions();
      } else {
        // Load mock data if no saved data
        _loadMockData();
      }

      // Load user goals
      await _loadGoals();
    } catch (e) {
      print('Error loading saved data: $e');
      _loadMockData();
      _userGoals = UserGoals(); // Set default goals on error
    }
  }

  // Load mock data for demo
  void _loadMockData() {
    _todaySessions = [
      TrackingSession(
        distance: 1.2,
        calories: 85.0,
        duration: 15,
        activityType: 'walking',
        startTime: DateTime.now().subtract(Duration(hours: 2)),
        endTime: DateTime.now().subtract(Duration(hours: 1, minutes: 45)),
        route: [],
      ),
      TrackingSession(
        distance: 1.3,
        calories: 95.0,
        duration: 18,
        activityType: 'running',
        startTime: DateTime.now().subtract(Duration(hours: 4)),
        endTime: DateTime.now().subtract(Duration(hours: 3, minutes: 42)),
        route: [],
      ),
    ];
    _updateDailyTotalsFromSessions();
  }

  // Save data to SharedPreferences
  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save historical data
      final historicalJson = jsonEncode(
        _historicalData.map((key, value) => MapEntry(key, value.toJson())),
      );
      await prefs.setString('historical_data', historicalJson);

      // Save last reset date
      await prefs.setString('last_reset_date', _lastResetDate);

      // Save today's sessions
      final todaySessionsJson = jsonEncode(
        _todaySessions.map((session) => session.toJson()).toList(),
      );
      await prefs.setString('today_sessions', todaySessionsJson);
    } catch (e) {
      print('Error saving data: $e');
    }
  }

  // Check if we need to reset daily data
  void _checkAndResetDailyData() {
    final today = _formatDate(DateTime.now());
    if (_lastResetDate != today) {
      _performDailyReset();
    }
  }

  // Perform daily reset and save yesterday's data
  void _performDailyReset() {
    final yesterday = _formatDate(DateTime.now().subtract(Duration(days: 1)));

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

    // Save the changes
    _saveData();

    print('Daily data reset completed for ${DateTime.now()}');
  }

  // Start timer for daily reset at midnight
  void _startDailyResetTimer() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);

    _dailyResetTimer = Timer(timeUntilMidnight, () {
      _performDailyReset();
      // Set up recurring daily timer
      _dailyResetTimer = Timer.periodic(Duration(days: 1), (timer) {
        _performDailyReset();
      });
    });
  }

  // Format date as string
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Get historical data for specific date
  DailySummary? getDataForDate(DateTime date) {
    return _historicalData[_formatDate(date)];
  }

  // Get all historical data
  Map<String, DailySummary> getAllHistoricalData() {
    return Map.from(_historicalData);
  }

  // Reset daily data (call at midnight)
  void resetDailyData() {
    _performDailyReset();
  }

  // Goals management methods

  // Update user goals
  Future<void> updateUserGoals(UserGoals newGoals) async {
    _userGoals = newGoals;
    await _saveGoals();
    _trackingStateController.add(_currentState); // Trigger UI update
  }

  // Update daily goals
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

  // Update weekly goals
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

  // Get daily goal progress
  Map<String, double> getDailyGoalsProgress() {
    return {
      'distance': _userGoals.getDailyProgress('distance', _dailyDistance),
      'calories': _userGoals.getDailyProgress('calories', _dailyCalories),
      'steps': _userGoals.getDailyProgress('steps', _dailySteps.toDouble()),
    };
  }

  // Get weekly goal progress
  Map<String, double> getWeeklyGoalsProgress() {
    final weekly = getWeeklySummary();
    return {
      'distance': _userGoals.getWeeklyProgress(
        'distance',
        weekly.totalDistance,
      ),
      'calories': _userGoals.getWeeklyProgress(
        'calories',
        weekly.totalCalories,
      ),
      'steps': _userGoals.getWeeklyProgress(
        'steps',
        weekly.totalSteps.toDouble(),
      ),
      'activeDays': _userGoals.getWeeklyProgress(
        'activedays',
        weekly.activeDays.toDouble(),
      ),
    };
  }

  // Check if any daily goals are achieved
  Map<String, bool> getDailyGoalsAchieved() {
    return {
      'distance': _userGoals.isDailyGoalAchieved('distance', _dailyDistance),
      'calories': _userGoals.isDailyGoalAchieved('calories', _dailyCalories),
      'steps': _userGoals.isDailyGoalAchieved('steps', _dailySteps.toDouble()),
    };
  }

  // Save goals to SharedPreferences
  Future<void> _saveGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_goals', jsonEncode(_userGoals.toJson()));
    } catch (e) {
      print('Error saving goals: $e');
    }
  }

  // Load goals from SharedPreferences
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
      _userGoals = UserGoals(); // Use default goals
    }
  }

  // Force refresh data and notify listeners
  void refreshData() {
    _trackingStateController.add(_currentState);
  }

  // Clear all history and reset progress
  Future<void> clearAllHistoryAndReset() async {
    try {
      // Clear all data
      _historicalData.clear();
      _todaySessions.clear();
      _dailyDistance = 0.0;
      _dailyCalories = 0.0;
      _dailySteps = 0;
      _currentState = TrackingState();

      // Save the cleared state
      await _saveData();

      // Notify listeners
      _trackingStateController.add(_currentState);
      _dataChangeController.add(true);

      print('All history and progress cleared successfully');
    } catch (e) {
      print('Error clearing history: $e');
      throw Exception('Failed to clear history and reset progress');
    }
  }

  // Clear only today's data
  Future<void> clearTodayData() async {
    try {
      _todaySessions.clear();
      _dailyDistance = 0.0;
      _dailyCalories = 0.0;
      _dailySteps = 0;

      // Reset current tracking state
      _currentState = TrackingState();

      await _saveData();
      _trackingStateController.add(_currentState);
      _dataChangeController.add(true);

      print('Today\'s data cleared successfully');
    } catch (e) {
      print('Error clearing today\'s data: $e');
      throw Exception('Failed to clear today\'s data');
    }
  }

  // Clear only historical data (keep today's data)
  Future<void> clearHistoricalData() async {
    try {
      _historicalData.clear();
      await _saveData();
      _dataChangeController.add(true);

      print('Historical data cleared successfully');
    } catch (e) {
      print('Error clearing historical data: $e');
      throw Exception('Failed to clear historical data');
    }
  }

  // Reset goals to default values
  Future<void> resetGoalsToDefault() async {
    try {
      _userGoals = UserGoals(); // Default goals
      await _saveGoals();
      _trackingStateController.add(_currentState);
      _dataChangeController.add(true);

      print('Goals reset to default values');
    } catch (e) {
      print('Error resetting goals: $e');
      throw Exception('Failed to reset goals');
    }
  }

  // Complete reset - everything back to default
  Future<void> completeReset() async {
    try {
      // Clear all data
      await clearAllHistoryAndReset();

      // Reset goals
      await resetGoalsToDefault();

      print('Complete reset performed successfully');
    } catch (e) {
      print('Error performing complete reset: $e');
      throw Exception('Failed to perform complete reset');
    }
  }

  // Dispose
  void dispose() {
    _dailyResetTimer?.cancel();
    _trackingStateController.close();
    _dataChangeController.close();
  }
}

// Data models
class TrackingSession {
  final double distance;
  final double calories;
  final int duration; // in minutes
  final String activityType;
  final DateTime startTime;
  final DateTime endTime;
  final List<dynamic> route; // LatLng list

  TrackingSession({
    required this.distance,
    required this.calories,
    required this.duration,
    required this.activityType,
    required this.startTime,
    required this.endTime,
    required this.route,
  });

  // Convert to JSON
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

  // Create from JSON
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
  final String date; // yyyy-MM-dd format
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

  // Convert to JSON
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

  // Create from JSON
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
