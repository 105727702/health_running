// Analytics data models for dashboard

class UserOverviewData {
  final int totalUsers;
  final int activeUsers;
  final int newUsers;
  final int totalAdmins;

  const UserOverviewData({
    required this.totalUsers,
    required this.activeUsers,
    required this.newUsers,
    required this.totalAdmins,
  });

  @override
  String toString() {
    return 'UserOverviewData(totalUsers: $totalUsers, activeUsers: $activeUsers, newUsers: $newUsers, totalAdmins: $totalAdmins)';
  }
}

class DailyActivityData {
  final DateTime date;
  final int workoutSessions;
  final int activeUsers;

  const DailyActivityData({
    required this.date,
    required this.workoutSessions,
    required this.activeUsers,
  });

  String get dateString => '${date.day}/${date.month}';

  @override
  String toString() {
    return 'DailyActivityData(date: $date, workoutSessions: $workoutSessions, activeUsers: $activeUsers)';
  }
}

class WorkoutStats {
  final int totalSessions;
  final double totalDistance;
  final double totalDuration;
  final double totalCalories;
  final double avgDistance;
  final double avgDuration;
  final double avgCalories;

  const WorkoutStats({
    required this.totalSessions,
    required this.totalDistance,
    required this.totalDuration,
    required this.totalCalories,
    required this.avgDistance,
    required this.avgDuration,
    required this.avgCalories,
  });

  @override
  String toString() {
    return 'WorkoutStats(totalSessions: $totalSessions, totalDistance: $totalDistance, avgDistance: $avgDistance)';
  }
}

class TopUserData {
  final String userId;
  final String userName;
  final double totalDistance;
  final double totalDuration;
  final double totalCalories;
  final int totalWorkouts;

  const TopUserData({
    required this.userId,
    required this.userName,
    required this.totalDistance,
    required this.totalDuration,
    required this.totalCalories,
    required this.totalWorkouts,
  });

  TopUserData copyWith({
    String? userId,
    String? userName,
    double? totalDistance,
    double? totalDuration,
    double? totalCalories,
    int? totalWorkouts,
  }) {
    return TopUserData(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      totalDistance: totalDistance ?? this.totalDistance,
      totalDuration: totalDuration ?? this.totalDuration,
      totalCalories: totalCalories ?? this.totalCalories,
      totalWorkouts: totalWorkouts ?? this.totalWorkouts,
    );
  }

  @override
  String toString() {
    return 'TopUserData(userName: $userName, totalDistance: $totalDistance, totalWorkouts: $totalWorkouts)';
  }
}

class AppEventData {
  final String eventName;
  final String screenName;
  final String userId;
  final DateTime timestamp;
  final Map<String, dynamic> parameters;

  const AppEventData({
    required this.eventName,
    required this.screenName,
    required this.userId,
    required this.timestamp,
    required this.parameters,
  });

  String get timeString =>
      '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  String get dateString => '${timestamp.day}/${timestamp.month}';

  @override
  String toString() {
    return 'AppEventData(eventName: $eventName, screenName: $screenName, timestamp: $timestamp)';
  }
}

class CrashSummaryData {
  final int totalCrashes;
  final Map<String, int> crashesByType;
  final Map<String, int> crashesByScreen;
  final int period; // days

  const CrashSummaryData({
    required this.totalCrashes,
    required this.crashesByType,
    required this.crashesByScreen,
    required this.period,
  });

  List<MapEntry<String, int>> get topCrashTypes {
    final entries = crashesByType.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).toList();
  }

  List<MapEntry<String, int>> get topCrashScreens {
    final entries = crashesByScreen.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).toList();
  }

  @override
  String toString() {
    return 'CrashSummaryData(totalCrashes: $totalCrashes, period: ${period}d)';
  }
}

class ChartDataPoint {
  final String label;
  final double value;
  final String? category;

  const ChartDataPoint({
    required this.label,
    required this.value,
    this.category,
  });

  @override
  String toString() {
    return 'ChartDataPoint(label: $label, value: $value)';
  }
}

class DashboardSummary {
  final UserOverviewData userOverview;
  final WorkoutStats workoutStats;
  final List<DailyActivityData> dailyActivity;
  final List<TopUserData> topUsers;
  final CrashSummaryData crashSummary;
  final DateTime lastUpdated;

  const DashboardSummary({
    required this.userOverview,
    required this.workoutStats,
    required this.dailyActivity,
    required this.topUsers,
    required this.crashSummary,
    required this.lastUpdated,
  });

  @override
  String toString() {
    return 'DashboardSummary(lastUpdated: $lastUpdated, totalUsers: ${userOverview.totalUsers})';
  }
}
