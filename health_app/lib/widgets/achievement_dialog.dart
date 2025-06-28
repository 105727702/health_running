import 'package:flutter/material.dart';

class AchievementDialog extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const AchievementDialog({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  static void show(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AchievementDialog(
        title: title,
        description: description,
        icon: icon,
        color: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Achievement icon with animation
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 600),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 3),
                    ),
                    child: Icon(icon, size: 40, color: color),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Congratulations text
            Text(
              '🎉 Congratulations! 🎉',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Achievement title
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Achievement description
            Text(
              description,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Awesome!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Achievement manager to track and show achievements
class AchievementManager {
  static final Set<String> _shownAchievements = {};

  static void checkDailyGoalAchievements(
    BuildContext context,
    Map<String, bool> achievements,
  ) {
    final now = DateTime.now().toIso8601String().split(
      'T',
    )[0]; // Get date part only

    if (achievements['distance'] == true &&
        !_shownAchievements.contains('daily_distance_$now')) {
      _shownAchievements.add('daily_distance_$now');
      Future.delayed(const Duration(milliseconds: 500), () {
        AchievementDialog.show(
          context,
          title: 'Daily Distance Goal Achieved!',
          description:
              'You\'ve completed your daily distance goal. Keep it up!',
          icon: Icons.route,
          color: Colors.blue,
        );
      });
    }

    if (achievements['calories'] == true &&
        !_shownAchievements.contains('daily_calories_$now')) {
      _shownAchievements.add('daily_calories_$now');
      Future.delayed(const Duration(milliseconds: 800), () {
        AchievementDialog.show(
          context,
          title: 'Daily Calories Goal Achieved!',
          description: 'Great job burning those calories today!',
          icon: Icons.local_fire_department,
          color: Colors.orange,
        );
      });
    }

    if (achievements['steps'] == true &&
        !_shownAchievements.contains('daily_steps_$now')) {
      _shownAchievements.add('daily_steps_$now');
      Future.delayed(const Duration(milliseconds: 1100), () {
        AchievementDialog.show(
          context,
          title: 'Daily Steps Goal Achieved!',
          description: 'You\'ve reached your daily steps target. Fantastic!',
          icon: Icons.directions_walk,
          color: Colors.green,
        );
      });
    }
  }

  static void checkWeeklyGoalAchievements(
    BuildContext context,
    Map<String, bool> achievements,
  ) {
    // Get week number to avoid showing same achievement multiple times in a week
    final now = DateTime.now();
    final weekNumber = ((now.difference(DateTime(now.year, 1, 1)).inDays) / 7)
        .floor();
    final weekKey = '${now.year}_$weekNumber';

    if (achievements['distance'] == true &&
        !_shownAchievements.contains('weekly_distance_$weekKey')) {
      _shownAchievements.add('weekly_distance_$weekKey');
      Future.delayed(const Duration(milliseconds: 500), () {
        AchievementDialog.show(
          context,
          title: 'Weekly Distance Goal Achieved!',
          description: 'Amazing! You\'ve completed your weekly distance goal.',
          icon: Icons.route,
          color: Colors.blue,
        );
      });
    }

    if (achievements['calories'] == true &&
        !_shownAchievements.contains('weekly_calories_$weekKey')) {
      _shownAchievements.add('weekly_calories_$weekKey');
      Future.delayed(const Duration(milliseconds: 800), () {
        AchievementDialog.show(
          context,
          title: 'Weekly Calories Goal Achieved!',
          description: 'Excellent work on your weekly calorie burning goal!',
          icon: Icons.local_fire_department,
          color: Colors.orange,
        );
      });
    }

    if (achievements['steps'] == true &&
        !_shownAchievements.contains('weekly_steps_$weekKey')) {
      _shownAchievements.add('weekly_steps_$weekKey');
      Future.delayed(const Duration(milliseconds: 1100), () {
        AchievementDialog.show(
          context,
          title: 'Weekly Steps Goal Achieved!',
          description: 'You\'ve crushed your weekly steps target!',
          icon: Icons.directions_walk,
          color: Colors.green,
        );
      });
    }

    if (achievements['activeDays'] == true &&
        !_shownAchievements.contains('weekly_active_$weekKey')) {
      _shownAchievements.add('weekly_active_$weekKey');
      Future.delayed(const Duration(milliseconds: 1400), () {
        AchievementDialog.show(
          context,
          title: 'Weekly Active Days Goal Achieved!',
          description:
              'Great consistency! You\'ve hit your weekly active days goal.',
          icon: Icons.calendar_today,
          color: Colors.purple,
        );
      });
    }
  }
}
