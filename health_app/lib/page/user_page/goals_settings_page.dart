import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/data_manage/tracking_data_service.dart';
import '../../models/user_goals.dart';
import '../../utils/snackbar_utils.dart';

class GoalsSettingsPage extends StatefulWidget {
  const GoalsSettingsPage({super.key});

  @override
  State<GoalsSettingsPage> createState() => _GoalsSettingsPageState();
}

class _GoalsSettingsPageState extends State<GoalsSettingsPage>
    with SingleTickerProviderStateMixin {
  final TrackingDataService _trackingService = TrackingDataService();
  late TabController _tabController;

  // Daily goals controllers
  final TextEditingController _dailyDistanceController =
      TextEditingController();
  final TextEditingController _dailyCaloriesController =
      TextEditingController();
  final TextEditingController _dailyStepsController = TextEditingController();

  // Weekly goals controllers
  final TextEditingController _weeklyDistanceController =
      TextEditingController();
  final TextEditingController _weeklyCaloriesController =
      TextEditingController();
  final TextEditingController _weeklyStepsController = TextEditingController();
  final TextEditingController _weeklyActiveDaysController =
      TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCurrentGoals();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dailyDistanceController.dispose();
    _dailyCaloriesController.dispose();
    _dailyStepsController.dispose();
    _weeklyDistanceController.dispose();
    _weeklyCaloriesController.dispose();
    _weeklyStepsController.dispose();
    _weeklyActiveDaysController.dispose();
    super.dispose();
  }

  void _loadCurrentGoals() {
    final goals = _trackingService.userGoals;

    _dailyDistanceController.text = goals.dailyDistanceGoal.toString();
    _dailyCaloriesController.text = goals.dailyCaloriesGoal.toString();
    _dailyStepsController.text = goals.dailyStepsGoal.toString();

    _weeklyDistanceController.text = goals.weeklyDistanceGoal.toString();
    _weeklyCaloriesController.text = goals.weeklyCaloriesGoal.toString();
    _weeklyStepsController.text = goals.weeklyStepsGoal.toString();
    _weeklyActiveDaysController.text = goals.weeklyActiveDaysGoal.toString();
  }

  Future<void> _saveDailyGoals() async {
    setState(() => _isLoading = true);

    try {
      final distance = double.tryParse(_dailyDistanceController.text) ?? 5.0;
      final calories = double.tryParse(_dailyCaloriesController.text) ?? 500.0;
      final steps = int.tryParse(_dailyStepsController.text) ?? 10000;

      await _trackingService.updateDailyGoals(
        distanceGoal: distance,
        caloriesGoal: calories,
        stepsGoal: steps,
      );

      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Daily goals updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Failed to update daily goals');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveWeeklyGoals() async {
    setState(() => _isLoading = true);

    try {
      final distance = double.tryParse(_weeklyDistanceController.text) ?? 30.0;
      final calories =
          double.tryParse(_weeklyCaloriesController.text) ?? 3000.0;
      final steps = int.tryParse(_weeklyStepsController.text) ?? 70000;
      final activeDays = int.tryParse(_weeklyActiveDaysController.text) ?? 5;

      await _trackingService.updateWeeklyGoals(
        distanceGoal: distance,
        caloriesGoal: calories,
        stepsGoal: steps,
        activeDaysGoal: activeDays,
      );

      if (mounted) {
        SnackBarUtils.showSuccess(
          context,
          'Weekly goals updated successfully!',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Failed to update weekly goals');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text(
          'Are you sure you want to reset all goals to default values?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _setDefaultValues();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _setDefaultValues() {
    final defaultGoals = UserGoals();

    _dailyDistanceController.text = defaultGoals.dailyDistanceGoal.toString();
    _dailyCaloriesController.text = defaultGoals.dailyCaloriesGoal.toString();
    _dailyStepsController.text = defaultGoals.dailyStepsGoal.toString();

    _weeklyDistanceController.text = defaultGoals.weeklyDistanceGoal.toString();
    _weeklyCaloriesController.text = defaultGoals.weeklyCaloriesGoal.toString();
    _weeklyStepsController.text = defaultGoals.weeklyStepsGoal.toString();
    _weeklyActiveDaysController.text = defaultGoals.weeklyActiveDaysGoal
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Goals Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _resetToDefaults,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset to defaults',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.today), text: 'Daily Goals'),
            Tab(icon: Icon(Icons.date_range), text: 'Weekly Goals'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildDailyGoalsTab(), _buildWeeklyGoalsTab()],
      ),
    );
  }

  Widget _buildDailyGoalsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Daily Goals',
            'Set your daily targets to stay motivated',
            Icons.flag,
          ),
          const SizedBox(height: 20),

          _buildGoalCard(
            'Distance Goal',
            'Target distance to walk/run per day',
            _dailyDistanceController,
            'km',
            Icons.route,
            Colors.blue,
          ),

          const SizedBox(height: 16),

          _buildGoalCard(
            'Calories Goal',
            'Target calories to burn per day',
            _dailyCaloriesController,
            'cal',
            Icons.local_fire_department,
            Colors.orange,
          ),

          const SizedBox(height: 16),

          _buildGoalCard(
            'Steps Goal',
            'Target steps to take per day',
            _dailyStepsController,
            'steps',
            Icons.directions_walk,
            Colors.green,
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveDailyGoals,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Save Daily Goals',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyGoalsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Weekly Goals',
            'Set your weekly targets for long-term progress',
            Icons.calendar_view_week,
          ),
          const SizedBox(height: 20),

          _buildGoalCard(
            'Distance Goal',
            'Target distance to cover per week',
            _weeklyDistanceController,
            'km',
            Icons.route,
            Colors.blue,
          ),

          const SizedBox(height: 16),

          _buildGoalCard(
            'Calories Goal',
            'Target calories to burn per week',
            _weeklyCaloriesController,
            'cal',
            Icons.local_fire_department,
            Colors.orange,
          ),

          const SizedBox(height: 16),

          _buildGoalCard(
            'Steps Goal',
            'Target steps to take per week',
            _weeklyStepsController,
            'steps',
            Icons.directions_walk,
            Colors.green,
          ),

          const SizedBox(height: 16),

          _buildGoalCard(
            'Active Days Goal',
            'Target active days per week',
            _weeklyActiveDaysController,
            'days',
            Icons.calendar_today,
            Colors.purple,
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveWeeklyGoals,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Save Weekly Goals',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(
    String title,
    String description,
    TextEditingController controller,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                suffixText: unit,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: color, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
