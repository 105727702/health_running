import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/analytics_models.dart';

class AnalyticsDashboardService {
  static final AnalyticsDashboardService _instance =
      AnalyticsDashboardService._internal();
  factory AnalyticsDashboardService() => _instance;
  AnalyticsDashboardService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Lấy tổng quan người dùng
  Future<UserOverviewData> getUserOverview() async {
    try {
      // Tổng số người dùng
      final usersSnapshot = await _firestore.collection('users').get();
      final totalUsers = usersSnapshot.docs.length;

      // Người dùng hoạt động trong 7 ngày qua
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final activeUsersSnapshot = await _firestore
          .collection('users')
          .where('lastActive', isGreaterThan: weekAgo)
          .get();
      final activeUsers = activeUsersSnapshot.docs.length;

      // Người dùng mới trong 30 ngày qua
      final monthAgo = DateTime.now().subtract(const Duration(days: 30));
      final newUsersSnapshot = await _firestore
          .collection('users')
          .where('createdAt', isGreaterThan: monthAgo)
          .get();
      final newUsers = newUsersSnapshot.docs.length;

      // Tổng số admin
      final adminSnapshot = await _firestore
          .collection('user_roles')
          .where('role', isEqualTo: 'admin')
          .get();
      final totalAdmins = adminSnapshot.docs.length;

      return UserOverviewData(
        totalUsers: totalUsers,
        activeUsers: activeUsers,
        newUsers: newUsers,
        totalAdmins: totalAdmins,
      );
    } catch (e) {
      print('Error getting user overview: $e');
      return UserOverviewData(
        totalUsers: 0,
        activeUsers: 0,
        newUsers: 0,
        totalAdmins: 0,
      );
    }
  }

  // Lấy dữ liệu hoạt động theo ngày
  Future<List<DailyActivityData>> getDailyActivity({int days = 7}) async {
    try {
      final List<DailyActivityData> activityData = [];
      final now = DateTime.now();

      for (int i = days - 1; i >= 0; i--) {
        final date = DateTime(now.year, now.month, now.day - i);
        final nextDate = date.add(const Duration(days: 1));

        // Lấy số lượng workout sessions trong ngày
        final workoutSnapshot = await _firestore
            .collection('workout_sessions')
            .where('date', isGreaterThanOrEqualTo: date)
            .where('date', isLessThan: nextDate)
            .get();

        // Lấy số lượng user active trong ngày
        final activeUserSnapshot = await _firestore
            .collection('users')
            .where('lastActive', isGreaterThanOrEqualTo: date)
            .where('lastActive', isLessThan: nextDate)
            .get();

        activityData.add(
          DailyActivityData(
            date: date,
            workoutSessions: workoutSnapshot.docs.length,
            activeUsers: activeUserSnapshot.docs.length,
          ),
        );
      }

      return activityData;
    } catch (e) {
      print('Error getting daily activity: $e');
      return [];
    }
  }

  // Lấy thống kê workout
  Future<WorkoutStats> getWorkoutStats() async {
    try {
      final workoutSnapshot = await _firestore
          .collection('workout_sessions')
          .get();

      double totalDistance = 0;
      double totalDuration = 0;
      double totalCalories = 0;
      int totalSessions = workoutSnapshot.docs.length;

      for (final doc in workoutSnapshot.docs) {
        final data = doc.data();
        totalDistance += (data['distance'] ?? 0.0).toDouble();
        totalDuration += (data['duration'] ?? 0.0).toDouble();
        totalCalories += (data['calories'] ?? 0.0).toDouble();
      }

      final avgDistance = totalSessions > 0
          ? totalDistance / totalSessions
          : 0.0;
      final avgDuration = totalSessions > 0
          ? totalDuration / totalSessions
          : 0.0;
      final avgCalories = totalSessions > 0
          ? totalCalories / totalSessions
          : 0.0;

      return WorkoutStats(
        totalSessions: totalSessions,
        totalDistance: totalDistance,
        totalDuration: totalDuration,
        totalCalories: totalCalories,
        avgDistance: avgDistance,
        avgDuration: avgDuration,
        avgCalories: avgCalories,
      );
    } catch (e) {
      print('Error getting workout stats: $e');
      return WorkoutStats(
        totalSessions: 0,
        totalDistance: 0,
        totalDuration: 0,
        totalCalories: 0,
        avgDistance: 0,
        avgDuration: 0,
        avgCalories: 0,
      );
    }
  }

  // Lấy top users
  Future<List<TopUserData>> getTopUsers({int limit = 10}) async {
    try {
      final workoutSnapshot = await _firestore
          .collection('workout_sessions')
          .orderBy('distance', descending: true)
          .limit(limit * 3) // Lấy nhiều hơn để group by user
          .get();

      final Map<String, TopUserData> userStats = {};

      for (final doc in workoutSnapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String?;
        if (userId == null) continue;

        final distance = (data['distance'] ?? 0.0).toDouble();
        final duration = (data['duration'] ?? 0.0).toDouble();
        final calories = (data['calories'] ?? 0.0).toDouble();

        if (userStats.containsKey(userId)) {
          userStats[userId] = userStats[userId]!.copyWith(
            totalDistance: userStats[userId]!.totalDistance + distance,
            totalDuration: userStats[userId]!.totalDuration + duration,
            totalCalories: userStats[userId]!.totalCalories + calories,
            totalWorkouts: userStats[userId]!.totalWorkouts + 1,
          );
        } else {
          // Lấy thông tin user
          final userDoc = await _firestore
              .collection('users')
              .doc(userId)
              .get();
          final userData = userDoc.data();
          final userName =
              userData?['displayName'] ??
              userData?['email']?.split('@')[0] ??
              'Unknown';

          userStats[userId] = TopUserData(
            userId: userId,
            userName: userName,
            totalDistance: distance,
            totalDuration: duration,
            totalCalories: calories,
            totalWorkouts: 1,
          );
        }
      }

      final topUsers = userStats.values.toList();
      topUsers.sort((a, b) => b.totalDistance.compareTo(a.totalDistance));

      return topUsers.take(limit).toList();
    } catch (e) {
      print('Error getting top users: $e');
      return [];
    }
  }

  // Lấy app usage events
  Future<List<AppEventData>> getAppEvents({int days = 7}) async {
    try {
      final daysAgo = DateTime.now().subtract(Duration(days: days));
      final eventsSnapshot = await _firestore
          .collection('app_events')
          .where('timestamp', isGreaterThan: daysAgo)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      return eventsSnapshot.docs.map((doc) {
        final data = doc.data();
        return AppEventData(
          eventName: data['event_name'] ?? 'unknown',
          screenName: data['screen_name'] ?? 'unknown',
          userId: data['user_id'] ?? 'anonymous',
          timestamp:
              (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          parameters: Map<String, dynamic>.from(data['parameters'] ?? {}),
        );
      }).toList();
    } catch (e) {
      print('Error getting app events: $e');
      return [];
    }
  }

  // Lấy crash reports summary
  Future<CrashSummaryData> getCrashSummary({int days = 30}) async {
    try {
      final daysAgo = DateTime.now().subtract(Duration(days: days));
      final crashSnapshot = await _firestore
          .collection('crash_reports')
          .where('timestamp', isGreaterThan: daysAgo)
          .get();

      final Map<String, int> crashesByType = {};
      final Map<String, int> crashesByScreen = {};
      int totalCrashes = crashSnapshot.docs.length;

      for (final doc in crashSnapshot.docs) {
        final data = doc.data();
        final crashType = data['error_type'] ?? 'Unknown';
        final screenName = data['screen_name'] ?? 'Unknown';

        crashesByType[crashType] = (crashesByType[crashType] ?? 0) + 1;
        crashesByScreen[screenName] = (crashesByScreen[screenName] ?? 0) + 1;
      }

      return CrashSummaryData(
        totalCrashes: totalCrashes,
        crashesByType: crashesByType,
        crashesByScreen: crashesByScreen,
        period: days,
      );
    } catch (e) {
      print('Error getting crash summary: $e');
      return CrashSummaryData(
        totalCrashes: 0,
        crashesByType: {},
        crashesByScreen: {},
        period: days,
      );
    }
  }

  // Log analytics event (để thu thập data)
  Future<void> logEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
    String? screenName,
  }) async {
    try {
      final user = _auth.currentUser;
      await _firestore.collection('app_events').add({
        'event_name': eventName,
        'screen_name': screenName,
        'user_id': user?.uid ?? 'anonymous',
        'user_email': user?.email,
        'parameters': parameters ?? {},
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error logging event: $e');
    }
  }

  // Cập nhật user activity
  Future<void> updateUserActivity() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user activity: $e');
    }
  }
}
