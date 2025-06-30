import 'package:flutter/material.dart';
import '../../services/data_monitoring/analytics_dashboard_service.dart';
import '../../services/data_monitoring/analytics_test_data_service.dart';
import '../../models/analytics_models.dart';
import '../../utils/firebase_utils.dart';

class AnalyticsDashboardPage extends StatefulWidget {
  const AnalyticsDashboardPage({super.key});

  @override
  State<AnalyticsDashboardPage> createState() => _AnalyticsDashboardPageState();
}

class _AnalyticsDashboardPageState extends State<AnalyticsDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AnalyticsDashboardService _analyticsService =
      AnalyticsDashboardService();

  bool _isLoading = true;
  UserOverviewData? _userOverview;
  WorkoutStats? _workoutStats;
  List<DailyActivityData> _dailyActivity = [];
  List<TopUserData> _topUsers = [];
  CrashSummaryData? _crashSummary;
  List<AppEventData> _recentEvents = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDashboardData();
    FirebaseUtils.trackScreenView('analytics_dashboard');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _analyticsService.getUserOverview(),
        _analyticsService.getWorkoutStats(),
        _analyticsService.getDailyActivity(days: 7),
        _analyticsService.getTopUsers(limit: 10),
        _analyticsService.getCrashSummary(days: 30),
        _analyticsService.getAppEvents(days: 7),
      ]);

      setState(() {
        _userOverview = results[0] as UserOverviewData;
        _workoutStats = results[1] as WorkoutStats;
        _dailyActivity = results[2] as List<DailyActivityData>;
        _topUsers = results[3] as List<TopUserData>;
        _crashSummary = results[4] as CrashSummaryData;
        _recentEvents = results[5] as List<AppEventData>;
        _isLoading = false;
      });

      await FirebaseUtils.trackButtonTap(
        'dashboard_loaded',
        screenName: 'analytics_dashboard',
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading dashboard: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateTestData() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating test data...'),
            ],
          ),
        ),
      );

      await AnalyticsTestDataService().generateTestData();

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test data generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadDashboardData(); // Refresh data
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating test data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearTestData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Test Data'),
        content: const Text(
          'Are you sure you want to clear all test data? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Clearing test data...'),
            ],
          ),
        ),
      );

      await AnalyticsTestDataService().clearTestData();

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test data cleared successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadDashboardData(); // Refresh data
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing test data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              switch (value) {
                case 'refresh':
                  await _loadDashboardData();
                  break;
                case 'generate_test_data':
                  await _generateTestData();
                  break;
                case 'clear_test_data':
                  await _clearTestData();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Refresh Data'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'generate_test_data',
                child: Row(
                  children: [
                    Icon(Icons.data_usage),
                    SizedBox(width: 8),
                    Text('Generate Test Data'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_test_data',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear Test Data'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.trending_up), text: 'Activity'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.bug_report), text: 'Issues'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.deepOrange),
                  SizedBox(height: 16),
                  Text('Loading analytics data...'),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildActivityTab(),
                _buildUsersTab(),
                _buildIssuesTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: Colors.deepOrange,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Users',
                    '${_userOverview?.totalUsers ?? 0}',
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Active Users',
                    '${_userOverview?.activeUsers ?? 0}',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'New Users',
                    '${_userOverview?.newUsers ?? 0}',
                    Icons.person_add,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Admins',
                    '${_userOverview?.totalAdmins ?? 0}',
                    Icons.admin_panel_settings,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Workout Stats
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.fitness_center, color: Colors.deepOrange),
                        const SizedBox(width: 8),
                        const Text(
                          'Workout Statistics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildWorkoutStat(
                          'Sessions',
                          '${_workoutStats?.totalSessions ?? 0}',
                        ),
                        _buildWorkoutStat(
                          'Distance',
                          '${(_workoutStats?.totalDistance ?? 0).toStringAsFixed(1)} km',
                        ),
                        _buildWorkoutStat(
                          'Calories',
                          '${(_workoutStats?.totalCalories ?? 0).toStringAsFixed(0)}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Daily Activity Chart
            if (_dailyActivity.isNotEmpty) _buildDailyActivityChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Activity Chart
          if (_dailyActivity.isNotEmpty) _buildDailyActivityChart(),
          const SizedBox(height: 24),

          // Recent Events
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.timeline, color: Colors.deepOrange),
                      const SizedBox(width: 8),
                      const Text(
                        'Recent Events',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_recentEvents.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No recent events found'),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recentEvents.length.clamp(0, 10),
                      itemBuilder: (context, index) {
                        final event = _recentEvents[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepOrange.withOpacity(0.1),
                            child: Icon(
                              _getEventIcon(event.eventName),
                              color: Colors.deepOrange,
                              size: 20,
                            ),
                          ),
                          title: Text(event.eventName),
                          subtitle: Text(
                            '${event.screenName} • ${event.timeString}',
                          ),
                          trailing: Text(
                            event.dateString,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Users
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.leaderboard, color: Colors.deepOrange),
                      const SizedBox(width: 8),
                      const Text(
                        'Top Users by Distance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_topUsers.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No user data available'),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _topUsers.length,
                      itemBuilder: (context, index) {
                        final user = _topUsers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getRankColor(index),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(user.userName),
                          subtitle: Text('${user.totalWorkouts} workouts'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${user.totalDistance.toStringAsFixed(1)} km',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${user.totalCalories.toStringAsFixed(0)} cal',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssuesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Crash Summary
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bug_report, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        'Crash Summary (${_crashSummary?.period ?? 30} days)',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStatCard(
                    'Total Crashes',
                    '${_crashSummary?.totalCrashes ?? 0}',
                    Icons.error,
                    Colors.red,
                  ),
                  const SizedBox(height: 16),

                  // Top Crash Types
                  if (_crashSummary?.topCrashTypes.isNotEmpty ?? false) ...[
                    const Text(
                      'Top Crash Types',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._crashSummary!.topCrashTypes.map(
                      (entry) => ListTile(
                        leading: Icon(
                          Icons.error_outline,
                          color: Colors.red[300],
                        ),
                        title: Text(entry.key),
                        trailing: Text('${entry.value}'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepOrange,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildDailyActivityChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, color: Colors.deepOrange),
                const SizedBox(width: 8),
                const Text(
                  'Daily Activity (7 days)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(height: 200, child: _buildSimpleBarChart()),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleBarChart() {
    if (_dailyActivity.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final maxValue = _dailyActivity
        .map((e) => e.workoutSessions)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: _dailyActivity.map((data) {
        final height = maxValue > 0
            ? (data.workoutSessions / maxValue * 150).clamp(20.0, 150.0)
            : 20.0;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '${data.workoutSessions}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 30,
              height: height,
              decoration: BoxDecoration(
                color: Colors.deepOrange,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Text(data.dateString, style: const TextStyle(fontSize: 12)),
          ],
        );
      }).toList(),
    );
  }

  IconData _getEventIcon(String eventName) {
    switch (eventName.toLowerCase()) {
      case 'screen_view':
        return Icons.visibility;
      case 'button_tap':
        return Icons.touch_app;
      case 'workout_start':
        return Icons.play_arrow;
      case 'workout_end':
        return Icons.stop;
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      default:
        return Icons.event;
    }
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber; // Gold
      case 1:
        return Colors.grey; // Silver
      case 2:
        return Colors.brown; // Bronze
      default:
        return Colors.deepOrange;
    }
  }
}
