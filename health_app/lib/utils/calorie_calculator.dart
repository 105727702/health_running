class CalorieCalculator {
  static const Map<String, double> _calorieRates = {
    'walking': 0.5,
    'running': 1.0,
    'cycling': 0.3,
  };

  // Calculate calories burned based on distance and user weight
  static double calculateCalories({
    required double distanceKm,
    required double userWeight,
    required String activityType,
  }) {
    double calorieRate = _calorieRates[activityType] ?? 0.5;
    return distanceKm * userWeight * calorieRate;
  }

  // Get available activity types
  static List<String> getActivityTypes() {
    return _calorieRates.keys.toList();
  }

  // Get calorie rate for activity
  static double getCalorieRate(String activityType) {
    return _calorieRates[activityType] ?? 0.5;
  }
}
