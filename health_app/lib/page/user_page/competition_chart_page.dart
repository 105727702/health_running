import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/friend_models.dart';
import '../../services/data_manage/community_service.dart';
import '../../services/authen_service/firebase_auth_service.dart';

class CompetitionChartPage extends StatefulWidget {
  const CompetitionChartPage({super.key});

  @override
  State<CompetitionChartPage> createState() => _CompetitionChartPageState();
}

class _CompetitionChartPageState extends State<CompetitionChartPage>
    with TickerProviderStateMixin {
  final CommunityService _communityService = CommunityService();
  final FirebaseAuthService _authService = FirebaseAuthService();

  late TabController _tabController;
  List<LeaderboardEntry> _weeklyLeaderboard = [];
  List<LeaderboardEntry> _monthlyLeaderboard = [];
  List<Challenge> _activeChallenges = [];
  bool _isLoading = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _getCurrentUserId();
    _loadCompetitionData();
  }

  void _getCurrentUserId() {
    final user = _authService.getCurrentFirebaseUser();
    _currentUserId = user?.uid;
  }

  Future<void> _loadCompetitionData() async {
    setState(() => _isLoading = true);

    try {
      await _communityService.initialize();

      // Load leaderboards and challenges
      _weeklyLeaderboard = await _communityService.getWeeklyLeaderboard();
      _monthlyLeaderboard = await _communityService.getMonthlyLeaderboard();
      _activeChallenges = await _communityService.getActiveChallenges();

      // Auto-update challenge progress based on user activities
      await _autoUpdateChallengeProgress();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading competition data: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Competition'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_view_week), text: 'Weekly'),
            Tab(icon: Icon(Icons.calendar_month), text: 'Monthly'),
            Tab(icon: Icon(Icons.emoji_events), text: 'Challenges'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLeaderboardTab(_weeklyLeaderboard, 'Weekly Rankings'),
                _buildLeaderboardTab(_monthlyLeaderboard, 'Monthly Rankings'),
                _buildChallengesTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateChallengeDialog,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildLeaderboardTab(
    List<LeaderboardEntry> leaderboard,
    String title,
  ) {
    return RefreshIndicator(
      onRefresh: _loadCompetitionData,
      child: Column(
        children: [
          // Stats summary card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.shade300,
                  Colors.deepPurple.shade600,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Total Players',
                      '${leaderboard.length}',
                      Icons.people,
                    ),
                    _buildStatItem(
                      'Your Rank',
                      _getUserRank(leaderboard) == leaderboard.length + 1
                          ? 'N/A'
                          : '#${_getUserRank(leaderboard)}',
                      Icons.star,
                    ),
                    _buildStatItem(
                      'Your Score',
                      _getCurrentUserScore().toString(),
                      Icons.emoji_events,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Leaderboard list
          Expanded(
            child: leaderboard.isEmpty
                ? _buildEmptyLeaderboard()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: leaderboard.length,
                    itemBuilder: (context, index) {
                      return _buildLeaderboardCard(
                        leaderboard[index],
                        index + 1,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildLeaderboardCard(LeaderboardEntry entry, int rank) {
    final isCurrentUser = entry.userId == _currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.deepPurple.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: Colors.deepPurple, width: 2)
            : Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getRankColor(rank),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: rank <= 3
                ? Icon(_getRankIcon(rank), color: Colors.white, size: 20)
                : Text(
                    rank.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        title: Text(
          entry.userName,
          style: TextStyle(
            fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
            color: isCurrentUser ? Colors.deepPurple : Colors.black87,
          ),
        ),
        subtitle: Text(
          '${entry.stats.totalDistance.toInt()} km • ${entry.stats.totalSessions} sessions',
          style: TextStyle(
            color: isCurrentUser
                ? Colors.deepPurple.shade700
                : Colors.grey.shade600,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${entry.stats.competitionScore.toInt()} pts',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isCurrentUser ? Colors.deepPurple : Colors.black87,
              ),
            ),
            if (entry.stats.activeDays > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '🔥 ${entry.stats.activeDays}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengesTab() {
    return RefreshIndicator(
      onRefresh: _loadCompetitionData,
      child: _activeChallenges.isEmpty
          ? _buildEmptyChallenges()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _activeChallenges.length,
              itemBuilder: (context, index) {
                return _buildChallengeCard(_activeChallenges[index]);
              },
            ),
    );
  }

  Widget _buildChallengeCard(Challenge challenge) {
    // Get current user's progress for this challenge
    final currentProgress =
        challenge.participantProgress[_currentUserId] ?? 0.0;
    final progress = currentProgress / challenge.targetValue;
    final isCompleted = progress >= 1.0;
    final isParticipating =
        _currentUserId != null &&
        challenge.participantIds.contains(_currentUserId);
    final isCreator =
        _currentUserId != null &&
        challenge.participantIds.isNotEmpty &&
        challenge.participantIds.first == _currentUserId;

    return GestureDetector(
      onTap: () => _showChallengeDetails(challenge),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isChallengeExpired(challenge)
                ? Colors.grey.shade300
                : _getChallengeStatusColor(challenge),
            width: _isChallengeExpired(challenge) ? 1 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Challenge header with title and action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isCreator)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Creator',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.deepPurple.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      if (_isChallengeExpired(challenge))
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Expired',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isParticipating &&
                        _currentUserId != null &&
                        !_isChallengeExpired(challenge))
                      ElevatedButton(
                        onPressed: () => _joinChallenge(challenge.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        child: const Text(
                          'Join',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    if (isParticipating &&
                        _currentUserId != null &&
                        !_isChallengeExpired(challenge)) ...[
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'leave') {
                            _showLeaveChallengeConfirmation(challenge);
                          } else if (value == 'delete' && isCreator) {
                            _showDeleteChallengeConfirmation(challenge);
                          }
                        },
                        itemBuilder: (context) => [
                          if (!isCreator)
                            const PopupMenuItem(
                              value: 'leave',
                              child: Row(
                                children: [
                                  Icon(Icons.exit_to_app, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Text('Leave Challenge'),
                                ],
                              ),
                            ),
                          if (isCreator)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete Challenge'),
                                ],
                              ),
                            ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.more_vert,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Challenge description
            Text(
              challenge.description,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),

            const SizedBox(height: 12),

            // Progress section (only show if participating)
            if (isParticipating) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Progress',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    '${currentProgress.toStringAsFixed(1)} / ${challenge.targetValue.toStringAsFixed(0)} ${_getChallengeUnit(challenge.type)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? Colors.green : Colors.deepPurple,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? Colors.green : Colors.deepPurple,
                ),
              ),

              const SizedBox(height: 12),
            ],

            // Challenge details
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  _getDaysRemaining(challenge),
                  style: TextStyle(
                    color: _isChallengeExpired(challenge)
                        ? Colors.red.shade600
                        : Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: _isChallengeExpired(challenge)
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.blue.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${challenge.participantIds.length} participants',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyLeaderboard() {
    return RefreshIndicator(
      onRefresh: _loadCompetitionData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: 400,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.leaderboard, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No rankings yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start tracking activities to see rankings',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
                const SizedBox(height: 24),
                Text(
                  'Pull down to refresh',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChallenges() {
    return RefreshIndicator(
      onRefresh: _loadCompetitionData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: 400,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No active challenges',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a challenge to compete with friends',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _showCreateChallengeDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Challenge'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateChallengeDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final targetController = TextEditingController();
    ChallengeType selectedType = ChallengeType.distance;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Challenge'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Challenge Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ChallengeType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Challenge Type',
                    border: OutlineInputBorder(),
                  ),
                  items: ChallengeType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getChallengeTypeLabel(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: targetController,
                  decoration: InputDecoration(
                    labelText: 'Target ${_getChallengeUnit(selectedType)}',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a challenge title'),
                    ),
                  );
                  return;
                }

                final targetValue = double.tryParse(targetController.text);
                if (targetValue == null || targetValue <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid target value'),
                    ),
                  );
                  return;
                }

                _createChallenge(
                  titleController.text.trim(),
                  descriptionController.text.trim(),
                  selectedType,
                  targetValue,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createChallenge(
    String title,
    String description,
    ChallengeType type,
    double target,
  ) async {
    if (_currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to create challenges')),
        );
      }
      return;
    }

    try {
      await _communityService.createChallenge(title, description, type, target);
      _loadCompetitionData(); // Refresh data
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Challenge created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating challenge: $e')));
      }
    }
  }

  Future<void> _joinChallenge(String challengeId) async {
    if (_currentUserId == null) return;

    try {
      await _communityService.joinChallenge(challengeId, _currentUserId!);
      await _loadCompetitionData(); // Refresh data
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joined challenge successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error joining challenge: $e')));
      }
    }
  }

  Future<void> _leaveChallenge(String challengeId) async {
    if (_currentUserId == null) return;

    try {
      await _communityService.leaveChallenge(challengeId, _currentUserId!);
      await _loadCompetitionData(); // Refresh data
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Left challenge successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error leaving challenge: $e')));
      }
    }
  }

  Future<void> _deleteChallenge(String challengeId) async {
    if (_currentUserId == null) return;

    try {
      final success = await _communityService.deleteChallenge(
        challengeId,
        _currentUserId!,
      );
      if (success) {
        await _loadCompetitionData(); // Refresh data
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Challenge deleted successfully!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can only delete challenges you created'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting challenge: $e')));
      }
    }
  }

  // Auto-update challenge progress based on user activities
  Future<void> _autoUpdateChallengeProgress() async {
    if (_currentUserId == null) return;

    try {
      // Get user's current stats from Firestore
      final userStatsDoc = await FirebaseFirestore.instance
          .collection('user_stats')
          .doc(_currentUserId)
          .get();

      if (!userStatsDoc.exists) return;

      final stats = userStatsDoc.data() as Map<String, dynamic>;

      // Update progress for all challenges user is participating in
      for (final challenge in _activeChallenges) {
        if (challenge.participantIds.contains(_currentUserId)) {
          double currentProgress = 0.0;

          switch (challenge.type) {
            case ChallengeType.distance:
              currentProgress =
                  (stats['totalDistance'] as num?)?.toDouble() ?? 0.0;
              currentProgress *= 1000; // Convert km to meters
              break;
            case ChallengeType.calories:
              currentProgress =
                  (stats['totalCalories'] as num?)?.toDouble() ?? 0.0;
              break;
            case ChallengeType.steps:
              currentProgress =
                  (stats['totalSteps'] as num?)?.toDouble() ?? 0.0;
              break;
            case ChallengeType.sessions:
              currentProgress =
                  (stats['totalSessions'] as num?)?.toDouble() ?? 0.0;
              break;
          }

          // Only update if progress has increased
          final oldProgress =
              challenge.participantProgress[_currentUserId] ?? 0.0;
          if (currentProgress > oldProgress) {
            await _communityService.updateChallengeProgress(
              challenge.id,
              _currentUserId!,
              currentProgress,
            );
          }
        }
      }
    } catch (e) {
      // Silently handle errors in auto-update
      print('Error auto-updating challenge progress: $e');
    }
  }

  // Helper methods
  int _getUserRank(List<LeaderboardEntry> leaderboard) {
    if (_currentUserId == null) return leaderboard.length + 1;

    for (int i = 0; i < leaderboard.length; i++) {
      if (leaderboard[i].userId == _currentUserId) {
        return i + 1;
      }
    }
    return leaderboard.length + 1;
  }

  int _getCurrentUserScore() {
    if (_currentUserId == null) return 0;

    // Find current user in weekly leaderboard
    for (final entry in _weeklyLeaderboard) {
      if (entry.userId == _currentUserId) {
        return entry.stats.competitionScore.toInt();
      }
    }
    return 0;
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.orange.shade400;
      default:
        return Colors.deepPurple;
    }
  }

  IconData _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return Icons.emoji_events;
      case 2:
        return Icons.military_tech;
      case 3:
        return Icons.workspace_premium;
      default:
        return Icons.star;
    }
  }

  String _getChallengeTypeLabel(ChallengeType type) {
    switch (type) {
      case ChallengeType.distance:
        return 'Distance';
      case ChallengeType.calories:
        return 'Calories';
      case ChallengeType.steps:
        return 'Steps';
      case ChallengeType.sessions:
        return 'Sessions';
    }
  }

  String _getChallengeUnit(ChallengeType type) {
    switch (type) {
      case ChallengeType.distance:
        return 'km';
      case ChallengeType.calories:
        return 'calories';
      case ChallengeType.steps:
        return 'steps';
      case ChallengeType.sessions:
        return 'sessions';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference > 0) {
      return 'In $difference days';
    } else {
      return '${-difference} days ago';
    }
  }

  // Show challenge details dialog
  void _showChallengeDetails(Challenge challenge) {
    final isParticipating =
        _currentUserId != null &&
        challenge.participantIds.contains(_currentUserId);
    final isCreator =
        _currentUserId != null &&
        challenge.participantIds.isNotEmpty &&
        challenge.participantIds.first == _currentUserId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Expanded(child: Text(challenge.name)),
            if (isCreator)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Creator',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.deepPurple.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(challenge.description),
              const SizedBox(height: 16),
              Text(
                'Target: ${challenge.targetValue.toStringAsFixed(0)} ${_getChallengeUnit(challenge.type)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Start: ${_formatDate(challenge.startDate)}'),
              Text('End: ${_formatDate(challenge.endDate)}'),
              const SizedBox(height: 16),
              Text(
                'Participants (${challenge.participantIds.length})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // Show participants with better formatting
              ...challenge.participantProgress.entries.map((entry) {
                final progress = entry.value / challenge.targetValue * 100;
                final isCurrentUserEntry = entry.key == _currentUserId;
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrentUserEntry
                        ? Colors.deepPurple.shade50
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: isCurrentUserEntry
                        ? Border.all(color: Colors.deepPurple.shade200)
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isCurrentUserEntry
                              ? 'You'
                              : 'User ${entry.key.substring(0, 8)}...',
                          style: TextStyle(
                            fontWeight: isCurrentUserEntry
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isCurrentUserEntry
                                ? Colors.deepPurple
                                : Colors.black87,
                          ),
                        ),
                      ),
                      Text(
                        '${progress.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: progress >= 100
                              ? Colors.green
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (!isParticipating && _currentUserId != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _joinChallenge(challenge.id);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Join'),
            ),
          if (isParticipating && !isCreator)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showLeaveChallengeConfirmation(challenge);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Leave'),
            ),
          if (isCreator)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showDeleteChallengeConfirmation(challenge);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
        ],
      ),
    );
  }

  void _showLeaveChallengeConfirmation(Challenge challenge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Challenge'),
        content: Text(
          'Are you sure you want to leave "${challenge.name}"? Your progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _leaveChallenge(challenge.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _showDeleteChallengeConfirmation(Challenge challenge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Challenge'),
        content: Text(
          'Are you sure you want to delete "${challenge.name}"? This action cannot be undone and will remove the challenge for all participants.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteChallenge(challenge.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Helper method to check if challenge is expired
  bool _isChallengeExpired(Challenge challenge) {
    return DateTime.now().isAfter(challenge.endDate);
  }

  // Helper method to get challenge status color
  Color _getChallengeStatusColor(Challenge challenge) {
    if (_isChallengeExpired(challenge)) {
      return Colors.grey;
    }

    final currentProgress =
        challenge.participantProgress[_currentUserId] ?? 0.0;
    final progress = currentProgress / challenge.targetValue;

    if (progress >= 1.0) {
      return Colors.green;
    } else if (progress >= 0.7) {
      return Colors.orange;
    } else {
      return Colors.deepPurple;
    }
  }

  // Helper method to get days remaining
  String _getDaysRemaining(Challenge challenge) {
    final now = DateTime.now();
    final difference = challenge.endDate.difference(now).inDays;

    if (difference < 0) {
      return 'Expired';
    } else if (difference == 0) {
      return 'Ends today';
    } else if (difference == 1) {
      return '1 day left';
    } else {
      return '$difference days left';
    }
  }
}
