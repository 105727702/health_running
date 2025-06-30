import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/data_manage/firebase_data_service.dart';
import '../../services/data_manage/hybrid_data_service.dart';
import '../../services/authen_service/role_service.dart';
import '../../widgets/custom_edit_test_dialog.dart';

class FirebaseTestPage extends StatefulWidget {
  const FirebaseTestPage({super.key});

  @override
  State<FirebaseTestPage> createState() => _FirebaseTestPageState();
}

class _FirebaseTestPageState extends State<FirebaseTestPage> {
  final FirebaseDataService _firebaseService = FirebaseDataService();
  final HybridDataService _hybridService = HybridDataService();
  final RoleService _roleService = RoleService();
  bool _isLoading = false;
  String _status = 'Ready to test Firebase';
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final isAdmin = await _roleService.isCurrentUserAdmin();
    setState(() {
      _isAdmin = isAdmin;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Test & Data Management'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.deepPurple.withOpacity(0.3),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Status Card
              Card(
                elevation: 4,
                shadowColor: Colors.deepPurple.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple.withOpacity(0.05),
                        Colors.deepPurple.withOpacity(0.02),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: Colors.deepPurple,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'User Status',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: Colors.deepPurple,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildStatusRow(
                          icon: user != null
                              ? Icons.check_circle
                              : Icons.cancel,
                          iconColor: user != null ? Colors.green : Colors.red,
                          label: 'Signed in',
                          value: '${user != null}',
                        ),
                        if (user != null) ...[
                          const SizedBox(height: 8),
                          _buildStatusRow(
                            icon: Icons.key,
                            iconColor: Colors.blue,
                            label: 'UID',
                            value: user.uid.substring(0, 20) + '...',
                          ),
                          const SizedBox(height: 8),
                          _buildStatusRow(
                            icon: Icons.email,
                            iconColor: Colors.orange,
                            label: 'Email',
                            value: user.email ?? 'No email',
                          ),
                          const SizedBox(height: 8),
                          _buildStatusRow(
                            icon: _isAdmin
                                ? Icons.admin_panel_settings
                                : Icons.person,
                            iconColor: _isAdmin ? Colors.purple : Colors.grey,
                            label: 'Role',
                            value: _isAdmin ? 'Admin' : 'User',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Firebase Status Card
              Card(
                elevation: 4,
                shadowColor: Colors.deepPurple.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withOpacity(0.05),
                        Colors.blue.withOpacity(0.02),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.cloud_done,
                              color: Colors.blue,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Firebase Status',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            _status,
                            style: const TextStyle(fontSize: 13, height: 1.4),
                          ),
                        ),
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Test Functions Card
              Card(
                elevation: 4,
                shadowColor: Colors.green.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.withOpacity(0.05),
                        Colors.green.withOpacity(0.02),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.play_circle,
                              color: Colors.green,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Test Functions',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Data Test Buttons
                        _buildTestButton(
                          onPressed: _showCurrentData,
                          icon: Icons.info,
                          label: 'Show Current App Data',
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 12),
                        _buildTestButton(
                          onPressed: user == null ? null : _testSaveSession,
                          icon: Icons.save,
                          label: 'Test Save Session',
                          color: Colors.green,
                        ),
                        const SizedBox(height: 12),
                        _buildTestButton(
                          onPressed: user == null ? null : _testGetSessions,
                          icon: Icons.list,
                          label: 'Test Get Sessions',
                          color: Colors.purple,
                        ),
                        const SizedBox(height: 12),

                        // Auto-save and Backup
                        _buildTestButton(
                          onPressed: _showAutoSaveStatus,
                          icon: Icons.schedule,
                          label: 'Show Auto-Save Status',
                          color: Colors.indigo,
                        ),
                        const SizedBox(height: 12),
                        _buildTestButton(
                          onPressed: user == null ? null : _manualBackup,
                          icon: Icons.cloud_upload,
                          label: 'Manual Backup to Firebase',
                          color: Colors.deepOrange,
                        ),
                        const SizedBox(height: 16),

                        // Divider
                        Divider(color: Colors.grey.shade300),
                        const SizedBox(height: 16),

                        // Data Management Section Header
                        Row(
                          children: [
                            Icon(
                              Icons.manage_history,
                              color: Colors.red,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Data Management',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Edit and Delete Functions (Admin Only)
                        if (_isAdmin) ...[
                          _buildTestButton(
                            onPressed: user == null ? null : _testEditData,
                            icon: Icons.edit,
                            label: 'Custom Session Creator/Editor (Admin)',
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 12),
                          _buildTestButton(
                            onPressed: user == null ? null : _testDeleteData,
                            icon: Icons.delete_outline,
                            label: 'Test Delete Session from Firebase',
                            color: Colors.red,
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Edit/Delete functions are restricted to admin users only',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Instructions Card
              Card(
                elevation: 4,
                shadowColor: Colors.amber.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.withOpacity(0.05),
                        Colors.amber.withOpacity(0.02),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.help_outline,
                              color: Colors.amber[700],
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'How to Test Delete & Edit',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: Colors.amber[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInstructionStep(
                          '1',
                          'Make sure you are signed in as Admin',
                        ),
                        _buildInstructionStep(
                          '2',
                          'Create test sessions using "Test Save Session"',
                        ),
                        _buildInstructionStep(
                          '3',
                          'Use "Custom Edit Session Test" to modify with your own values',
                        ),
                        _buildInstructionStep(
                          '4',
                          'Use "Test Delete Session" to remove data',
                        ),
                        _buildInstructionStep(
                          '5',
                          'Check Firebase Console to verify changes',
                        ),
                        _buildInstructionStep(
                          '6',
                          'Go to History page to use the full edit/delete UI',
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _testSaveSession() async {
    setState(() {
      _isLoading = true;
      _status = 'Creating test session...';
    });

    try {
      final now = DateTime.now();
      await _firebaseService.saveTrackingSession(
        distance: 2.5,
        calories: 180,
        duration: 25,
        activityType: 'walking',
        startTime: now.subtract(const Duration(minutes: 25)),
        endTime: now,
        route: [
          {'latitude': 10.762622, 'longitude': 106.660172},
          {'latitude': 10.763622, 'longitude': 106.661172},
        ],
      );

      setState(() {
        _status =
            '✅ Test session created!\nDistance: 2.5 km\nCalories: 180\nDuration: 25 min';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Failed to create session: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testGetSessions() async {
    setState(() {
      _isLoading = true;
      _status = 'Getting sessions from Firebase...';
    });

    try {
      final sessions = await _firebaseService.getDailySessions(DateTime.now());
      setState(() {
        _status =
            '📋 Found ${sessions.length} sessions for today.\n'
            'You can now test edit/delete functions.';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Failed to get sessions: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testEditData() async {
    setState(() {
      _isLoading = true;
      _status = 'Preparing edit test...';
    });

    try {
      final todaySessions = await _firebaseService.getDailySessions(
        DateTime.now(),
      );

      setState(() => _isLoading = false);

      // Show custom edit dialog (works even without existing sessions)
      await showDialog(
        context: context,
        builder: (context) => CustomEditTestDialog(
          existingSession: todaySessions.isNotEmpty
              ? todaySessions.first
              : null,
          onUpdate:
              (sessionId, distance, calories, duration, activityType) async {
                if (todaySessions.isNotEmpty) {
                  // Edit existing session
                  await _performCustomEditTest(
                    sessionId.isEmpty
                        ? todaySessions.first['id'] as String
                        : sessionId,
                    distance,
                    calories,
                    duration,
                    activityType,
                    todaySessions.first,
                  );
                } else {
                  // Create new session with custom values
                  await _createCustomTestSession(
                    distance,
                    calories,
                    duration,
                    activityType,
                  );
                }
              },
        ),
      );
    } catch (e) {
      setState(() {
        _status = '❌ Failed to prepare edit test: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createCustomTestSession(
    double distance,
    double calories,
    int duration,
    String activityType,
  ) async {
    setState(() {
      _isLoading = true;
      _status = 'Creating custom test session...';
    });

    try {
      final now = DateTime.now();
      await _firebaseService.saveTrackingSession(
        distance: distance,
        calories: calories,
        duration: duration,
        activityType: activityType,
        startTime: now.subtract(Duration(minutes: duration)),
        endTime: now,
        route: [
          {'latitude': 10.762622, 'longitude': 106.660172},
          {'latitude': 10.763622, 'longitude': 106.661172},
        ],
      );

      setState(() {
        _status =
            '✅ CUSTOM SESSION CREATED!\n\n'
            '🆕 New session with your custom values:\n'
            '• Distance: ${distance.toStringAsFixed(2)} km\n'
            '• Calories: ${calories.toStringAsFixed(0)} cal\n'
            '• Duration: $duration min\n'
            '• Activity: $activityType\n\n'
            '🔥 Check Firebase Console to verify!';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Custom session creation failed: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _performCustomEditTest(
    String sessionId,
    double newDistance,
    double newCalories,
    int newDuration,
    String newActivityType,
    Map<String, dynamic> originalSession,
  ) async {
    setState(() {
      _isLoading = true;
      _status = 'Performing custom edit test...';
    });

    try {
      // Get original values for comparison
      final originalDistance = (originalSession['distance'] as num).toDouble();
      final originalCalories = (originalSession['calories'] as num).toDouble();
      final originalDuration = originalSession['duration'] as int;
      final originalActivityType = originalSession['activityType'] as String;

      await _firebaseService.updateSession(
        sessionId: sessionId,
        distance: newDistance,
        calories: newCalories,
        duration: newDuration,
        activityType: newActivityType,
        startTime: DateTime.parse(originalSession['startTime'] as String),
        endTime: DateTime.parse(originalSession['endTime'] as String),
        route: originalSession['route'] as List<dynamic>,
      );

      setState(() {
        _status =
            '✅ CUSTOM EDIT TEST SUCCESSFUL!\n\n'
            'Session updated with your custom values:\n\n'
            '📊 CHANGES MADE:\n'
            '• Distance: ${originalDistance.toStringAsFixed(2)} → ${newDistance.toStringAsFixed(2)} km\n'
            '• Calories: ${originalCalories.toStringAsFixed(0)} → ${newCalories.toStringAsFixed(0)} cal\n'
            '• Duration: $originalDuration → $newDuration min\n'
            '• Activity: $originalActivityType → $newActivityType\n\n'
            '🔥 Check Firebase Console to verify changes!';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Custom edit test failed: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testDeleteData() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing delete functionality...';
    });

    try {
      final todaySessions = await _firebaseService.getDailySessions(
        DateTime.now(),
      );

      if (todaySessions.isEmpty) {
        setState(() {
          _status =
              '⚠️ No sessions found. Create some test sessions first using "Test Save Session".';
        });
        return;
      }

      final sessionToDelete = todaySessions.first;
      final sessionId = sessionToDelete['id'] as String;
      final distance = sessionToDelete['distance'];
      final calories = sessionToDelete['calories'];

      await _firebaseService.deleteSession(sessionId);

      setState(() {
        _status =
            '✅ DELETE TEST SUCCESSFUL!\n\n'
            'Deleted session:\n'
            '• Distance: $distance km\n'
            '• Calories: $calories\n'
            '• Activity: ${sessionToDelete['activityType']}\n\n'
            'Session permanently removed from Firebase.\n'
            'Check Firebase Console to verify deletion.';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Delete test failed: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showCurrentData() {
    final savedDistance = _hybridService.dailyDistance;
    final savedCalories = _hybridService.dailyCalories;
    final savedSteps = _hybridService.dailySteps;
    final savedSessions = _hybridService.todaySessions;

    setState(() {
      _status =
          '📊 CURRENT APP DATA\n\n'
          '📏 Distance: ${savedDistance.toStringAsFixed(2)} km\n'
          '🔥 Calories: ${savedCalories.round()}\n'
          '👣 Steps: $savedSteps\n'
          '📊 Sessions: ${savedSessions.length}\n\n'
          'This data will be saved to Firebase when you complete tracking sessions.';
    });
  }

  void _showAutoSaveStatus() {
    final status = _hybridService.getAutoSaveStatus();

    setState(() {
      _status =
          '⏰ AUTO-SAVE STATUS\n\n'
          '🔐 Enabled: ${status['isEnabled']}\n'
          '🌙 Next Reset: ${status['nextDailyReset']}\n'
          '🔄 Next Sync: ${status['nextPeriodicSync']}\n'
          '📦 Offline Queue: ${status['offlineQueueCount']} items\n\n'
          '💡 Your data is automatically backed up daily and hourly.';
    });
  }

  Future<void> _manualBackup() async {
    setState(() {
      _isLoading = true;
      _status = 'Performing manual backup...';
    });

    try {
      await _hybridService.manualBackupToFirebase();
      setState(() {
        _status =
            '✅ Manual backup completed!\nAll data safely stored in Firebase.';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Backup failed: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Helper methods
  Widget _buildStatusRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTestButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
          shadowColor: color.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.amber[700],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
