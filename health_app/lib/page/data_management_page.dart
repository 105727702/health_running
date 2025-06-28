import 'package:flutter/material.dart';
import '../services/tracking_data_service.dart';
import '../utils/snackbar_utils.dart';

class DataManagementPage extends StatefulWidget {
  const DataManagementPage({super.key});

  @override
  State<DataManagementPage> createState() => _DataManagementPageState();
}

class _DataManagementPageState extends State<DataManagementPage> {
  final TrackingDataService _trackingService = TrackingDataService();
  bool _isLoading = false;

  Future<void> _clearTodayData() async {
    final confirmed = await _showConfirmationDialog(
      title: 'Clear Today\'s Data',
      message:
          'Are you sure you want to clear all of today\'s activities and progress? This action cannot be undone.',
      confirmText: 'Clear Today',
      icon: Icons.today,
      color: Colors.orange,
    );

    if (confirmed) {
      setState(() => _isLoading = true);
      try {
        await _trackingService.clearTodayData();
        if (mounted) {
          SnackBarUtils.showSuccess(
            context,
            'Today\'s data cleared successfully!',
          );
        }
      } catch (e) {
        if (mounted) {
          SnackBarUtils.showError(context, 'Failed to clear today\'s data');
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _clearHistoricalData() async {
    final confirmed = await _showConfirmationDialog(
      title: 'Clear Historical Data',
      message:
          'Are you sure you want to clear all historical data? This will remove all past activities but keep today\'s progress. This action cannot be undone.',
      confirmText: 'Clear History',
      icon: Icons.history,
      color: Colors.blue,
    );

    if (confirmed) {
      setState(() => _isLoading = true);
      try {
        await _trackingService.clearHistoricalData();
        if (mounted) {
          SnackBarUtils.showSuccess(
            context,
            'Historical data cleared successfully!',
          );
        }
      } catch (e) {
        if (mounted) {
          SnackBarUtils.showError(context, 'Failed to clear historical data');
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await _showConfirmationDialog(
      title: 'Clear All Data',
      message:
          'Are you sure you want to clear ALL data including today\'s progress and all historical activities? This action cannot be undone.',
      confirmText: 'Clear All',
      icon: Icons.delete_forever,
      color: Colors.red,
    );

    if (confirmed) {
      setState(() => _isLoading = true);
      try {
        await _trackingService.clearAllHistoryAndReset();
        if (mounted) {
          SnackBarUtils.showSuccess(context, 'All data cleared successfully!');
        }
      } catch (e) {
        if (mounted) {
          SnackBarUtils.showError(context, 'Failed to clear all data');
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetGoals() async {
    final confirmed = await _showConfirmationDialog(
      title: 'Reset Goals',
      message:
          'Are you sure you want to reset all goals to their default values?',
      confirmText: 'Reset Goals',
      icon: Icons.flag,
      color: Colors.purple,
    );

    if (confirmed) {
      setState(() => _isLoading = true);
      try {
        await _trackingService.resetGoalsToDefault();
        if (mounted) {
          SnackBarUtils.showSuccess(context, 'Goals reset to default values!');
        }
      } catch (e) {
        if (mounted) {
          SnackBarUtils.showError(context, 'Failed to reset goals');
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _completeReset() async {
    final confirmed = await _showConfirmationDialog(
      title: 'Complete Reset',
      message:
          'Are you sure you want to perform a complete reset? This will:\n\n• Clear all activity data\n• Clear all historical data\n• Reset all goals to defaults\n\nThis action cannot be undone and will restore the app to its initial state.',
      confirmText: 'Complete Reset',
      icon: Icons.refresh,
      color: Colors.red,
      isDestructive: true,
    );

    if (confirmed) {
      setState(() => _isLoading = true);
      try {
        await _trackingService.completeReset();
        if (mounted) {
          SnackBarUtils.showSuccess(
            context,
            'Complete reset performed successfully!',
          );
        }
      } catch (e) {
        if (mounted) {
          SnackBarUtils.showError(context, 'Failed to perform complete reset');
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
    required IconData icon,
    required Color color,
    bool isDestructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
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
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: const TextStyle(fontSize: 14)),
                if (isDestructive) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This action is irreversible!',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(confirmText),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Data Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.deepPurple,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Processing...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    'Data Management',
                    'Manage your activity data and progress',
                    Icons.storage,
                  ),
                  const SizedBox(height: 20),

                  // Clear Today's Data
                  _buildActionCard(
                    title: 'Clear Today\'s Data',
                    description:
                        'Remove all activities and progress from today only',
                    icon: Icons.today,
                    color: Colors.orange,
                    onTap: _clearTodayData,
                  ),

                  const SizedBox(height: 12),

                  // Clear Historical Data
                  _buildActionCard(
                    title: 'Clear Historical Data',
                    description:
                        'Remove all past activities but keep today\'s progress',
                    icon: Icons.history,
                    color: Colors.blue,
                    onTap: _clearHistoricalData,
                  ),

                  const SizedBox(height: 12),

                  // Clear All Data
                  _buildActionCard(
                    title: 'Clear All Data',
                    description:
                        'Remove ALL activity data including today and history',
                    icon: Icons.delete_forever,
                    color: Colors.red,
                    onTap: _clearAllData,
                    isDestructive: true,
                  ),

                  const SizedBox(height: 24),

                  _buildSectionHeader(
                    'Goals Management',
                    'Reset your goals and targets',
                    Icons.flag,
                  ),
                  const SizedBox(height: 20),

                  // Reset Goals
                  _buildActionCard(
                    title: 'Reset Goals',
                    description:
                        'Reset all daily and weekly goals to default values',
                    icon: Icons.flag,
                    color: Colors.purple,
                    onTap: _resetGoals,
                  ),

                  const SizedBox(height: 24),

                  _buildSectionHeader(
                    'Complete Reset',
                    'Start fresh with all default settings',
                    Icons.refresh,
                  ),
                  const SizedBox(height: 20),

                  // Complete Reset
                  _buildActionCard(
                    title: 'Complete Reset',
                    description:
                        'Reset everything: data, goals, and settings to defaults',
                    icon: Icons.refresh,
                    color: Colors.red,
                    onTap: _completeReset,
                    isDestructive: true,
                  ),

                  const SizedBox(height: 32),

                  // Info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Important Note',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'All reset actions are permanent and cannot be undone. Make sure you really want to proceed before confirming.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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

  Widget _buildActionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDestructive ? color : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
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
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
