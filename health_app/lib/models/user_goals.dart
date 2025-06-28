class UserGoals {
  final double dailyDistanceGoal;
  final double dailyCaloriesGoal;
  final int dailyStepsGoal;
  final double weeklyDistanceGoal;
  final double weeklyCaloriesGoal;
  final int weeklyStepsGoal;
  final int weeklyActiveDaysGoal;

  UserGoals({
    this.dailyDistanceGoal = 5.0,
    this.dailyCaloriesGoal = 500.0,
    this.dailyStepsGoal = 10000,
    this.weeklyDistanceGoal = 30.0,
    this.weeklyCaloriesGoal = 3000.0,
    this.weeklyStepsGoal = 70000,
    this.weeklyActiveDaysGoal = 5,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'dailyDistanceGoal': dailyDistanceGoal,
      'dailyCaloriesGoal': dailyCaloriesGoal,
      'dailyStepsGoal': dailyStepsGoal,
      'weeklyDistanceGoal': weeklyDistanceGoal,
      'weeklyCaloriesGoal': weeklyCaloriesGoal,
      'weeklyStepsGoal': weeklyStepsGoal,
      'weeklyActiveDaysGoal': weeklyActiveDaysGoal,
    };
  }

  // Create from JSON
  factory UserGoals.fromJson(Map<String, dynamic> json) {
    return UserGoals(
      dailyDistanceGoal: json['dailyDistanceGoal']?.toDouble() ?? 5.0,
      dailyCaloriesGoal: json['dailyCaloriesGoal']?.toDouble() ?? 500.0,
      dailyStepsGoal: json['dailyStepsGoal'] ?? 10000,
      weeklyDistanceGoal: json['weeklyDistanceGoal']?.toDouble() ?? 30.0,
      weeklyCaloriesGoal: json['weeklyCaloriesGoal']?.toDouble() ?? 3000.0,
      weeklyStepsGoal: json['weeklyStepsGoal'] ?? 70000,
      weeklyActiveDaysGoal: json['weeklyActiveDaysGoal'] ?? 5,
    );
  }

  // Copy with new values
  UserGoals copyWith({
    double? dailyDistanceGoal,
    double? dailyCaloriesGoal,
    int? dailyStepsGoal,
    double? weeklyDistanceGoal,
    double? weeklyCaloriesGoal,
    int? weeklyStepsGoal,
    int? weeklyActiveDaysGoal,
  }) {
    return UserGoals(
      dailyDistanceGoal: dailyDistanceGoal ?? this.dailyDistanceGoal,
      dailyCaloriesGoal: dailyCaloriesGoal ?? this.dailyCaloriesGoal,
      dailyStepsGoal: dailyStepsGoal ?? this.dailyStepsGoal,
      weeklyDistanceGoal: weeklyDistanceGoal ?? this.weeklyDistanceGoal,
      weeklyCaloriesGoal: weeklyCaloriesGoal ?? this.weeklyCaloriesGoal,
      weeklyStepsGoal: weeklyStepsGoal ?? this.weeklyStepsGoal,
      weeklyActiveDaysGoal: weeklyActiveDaysGoal ?? this.weeklyActiveDaysGoal,
    );
  }

  // Get daily goal progress
  double getDailyProgress(String type, double currentValue) {
    switch (type.toLowerCase()) {
      case 'distance':
        return (currentValue / dailyDistanceGoal).clamp(0.0, 1.0);
      case 'calories':
        return (currentValue / dailyCaloriesGoal).clamp(0.0, 1.0);
      case 'steps':
        return (currentValue / dailyStepsGoal).clamp(0.0, 1.0);
      default:
        return 0.0;
    }
  }

  // Get weekly goal progress
  double getWeeklyProgress(String type, double currentValue) {
    switch (type.toLowerCase()) {
      case 'distance':
        return (currentValue / weeklyDistanceGoal).clamp(0.0, 1.0);
      case 'calories':
        return (currentValue / weeklyCaloriesGoal).clamp(0.0, 1.0);
      case 'steps':
        return (currentValue / weeklyStepsGoal).clamp(0.0, 1.0);
      case 'activedays':
        return (currentValue / weeklyActiveDaysGoal).clamp(0.0, 1.0);
      default:
        return 0.0;
    }
  }

  // Check if daily goal is achieved
  bool isDailyGoalAchieved(String type, double currentValue) {
    return getDailyProgress(type, currentValue) >= 1.0;
  }

  // Check if weekly goal is achieved
  bool isWeeklyGoalAchieved(String type, double currentValue) {
    return getWeeklyProgress(type, currentValue) >= 1.0;
  }
}
