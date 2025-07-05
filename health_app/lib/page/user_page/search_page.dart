import 'package:flutter/material.dart';
import '../../services/data_manage/community_service.dart';
import '../../models/friend_models.dart';
import 'settings_page.dart';
import 'competition_chart_page.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage>
    with TickerProviderStateMixin {
  final CommunityService _communityService = CommunityService();
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;
  List<Friend> _friends = [];
  List<FriendRequest> _friendRequests = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeCommunity();
  }

  Future<void> _initializeCommunity() async {
    setState(() => _isLoading = true);

    await _communityService.initialize();

    // Listen to streams
    _communityService.friendsStream.listen((friends) {
      if (mounted) {
        setState(() {
          _friends = friends;
        });
      }
    });

    _communityService.friendRequestsStream.listen((requests) {
      if (mounted) {
        setState(() {
          _friendRequests = requests;
        });
      }
    });

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CompetitionChartPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(icon: Icon(Icons.people), text: 'Friends (${_friends.length})'),
            Tab(
              icon: Icon(Icons.person_add),
              text:
                  'Requests (${_friendRequests.where((r) => r.status == FriendRequestStatus.pending).length})',
            ),
            const Tab(icon: Icon(Icons.search), text: 'Find Friends'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFriendsTab(),
                _buildRequestsTab(),
                _buildSearchTab(),
              ],
            ),
    );
  }

  Widget _buildFriendsTab() {
    if (_friends.isEmpty) {
      return _buildEmptyFriendsState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        _communityService.refreshData();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _friends.length + 1, // +1 for leaderboard card
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildQuickLeaderboardCard();
          }

          final friend = _friends[index - 1];
          return _buildFriendCard(friend);
        },
      ),
    );
  }

  Widget _buildQuickLeaderboardCard() {
    final leaderboard = _communityService.getWeeklyLeaderboard();
    final topThree = leaderboard.take(3).toList();
    final currentUserRank = _communityService.getCurrentUserRank();

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Weekly Leaderboard',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CompetitionChartPage(),
                      ),
                    );
                  },
                  icon: Icon(Icons.arrow_forward, size: 16),
                  label: Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Your rank
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, color: Colors.deepPurple),
                  const SizedBox(width: 8),
                  Text(
                    'Your Rank: #$currentUserRank',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const Spacer(),
                  if (currentUserRank <= 3)
                    Icon(
                      currentUserRank == 1
                          ? Icons.looks_one
                          : currentUserRank == 2
                          ? Icons.looks_two
                          : Icons.looks_3,
                      color: currentUserRank == 1
                          ? Colors.amber
                          : currentUserRank == 2
                          ? Colors.grey
                          : Colors.brown,
                    ),
                ],
              ),
            ),

            if (topThree.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Top 3 This Week',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              ...topThree.asMap().entries.map((entry) {
                final index = entry.key;
                final leader = entry.value;
                return _buildMiniLeaderItem(leader, index + 1);
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMiniLeaderItem(LeaderboardEntry leader, int rank) {
    final Color rankColor = rank == 1
        ? Colors.amber
        : rank == 2
        ? Colors.grey
        : Colors.brown;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: leader.isCurrentUser
            ? Colors.deepPurple.withOpacity(0.1)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: leader.isCurrentUser
            ? Border.all(color: Colors.deepPurple.withOpacity(0.3))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: rankColor, shape: BoxShape.circle),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              leader.isCurrentUser ? 'You' : leader.userName,
              style: TextStyle(
                fontWeight: leader.isCurrentUser
                    ? FontWeight.bold
                    : FontWeight.w500,
                color: leader.isCurrentUser
                    ? Colors.deepPurple
                    : Colors.black87,
              ),
            ),
          ),
          Text(
            '${leader.stats.totalDistance.toStringAsFixed(1)} km',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFriendsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Friends Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find and add friends to start competing!',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _tabController.animateTo(2); // Switch to search tab
            },
            icon: Icon(Icons.person_add),
            label: Text('Find Friends'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab() {
    if (_friendRequests.isEmpty) {
      return _buildEmptyRequestsState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _friendRequests.length,
      itemBuilder: (context, index) {
        final request = _friendRequests[index];
        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildSearchTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by email or name...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              // Implement search logic here
              if (value.isNotEmpty) {
                _performSearch(value);
              } else {
                setState(() {
                  _searchResults = [];
                });
              }
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _searchResults.isEmpty
                ? _buildEmptySearchState()
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      return _buildSearchResultCard(user);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendCard(Friend friend) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: friend.photoUrl != null
              ? NetworkImage(friend.photoUrl!)
              : null,
          child: friend.photoUrl == null
              ? Text(
                  friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
                )
              : null,
        ),
        title: Text(friend.name),
        subtitle: friend.currentWeekStats != null
            ? Text(
                '${friend.currentWeekStats!.totalDistance.toStringAsFixed(1)}km this week',
              )
            : const Text('No activity this week'),
        trailing: friend.isOnline
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Online',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              )
            : null,
        onTap: () {
          // Show friend details
        },
      ),
    );
  }

  Widget _buildRequestCard(FriendRequest request) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            request.fromUserName.isNotEmpty
                ? request.fromUserName[0].toUpperCase()
                : '?',
          ),
        ),
        title: Text(request.fromUserName),
        subtitle: Text(request.fromUserEmail),
        trailing: request.status == FriendRequestStatus.pending
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () => _acceptFriendRequest(request.id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => _declineFriendRequest(request.id),
                  ),
                ],
              )
            : Text(request.status.toString().split('.').last),
      ),
    );
  }

  Widget _buildSearchResultCard(Map<String, dynamic> user) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            user['name']?.isNotEmpty == true
                ? user['name'][0].toUpperCase()
                : '?',
          ),
        ),
        title: Text(user['name'] ?? 'Unknown'),
        subtitle: Text(user['email'] ?? ''),
        trailing: ElevatedButton(
          onPressed: () => _sendFriendRequest(user['id']),
          child: const Text('Add Friend'),
        ),
      ),
    );
  }

  Widget _buildEmptyRequestsState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_add, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No Friend Requests',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'You\'ll see friend requests here',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Search for Friends',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Enter email or name to find friends',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    try {
      // Use real search from Firestore
      final results = await _communityService.searchUsers(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      print('Error searching users: $e');
      setState(() {
        _searchResults = [];
      });
    }
  }

  void _sendFriendRequest(String userId) async {
    final user = _searchResults.firstWhere((u) => u['id'] == userId);
    await _communityService.sendFriendRequest(
      userId,
      user['name'] ?? 'Unknown',
      user['email'] ?? '',
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Friend request sent!')));
  }

  void _acceptFriendRequest(String requestId) async {
    await _communityService.acceptFriendRequest(requestId);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Friend request accepted!')));
  }

  void _declineFriendRequest(String requestId) async {
    await _communityService.rejectFriendRequest(requestId);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Friend request declined.')));
  }
}
