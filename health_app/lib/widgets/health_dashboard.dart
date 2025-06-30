import 'package:flutter/material.dart';
import '../services/data_manage/tracking_data_service.dart';
import '../page/user_page/history_page.dart';
import '../page/user_page/goals_settings_page.dart';
import '../page/admin_page/data_management_page.dart';
import '../widgets/achievement_dialog.dart';

class HealthDashboard extends StatefulWidget {
  const HealthDashboard({super.key});

  @override
  State<HealthDashboard> createState() => _HealthDashboardState();
}

class _HealthDashboardState extends State<HealthDashboard> {
  final TrackingDataService _trackingService = TrackingDataService();

  @override
  void initState() {
    super.initState();
    // Ensure data is refreshed when widget is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _trackingService.refreshData();
      }
    });
  }

  @override
  void didUpdateWidget(HealthDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh data when widget is updated
    _trackingService.refreshData();
  }

  void _checkGoalAchievements() {
    final dailyAchievements = _trackingService.getDailyGoalsAchieved();
    AchievementManager.checkDailyGoalAchievements(context, dailyAchievements);

    final weeklyProgress = _trackingService.getWeeklyGoalsProgress();
    final weeklyAchievements = weeklyProgress.map(
      (key, value) => MapEntry(key, value >= 1.0),
    );
    AchievementManager.checkWeeklyGoalAchievements(context, weeklyAchievements);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _trackingService.initialized,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading health data...',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Error loading data',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please try restarting the app',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return StreamBuilder(
          stream: _trackingService.trackingStateStream,
          builder: (context, streamSnapshot) {
            // Check for goal achievements
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _checkGoalAchievements();
              }
            });

            return _buildDashboardContent();
          },
        );
      },
    );
  }

  Widget _buildDashboardContent() {
    final weeklySummary = _trackingService.getWeeklySummary();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Daily Overview Card
          _buildDailyOverviewCard(),
          const SizedBox(height: 16),

          // Current Session Card (if tracking)
          if (_trackingService.currentState.isTracking) ...[
            _buildCurrentSessionCard(),
            const SizedBox(height: 16),
          ],

          // Weekly Summary Card
          _buildWeeklySummaryCard(weeklySummary),
          const SizedBox(height: 16),

          // Weekly Goals Progress
          _buildWeeklyGoalsCard(weeklySummary),
          const SizedBox(height: 16),

          // Activity History
          _buildActivityHistoryCard(),
          const SizedBox(height: 16),

          // Progress Chart
          _buildProgressChartCard(),
          const SizedBox(height: 16),

          // Quick Actions
          _buildQuickActionsCard(),
        ],
      ),
    );
  }

  Widget _buildDailyOverviewCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.today, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Today\'s Progress',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildDailyStat(
                      'Distance',
                      '${_trackingService.dailyDistance.toStringAsFixed(2)} km',
                      Icons.route,
                      Colors.blue.shade300,
                    ),
                  ),
                  Expanded(
                    child: _buildDailyStat(
                      'Calories',
                      '${_trackingService.dailyCalories.toStringAsFixed(0)} cal',
                      Icons.local_fire_department,
                      Colors.orange.shade300,
                    ),
                  ),
                  Expanded(
                    child: _buildDailyStat(
                      'Steps',
                      '${_trackingService.dailySteps}',
                      Icons.directions_walk,
                      Colors.green.shade300,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyStat(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(title, style: TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  Widget _buildCurrentSessionCard() {
    final currentState = _trackingService.currentState;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.radio_button_checked,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Current Session',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                Spacer(),
                Text(
                  currentState.activityType.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSessionStat(
                    'Distance',
                    '${currentState.totalDistance.toStringAsFixed(2)} km',
                    Icons.route,
                  ),
                ),
                Expanded(
                  child: _buildSessionStat(
                    'Calories',
                    '${currentState.totalCalories.toStringAsFixed(0)} cal',
                    Icons.local_fire_department,
                  ),
                ),
                Expanded(
                  child: _buildSessionStat(
                    'Route Points',
                    '${currentState.route.length}',
                    Icons.timeline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionStat(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.deepPurple, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildWeeklySummaryCard(WeeklySummary summary) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.date_range, color: Colors.deepPurple, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Weekly Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildWeeklyStat(
                    'Total Distance',
                    '${summary.totalDistance.toStringAsFixed(1)} km',
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildWeeklyStat(
                    'Total Calories',
                    '${summary.totalCalories.toStringAsFixed(0)} cal',
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildWeeklyStat(
                    'Active Days',
                    '${summary.activeDays}/7',
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildWeeklyStat(
                    'Avg. Daily',
                    '${summary.averageDistance.toStringAsFixed(1)} km',
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyStat(String title, String value, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyGoalsCard(WeeklySummary summary) {
    final weeklyGoals = _trackingService.userGoals;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assignment_turned_in,
                  color: Colors.deepPurple,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Weekly Goals Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildWeeklyGoalProgress(
              'Distance',
              summary.totalDistance,
              weeklyGoals.weeklyDistanceGoal,
              'km',
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildWeeklyGoalProgress(
              'Calories',
              summary.totalCalories,
              weeklyGoals.weeklyCaloriesGoal,
              'cal',
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildWeeklyGoalProgress(
              'Steps',
              summary.totalSteps.toDouble(),
              weeklyGoals.weeklyStepsGoal.toDouble(),
              'steps',
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildWeeklyGoalProgress(
              'Active Days',
              summary.activeDays.toDouble(),
              weeklyGoals.weeklyActiveDaysGoal.toDouble(),
              'days',
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyGoalProgress(
    String title,
    double current,
    double goal,
    String unit,
    Color color,
  ) {
    final progress = (current / goal).clamp(0.0, 1.0);
    final isAchieved = progress >= 1.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAchieved
            ? color.withOpacity(0.1)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAchieved
              ? color.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (isAchieved)
                    Icon(Icons.check_circle, color: color, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isAchieved ? color : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isAchieved ? color : Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${current.toStringAsFixed(unit == 'steps' || unit == 'days' ? 0 : 1)} / ${goal.toStringAsFixed(unit == 'steps' || unit == 'days' ? 0 : 1)} $unit',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityHistoryCard() {
    final sessions = _trackingService.todaySessions;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.deepPurple, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Today\'s Activities',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistoryPage(),
                      ),
                    );
                  },
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (sessions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Icon(Icons.directions_walk, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        'No activities today',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        'Go to Map tab to start tracking!',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...sessions.map((session) => _buildSessionItem(session)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionItem(TrackingSession session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              session.activityType == 'running'
                  ? Icons.directions_run
                  : Icons.directions_walk,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.activityType.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                Text(
                  '${session.distance.toStringAsFixed(2)} km • ${session.calories.toStringAsFixed(0)} cal',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            '${session.duration} min',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChartCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.deepPurple, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Progress Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GoalsSettingsPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings),
                  color: Colors.deepPurple,
                  tooltip: 'Goal Settings',
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Simple progress bars for daily goals
            _buildProgressBar(
              'Daily Distance Goal',
              _trackingService.dailyDistance,
              _trackingService.userGoals.dailyDistanceGoal,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildProgressBar(
              'Daily Calories Goal',
              _trackingService.dailyCalories,
              _trackingService.userGoals.dailyCaloriesGoal,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildProgressBar(
              'Daily Steps Goal',
              _trackingService.dailySteps.toDouble(),
              _trackingService.userGoals.dailyStepsGoal.toDouble(),
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(
    String title,
    double current,
    double goal,
    Color color,
  ) {
    final progress = (current / goal).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${current.toStringAsFixed(title.contains('Steps') ? 0 : 1)} / ${goal.toStringAsFixed(title.contains('Steps') ? 0 : 1)}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: Colors.deepPurple, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    'Goals',
                    Icons.flag,
                    Colors.purple,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GoalsSettingsPage(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    'Data',
                    Icons.storage,
                    Colors.orange,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DataManagementPage(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    'History',
                    Icons.history,
                    Colors.blue,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistoryPage(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
