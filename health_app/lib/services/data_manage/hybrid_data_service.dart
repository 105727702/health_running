import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/tracking_state.dart';
import '../../models/user_goals.dart';
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
    _startPeriodicSync(); // Start periodic sync on initialization
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

  // Debug methods to help understand data discrepancies
  double get currentTrackingDistance => _currentState.totalDistance;
  double get currentTrackingCalories => _currentState.totalCalories;
  bool get isCurrentlyTracking => _currentState.isTracking;

  // Get combined data (saved sessions + current tracking if active)
  double get combinedTotalDistance {
    double total = _dailyDistance;
    if (_currentState.isTracking) {
      total += _currentState.totalDistance;
    }
    return total;
  }

  double get combinedTotalCalories {
    double total = _dailyCalories;
    if (_currentState.isTracking) {
      total += _currentState.totalCalories;
    }
    return total;
  }

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

    // No need to update daily totals here since they should only come from saved sessions
    // The daily totals represent completed sessions, not the current ongoing tracking
  }

  // Save session (both local and Firebase)
  Future<void> saveSession(TrackingState finalState) async {
    if (finalState.totalDistance > 0) {
      // Convert LatLng route points to Map format for consistent storage
      final routeData = finalState.route
          .map(
            (point) => {
              'latitude': point.latitude,
              'longitude': point.longitude,
            },
          )
          .toList();

      final session = TrackingSession(
        distance: finalState.totalDistance,
        calories: finalState.totalCalories,
        duration: 30, // Should be calculated from actual tracking time
        activityType: finalState.activityType,
        startTime: DateTime.now().subtract(const Duration(minutes: 30)),
        endTime: DateTime.now(),
        route: routeData,
      );

      // Always save locally first
      _todaySessions.add(session);
      // Recalculate daily totals from all sessions (not just replace with current state)
      _updateDailyTotalsFromSessions();
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
    double totalSteps = _dailySteps.toDouble();
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
        totalSteps += dayData.totalSteps.toDouble();
        if (dayData.sessionCount > 0) activeDays++;
      }
    }

    return WeeklySummary(
      totalDistance: totalDistance,
      totalCalories: totalCalories,
      totalSteps: totalSteps.round(),
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

  void _updateDailyTotalsFromSessions() {
    // Calculate daily totals from all saved sessions for today
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
      final yesterdaySummary = DailySummary(
        date: yesterday,
        totalDistance: _dailyDistance,
        totalCalories: _dailyCalories,
        totalSteps: _dailySteps,
        sessionCount: _todaySessions.length,
        sessions: List.from(_todaySessions),
      );

      _historicalData[yesterday] = yesterdaySummary;

      // Auto-save yesterday's data to Firebase
      _autoSaveToFirebase(yesterdaySummary);
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

  // Periodic sync check - runs every hour when app is active
  Timer? _periodicSyncTimer;

  void _startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _performPeriodicSync();
    });
  }

  Future<void> _performPeriodicSync() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Sync offline queue if any
      if (_offlineSessionsQueue.isNotEmpty) {
        print(
          '🔄 Periodic sync: Syncing ${_offlineSessionsQueue.length} offline sessions...',
        );
        await _syncOfflineData();
      }

      // Auto-save current day if significant activity
      if (_dailyDistance > 0.5 || _todaySessions.length >= 2) {
        print('🔄 Periodic sync: Auto-saving current day data...');
        await _firebaseService.saveDailySummary(
          date: DateTime.now(),
          totalDistance: _dailyDistance,
          totalCalories: _dailyCalories,
          totalSteps: _dailySteps,
          sessionCount: _todaySessions.length,
        );
      }
    } catch (e) {
      print('❌ Periodic sync failed: $e');
    }
  }

  // Get auto-save status for UI display
  Map<String, dynamic> getAutoSaveStatus() {
    final user = _auth.currentUser;
    return {
      'isEnabled': user != null,
      'nextDailyReset': _getNextResetTime(),
      'nextPeriodicSync': _getNextSyncTime(),
      'offlineQueueCount': _offlineSessionsQueue.length,
      'lastResetDate': _lastResetDate,
    };
  }

  String _getNextResetTime() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntil = tomorrow.difference(now);

    final hours = timeUntil.inHours;
    final minutes = timeUntil.inMinutes % 60;

    return '${hours}h ${minutes}m';
  }

  String _getNextSyncTime() {
    if (_periodicSyncTimer == null) return 'Disabled';

    // Estimate next sync (this is approximate since Timer doesn't give us exact next time)
    final now = DateTime.now();
    final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1);
    final timeUntil = nextHour.difference(now);

    final minutes = timeUntil.inMinutes;
    return '${minutes}m';
  }

  // Manual trigger for immediate backup (for testing or user request)
  Future<void> manualBackupToFirebase() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      print('🔄 Manual backup initiated...');

      // Save current day data
      if (_dailyDistance > 0 || _todaySessions.isNotEmpty) {
        await _firebaseService.saveDailySummary(
          date: DateTime.now(),
          totalDistance: _dailyDistance,
          totalCalories: _dailyCalories,
          totalSteps: _dailySteps,
          sessionCount: _todaySessions.length,
        );

        // Save individual sessions
        for (final session in _todaySessions) {
          await _firebaseService.saveTrackingSession(
            distance: session.distance,
            calories: session.calories,
            duration: session.duration,
            activityType: session.activityType,
            startTime: session.startTime,
            endTime: session.endTime,
            route: session.route,
          );
        }
      }

      // Sync offline queue
      await _syncOfflineData();

      print('✅ Manual backup completed successfully');
    } catch (e) {
      print('❌ Manual backup failed: $e');
      rethrow;
    }
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
    _periodicSyncTimer?.cancel();
    _trackingStateController.close();
    _dataChangeController.close();
  }

  // Auto-save daily summary to Firebase (background operation)
  Future<void> _autoSaveToFirebase(DailySummary summary) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('📦 Auto-save skipped: User not authenticated');
      return;
    }

    try {
      print('📦 Auto-saving daily summary to Firebase for ${summary.date}...');

      // Parse the date string back to DateTime
      final dateParts = summary.date.split('-');
      final date = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
      );

      await _firebaseService.saveDailySummary(
        date: date,
        totalDistance: summary.totalDistance,
        totalCalories: summary.totalCalories,
        totalSteps: summary.totalSteps,
        sessionCount: summary.sessionCount,
      );

      // Also save individual sessions if they haven't been saved yet
      for (final session in summary.sessions) {
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
        } catch (e) {
          print('⚠️ Failed to save session to Firebase: $e');
          // Continue with other sessions even if one fails
        }
      }

      print('✅ Auto-save completed successfully for ${summary.date}');
    } catch (e) {
      print('❌ Auto-save failed for ${summary.date}: $e');
      // Add to offline queue for later sync
      _addToOfflineQueue(summary);
    }
  }

  // Add failed auto-saves to offline queue
  void _addToOfflineQueue(DailySummary summary) {
    try {
      for (final session in summary.sessions) {
        _offlineSessionsQueue.add(session.toJson());
      }
      _saveOfflineQueue();
      print('📝 Added ${summary.sessions.length} sessions to offline queue');
    } catch (e) {
      print('❌ Failed to add to offline queue: $e');
    }
  }

  // Delete session from both local storage and Firebase
  Future<void> deleteSession(String sessionId, DateTime sessionDate) async {
    try {
      // Delete from Firebase first if user is authenticated
      final user = _auth.currentUser;
      if (user != null) {
        await _firebaseService.deleteSession(sessionId);
      }

      // Delete from local storage
      final dateString = _formatDate(sessionDate);
      
      // If it's today's session, remove from today's sessions
      if (dateString == _formatDate(DateTime.now())) {
        _todaySessions.removeWhere((session) => session.toJson().toString().contains(sessionId));
        _updateDailyTotalsFromSessions();
        await _saveLocalData();
      } else {
        // Remove from historical data
        if (_historicalData.containsKey(dateString)) {
          final dayData = _historicalData[dateString]!;
          dayData.sessions.removeWhere((session) => session.toJson().toString().contains(sessionId));
          
          // Update daily totals for that day
          double dayDistance = 0, dayCalories = 0;
          int daySteps = 0;
          for (final session in dayData.sessions) {
            dayDistance += session.distance;
            dayCalories += session.calories;
            daySteps += (session.distance * 1000).round(); // Rough steps calculation
          }
          
          _historicalData[dateString] = DailySummary(
            date: dateString,
            totalDistance: dayDistance,
            totalCalories: dayCalories,
            totalSteps: daySteps,
            sessionCount: dayData.sessions.length,
            sessions: dayData.sessions,
          );
          
          await _saveLocalData();
        }
      }

      _dataChangeController.add(true);
      print('Session deleted successfully');
    } catch (e) {
      print('Error deleting session: $e');
      throw e;
    }
  }

  // Update session in both local storage and Firebase
  Future<void> updateSession({
    required String sessionId,
    required DateTime sessionDate,
    required double distance,
    required double calories,
    required int duration,
    required String activityType,
    required DateTime startTime,
    required DateTime endTime,
    required List<dynamic> route,
  }) async {
    try {
      // Update in Firebase first if user is authenticated
      final user = _auth.currentUser;
      if (user != null) {
        await _firebaseService.updateSession(
          sessionId: sessionId,
          distance: distance,
          calories: calories,
          duration: duration,
          activityType: activityType,
          startTime: startTime,
          endTime: endTime,
          route: route,
        );
      }

      // Create updated session
      final updatedSession = TrackingSession(
        distance: distance,
        calories: calories,
        duration: duration,
        activityType: activityType,
        startTime: startTime,
        endTime: endTime,
        route: route,
      );

      // Update in local storage
      final dateString = _formatDate(sessionDate);
      
      // If it's today's session, update today's sessions
      if (dateString == _formatDate(DateTime.now())) {
        final index = _todaySessions.indexWhere((session) => 
          session.toJson().toString().contains(sessionId));
        if (index != -1) {
          _todaySessions[index] = updatedSession;
          _updateDailyTotalsFromSessions();
          await _saveLocalData();
        }
      } else {
        // Update in historical data
        if (_historicalData.containsKey(dateString)) {
          final dayData = _historicalData[dateString]!;
          final index = dayData.sessions.indexWhere((session) => 
            session.toJson().toString().contains(sessionId));
          
          if (index != -1) {
            dayData.sessions[index] = updatedSession;
            
            // Recalculate daily totals for that day
            double dayDistance = 0, dayCalories = 0;
            int daySteps = 0;
            for (final session in dayData.sessions) {
              dayDistance += session.distance;
              dayCalories += session.calories;
              daySteps += (session.distance * 1000).round(); // Rough steps calculation
            }
            
            _historicalData[dateString] = DailySummary(
              date: dateString,
              totalDistance: dayDistance,
              totalCalories: dayCalories,
              totalSteps: daySteps,
              sessionCount: dayData.sessions.length,
              sessions: dayData.sessions,
            );
            
            await _saveLocalData();
          }
        }
      }

      _dataChangeController.add(true);
      print('Session updated successfully');
    } catch (e) {
      print('Error updating session: $e');
      throw e;
    }
  }

  // Get session by ID for editing
  TrackingSession? getSessionById(String sessionId, DateTime sessionDate) {
    final dateString = _formatDate(sessionDate);
    
    // Check today's sessions
    if (dateString == _formatDate(DateTime.now())) {
      return _todaySessions.firstWhere(
        (session) => session.toJson().toString().contains(sessionId),
        orElse: () => throw StateError('Session not found'),
      );
    } else {
      // Check historical data
      if (_historicalData.containsKey(dateString)) {
        final dayData = _historicalData[dateString]!;
        return dayData.sessions.firstWhere(
          (session) => session.toJson().toString().contains(sessionId),
          orElse: () => throw StateError('Session not found'),
        );
      }
    }
    
    return null;
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
    // Handle route data conversion from Firebase
    List<dynamic> routeData = [];
    if (json['route'] != null) {
      final rawRoute = json['route'] as List<dynamic>;
      routeData = rawRoute.map((point) {
        if (point is GeoPoint) {
          // Convert GeoPoint back to our expected format
          return {'latitude': point.latitude, 'longitude': point.longitude};
        } else if (point is Map<String, dynamic>) {
          // Already in the expected format
          return point;
        } else {
          // Fallback for unexpected data types
          return {'latitude': 0.0, 'longitude': 0.0};
        }
      }).toList();
    }

    return TrackingSession(
      distance: json['distance']?.toDouble() ?? 0.0,
      calories: json['calories']?.toDouble() ?? 0.0,
      duration: json['duration'] ?? 0,
      activityType: json['activityType'] ?? 'walking',
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      route: routeData,
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
