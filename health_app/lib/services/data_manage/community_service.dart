import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/friend_models.dart';
import 'tracking_data_service.dart';

class CommunityService {
  static final CommunityService _instance = CommunityService._internal();
  factory CommunityService() => _instance;
  CommunityService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TrackingDataService _trackingService = TrackingDataService();

  // Stream controllers
  final StreamController<List<Friend>> _friendsController =
      StreamController<List<Friend>>.broadcast();
  final StreamController<List<FriendRequest>> _friendRequestsController =
      StreamController<List<FriendRequest>>.broadcast();

  // Data storage
  List<Friend> _friends = [];
  List<FriendRequest> _friendRequests = [];
  Map<String, WeeklyStats> _friendsWeeklyStats = {};
  List<Challenge> _challenges = [];

  // Getters
  Stream<List<Friend>> get friendsStream => _friendsController.stream;
  Stream<List<FriendRequest>> get friendRequestsStream =>
      _friendRequestsController.stream;
  List<Friend> get friends => List.unmodifiable(_friends);
  List<FriendRequest> get pendingRequests => _friendRequests
      .where((req) => req.status == FriendRequestStatus.pending)
      .toList();

  // Initialize service
  Future<void> initialize() async {
    // Load local data first to show something immediately
    await _loadLocalData();

    // Emit current local data immediately (even if empty)
    _friendsController.add(_friends);
    _friendRequestsController.add(_friendRequests);

    // Then load fresh data from Firestore
    await _loadRealFriendsFromFirestore();
    _updateWeeklyStats();
  }

  // Load real friends from Firestore instead of mock data
  Future<void> _loadRealFriendsFromFirestore() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('No current user found, cannot load friends');
        _friends = [];
        _friendRequests = [];
        _friendsController.add(_friends);
        _friendRequestsController.add(_friendRequests);
        return;
      }

      print('Loading friends for user: ${currentUser.uid}');

      // Load friends from Firestore user_friends collection
      final friendsSnapshot = await _firestore
          .collection('user_friends')
          .doc(currentUser.uid)
          .collection('friends')
          .get();

      List<Friend> realFriends = [];

      for (var doc in friendsSnapshot.docs) {
        try {
          // Get friend's user data from users collection
          final friendData = await _firestore
              .collection('users')
              .doc(doc.id)
              .get();

          if (friendData.exists) {
            final userData = friendData.data()!;
            realFriends.add(
              Friend(
                id: doc.id,
                name: userData['displayName'] ?? userData['name'] ?? 'Unknown',
                email: userData['email'] ?? '',
                photoUrl: userData['photoURL'],
                friendSince:
                    (doc.data()['friendSince'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
                isOnline: userData['isOnline'] ?? false,
              ),
            );
          }
        } catch (e) {
          print('Error loading friend ${doc.id}: $e');
        }
      }

      _friends = realFriends;

      // Load real friend requests
      await _loadRealFriendRequests();

      print(
        'Loaded ${_friends.length} friends and ${_friendRequests.length} friend requests',
      );

      _friendsController.add(_friends);
      _friendRequestsController.add(_friendRequests);

      await _saveLocalData();
    } catch (e) {
      print('Error loading real friends: $e');
      // Fallback to empty list instead of mock data
      _friends = [];
      _friendRequests = [];

      // Still emit empty data to update UI
      _friendsController.add(_friends);
      _friendRequestsController.add(_friendRequests);
    }
  }

  // Load real friend requests from Firestore
  Future<void> _loadRealFriendRequests() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final requestsSnapshot = await _firestore
          .collection('friend_requests')
          .where('toUserId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      List<FriendRequest> realRequests = [];

      for (var doc in requestsSnapshot.docs) {
        try {
          final data = doc.data();
          realRequests.add(
            FriendRequest(
              id: doc.id,
              fromUserId: data['fromUserId'] ?? '',
              fromUserName: data['fromUserName'] ?? 'Unknown',
              fromUserEmail: data['fromUserEmail'] ?? '',
              toUserId: data['toUserId'] ?? '',
              toUserName: data['toUserName'] ?? '',
              toUserEmail: data['toUserEmail'] ?? '',
              createdAt:
                  (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              status: FriendRequestStatus.values.firstWhere(
                (e) => e.toString().split('.').last == data['status'],
                orElse: () => FriendRequestStatus.pending,
              ),
              message: data['message'],
            ),
          );
        } catch (e) {
          print('Error loading friend request ${doc.id}: $e');
        }
      }

      _friendRequests = realRequests;
    } catch (e) {
      print('Error loading friend requests: $e');
      _friendRequests = [];
    }
  }

  // Search for real users in Firestore
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      List<Map<String, dynamic>> results = [];

      // Search by email (exact match)
      if (query.contains('@')) {
        final emailQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: query.toLowerCase())
            .limit(10)
            .get();

        for (var doc in emailQuery.docs) {
          if (doc.id != currentUser.uid) {
            final data = doc.data();
            final friendshipStatus = await getFriendshipStatus(doc.id);

            results.add({
              'id': doc.id,
              'name': data['displayName'] ?? data['name'] ?? 'Unknown User',
              'email': data['email'] ?? '',
              'photoUrl': data['photoURL'],
              'friendshipStatus': friendshipStatus,
              'isAlreadyFriend': friendshipStatus == 'friends',
              'hasPendingRequest': friendshipStatus == 'pending',
            });
          }
        }
      }

      // Search by display name (partial match)
      final nameQuery = await _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThan: query + '\uf8ff')
          .limit(10)
          .get();

      for (var doc in nameQuery.docs) {
        if (doc.id != currentUser.uid) {
          final data = doc.data();
          final friendshipStatus = await getFriendshipStatus(doc.id);

          final userMap = {
            'id': doc.id,
            'name': data['displayName'] ?? data['name'] ?? 'Unknown User',
            'email': data['email'] ?? '',
            'photoUrl': data['photoURL'],
            'friendshipStatus': friendshipStatus,
            'isAlreadyFriend': friendshipStatus == 'friends',
            'hasPendingRequest': friendshipStatus == 'pending',
          };

          // Avoid duplicates
          if (!results.any((r) => r['id'] == userMap['id'])) {
            results.add(userMap);
          }
        }
      }

      return results;
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // Check if user is already a friend - check both local and Firestore to be sure
  bool _isAlreadyFriend(String userId) {
    return _friends.any((friend) => friend.id == userId);
  }

  // More thorough check including Firestore verification
  Future<bool> isAlreadyFriendInFirestore(String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final friendDoc = await _firestore
          .collection('user_friends')
          .doc(currentUser.uid)
          .collection('friends')
          .doc(userId)
          .get();

      return friendDoc.exists;
    } catch (e) {
      print('Error checking friendship in Firestore: $e');
      return false;
    }
  }

  // Save current user profile to Firestore (call this after login/signup)
  Future<void> saveCurrentUserProfile() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _firestore.collection('users').doc(currentUser.uid).set({
        'email': currentUser.email,
        'displayName':
            currentUser.displayName ?? currentUser.email?.split('@')[0],
        'name': currentUser.displayName ?? currentUser.email?.split('@')[0],
        'photoURL': currentUser.photoURL,
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving user profile: $e');
    }
  }

  // Ensure user profile exists in Firestore (especially for Google Sign-in users)
  Future<void> ensureUserProfile() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final userDocRef = _firestore.collection('users').doc(currentUser.uid);
      final userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        // Create user profile if it doesn't exist
        await userDocRef.set({
          'uid': currentUser.uid,
          'email': currentUser.email ?? '',
          'displayName':
              currentUser.displayName ??
              currentUser.email?.split('@')[0] ??
              'Unknown User',
          'name':
              currentUser.displayName ??
              currentUser.email?.split('@')[0] ??
              'Unknown User',
          'photoURL': currentUser.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing profile with latest info and online status
        await userDocRef.update({
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
          'photoURL': currentUser.photoURL,
          'displayName':
              currentUser.displayName ?? userDoc.data()?['displayName'],
        });
      }
    } catch (e) {
      print('Error ensuring user profile: $e');
    }
  }

  // Update user online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _firestore.collection('users').doc(currentUser.uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating online status: $e');
    }
  }

  // Load data from SharedPreferences
  Future<void> _loadLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load friends
      final friendsJson = prefs.getString('community_friends');
      if (friendsJson != null) {
        final List<dynamic> friendsList = jsonDecode(friendsJson);
        _friends = friendsList.map((json) => Friend.fromJson(json)).toList();
      }

      // Load friend requests
      final requestsJson = prefs.getString('community_requests');
      if (requestsJson != null) {
        final List<dynamic> requestsList = jsonDecode(requestsJson);
        _friendRequests = requestsList
            .map((json) => FriendRequest.fromJson(json))
            .toList();
      }

      // Load weekly stats
      final statsJson = prefs.getString('community_weekly_stats');
      if (statsJson != null) {
        final Map<String, dynamic> statsMap = jsonDecode(statsJson);
        _friendsWeeklyStats = statsMap.map(
          (key, value) => MapEntry(key, WeeklyStats.fromJson(value)),
        );
      }

      // Load challenges
      final challengesJson = prefs.getString('community_challenges');
      if (challengesJson != null) {
        final List<dynamic> challengesList = jsonDecode(challengesJson);
        _challenges = challengesList
            .map((json) => Challenge.fromJson(json))
            .toList();
      }
    } catch (e) {
      print('Error loading community data: $e');
    }
  }

  // Save data to SharedPreferences
  Future<void> _saveLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save friends
      await prefs.setString(
        'community_friends',
        jsonEncode(_friends.map((f) => f.toJson()).toList()),
      );

      // Save friend requests
      await prefs.setString(
        'community_requests',
        jsonEncode(_friendRequests.map((r) => r.toJson()).toList()),
      );

      // Save weekly stats
      await prefs.setString(
        'community_weekly_stats',
        jsonEncode(_friendsWeeklyStats.map((k, v) => MapEntry(k, v.toJson()))),
      );

      // Save challenges
      await prefs.setString(
        'community_challenges',
        jsonEncode(_challenges.map((c) => c.toJson()).toList()),
      );
    } catch (e) {
      print('Error saving community data: $e');
    }
  }

  // Update weekly stats for all friends
  void _updateWeeklyStats() {
    final random = Random();
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    // Update current user's stats from tracking service
    final currentUserWeekly = _trackingService.getWeeklySummary();
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      _friendsWeeklyStats[currentUser.uid] = WeeklyStats(
        totalDistance: currentUserWeekly.totalDistance,
        totalCalories: currentUserWeekly.totalCalories,
        totalSteps: currentUserWeekly.totalSteps,
        activeDays: currentUserWeekly.activeDays,
        totalSessions: _trackingService.todaySessions.length,
        weekStartDate: weekStart,
        weekEndDate: weekEnd,
      );
    }

    // Generate mock stats for friends (only for existing real friends)
    for (final friend in _friends) {
      if (!_friendsWeeklyStats.containsKey(friend.id)) {
        _friendsWeeklyStats[friend.id] = WeeklyStats(
          totalDistance: 5.0 + random.nextDouble() * 25.0, // 5-30 km
          totalCalories: (400 + random.nextInt(1200))
              .toDouble(), // 400-1600 calories
          totalSteps: 8000 + random.nextInt(12000), // 8k-20k steps
          activeDays: 3 + random.nextInt(5), // 3-7 days
          totalSessions: 3 + random.nextInt(8), // 3-10 sessions
          weekStartDate: weekStart,
          weekEndDate: weekEnd,
        );
      }
    }

    // Update friends with their stats
    _friends = _friends.map((friend) {
      return friend.copyWith(
        currentWeekStats: _friendsWeeklyStats[friend.id],
        isOnline: random.nextBool(), // Random online status
      );
    }).toList();

    _friendsController.add(_friends);
    _friendRequestsController.add(_friendRequests);
    _saveLocalData();
  }

  // Send friend request to Firestore
  Future<bool> sendFriendRequest(
    String toUserId,
    String toUserName,
    String toUserEmail, {
    String? message,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Create friend request in Firestore
      await _firestore.collection('friend_requests').add({
        'fromUserId': currentUser.uid,
        'fromUserName': currentUser.displayName ?? 'You',
        'fromUserEmail': currentUser.email ?? '',
        'toUserId': toUserId,
        'toUserName': toUserName,
        'toUserEmail': toUserEmail,
        'status': 'pending',
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Refresh data to ensure UI shows correct status
      await _loadRealFriendRequests();
      _friendRequestsController.add(_friendRequests);

      print('✅ Friend request sent to $toUserName ($toUserId)');
      return true;
    } catch (e) {
      print('Error sending friend request: $e');
      return false;
    }
  }

  // Accept friend request in Firestore
  Future<bool> acceptFriendRequest(String requestId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Get the request document
      final requestDoc = await _firestore
          .collection('friend_requests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) return false;

      final requestData = requestDoc.data()!;

      // Update request status to accepted
      await _firestore.collection('friend_requests').doc(requestId).update({
        'status': 'accepted',
      });

      // Add to both users' friends collections
      final batch = _firestore.batch();

      // Add friend to current user's friends
      final currentUserFriendRef = _firestore
          .collection('user_friends')
          .doc(currentUser.uid)
          .collection('friends')
          .doc(requestData['fromUserId']);

      batch.set(currentUserFriendRef, {
        'friendSince': FieldValue.serverTimestamp(),
        'addedAt': FieldValue.serverTimestamp(),
      });

      // Add current user to friend's friends
      final friendUserFriendRef = _firestore
          .collection('user_friends')
          .doc(requestData['fromUserId'])
          .collection('friends')
          .doc(currentUser.uid);

      batch.set(friendUserFriendRef, {
        'friendSince': FieldValue.serverTimestamp(),
        'addedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // Refresh local data
      await _loadRealFriendsFromFirestore();

      return true;
    } catch (e) {
      print('Error accepting friend request: $e');
      return false;
    }
  }

  // Reject friend request in Firestore
  Future<bool> rejectFriendRequest(String requestId) async {
    try {
      // Update request status to rejected
      await _firestore.collection('friend_requests').doc(requestId).update({
        'status': 'rejected',
      });

      // Refresh local data
      await _loadRealFriendRequests();
      _friendRequestsController.add(_friendRequests);

      return true;
    } catch (e) {
      print('Error rejecting friend request: $e');
      return false;
    }
  }

  // Remove friend
  Future<bool> removeFriend(String friendId) async {
    try {
      // Remove from Firestore first
      final success = await removeFriendshipFromFirestore(friendId);
      if (!success) return false;

      // Remove from local data (already done in removeFriendshipFromFirestore)
      _friendsWeeklyStats.remove(friendId);

      // Emit updated data to streams
      _friendsController.add(_friends);
      await _saveLocalData();

      print('✅ Friend removed: $friendId');
      return true;
    } catch (e) {
      print('Error removing friend: $e');
      return false;
    }
  }

  // Remove friendship relationship from Firestore (when unfriending)
  Future<bool> removeFriendshipFromFirestore(String friendId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final batch = _firestore.batch();

      // Remove friend from current user's friends collection
      final currentUserFriendRef = _firestore
          .collection('user_friends')
          .doc(currentUser.uid)
          .collection('friends')
          .doc(friendId);

      // Remove current user from friend's friends collection
      final friendUserFriendRef = _firestore
          .collection('user_friends')
          .doc(friendId)
          .collection('friends')
          .doc(currentUser.uid);

      batch.delete(currentUserFriendRef);
      batch.delete(friendUserFriendRef);

      await batch.commit();

      // Refresh local data
      await _loadRealFriendsFromFirestore();

      print('✅ Friendship removed between ${currentUser.uid} and $friendId');
      return true;
    } catch (e) {
      print('❌ Error removing friendship: $e');
      return false;
    }
  }

  // Get leaderboard
  List<LeaderboardEntry> getWeeklyLeaderboard() {
    final currentUser = _auth.currentUser;
    final entries = <LeaderboardEntry>[];

    // Add current user
    if (currentUser != null &&
        _friendsWeeklyStats.containsKey(currentUser.uid)) {
      entries.add(
        LeaderboardEntry(
          userId: currentUser.uid,
          userName: currentUser.displayName ?? 'You',
          stats: _friendsWeeklyStats[currentUser.uid]!,
          rank: 0,
          isCurrentUser: true,
        ),
      );
    }

    // Add friends
    for (final friend in _friends) {
      if (_friendsWeeklyStats.containsKey(friend.id)) {
        entries.add(
          LeaderboardEntry(
            userId: friend.id,
            userName: friend.name,
            photoUrl: friend.photoUrl,
            stats: _friendsWeeklyStats[friend.id]!,
            rank: 0,
            isCurrentUser: false,
          ),
        );
      }
    }

    // Sort by competition score and assign ranks
    entries.sort(
      (a, b) => b.stats.competitionScore.compareTo(a.stats.competitionScore),
    );
    for (int i = 0; i < entries.length; i++) {
      entries[i] = LeaderboardEntry(
        userId: entries[i].userId,
        userName: entries[i].userName,
        photoUrl: entries[i].photoUrl,
        stats: entries[i].stats,
        rank: i + 1,
        isCurrentUser: entries[i].isCurrentUser,
      );
    }

    return entries;
  }

  // Get current user's rank
  int getCurrentUserRank() {
    final leaderboard = getWeeklyLeaderboard();
    final userEntry = leaderboard.firstWhere(
      (entry) => entry.isCurrentUser,
      orElse: () => LeaderboardEntry(
        userId: '',
        userName: '',
        stats: WeeklyStats(
          totalDistance: 0,
          totalCalories: 0,
          totalSteps: 0,
          activeDays: 0,
          totalSessions: 0,
          weekStartDate: DateTime.now(),
          weekEndDate: DateTime.now(),
        ),
        rank: -1,
      ),
    );
    return userEntry.rank;
  }

  // Get monthly leaderboard (for now, use weekly stats as monthly)
  Future<List<LeaderboardEntry>> getMonthlyLeaderboard() async {
    // For demo purposes, we'll use the same logic as weekly but could be different
    return getWeeklyLeaderboard();
  }

  // Get active challenges
  Future<List<Challenge>> getActiveChallenges() async {
    final now = DateTime.now();
    return _challenges
        .where(
          (challenge) => challenge.isActive && challenge.endDate.isAfter(now),
        )
        .toList();
  }

  // Create a new challenge
  Future<void> createChallenge(
    String title,
    String description,
    ChallengeType type,
    double targetValue,
  ) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final challenge = Challenge(
      id: 'chal_${DateTime.now().millisecondsSinceEpoch}',
      name: title,
      description: description,
      type: type,
      targetValue: targetValue,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 7)), // 7-day challenge
      participantIds: [currentUser.uid],
      participantProgress: {currentUser.uid: 0.0},
      isActive: true,
    );

    _challenges.add(challenge);
    await _saveLocalData();
  }

  // Join a challenge
  Future<void> joinChallenge(String challengeId, String userId) async {
    final challengeIndex = _challenges.indexWhere((c) => c.id == challengeId);
    if (challengeIndex == -1) return;

    final challenge = _challenges[challengeIndex];
    if (!challenge.participantIds.contains(userId)) {
      final updatedChallenge = Challenge(
        id: challenge.id,
        name: challenge.name,
        description: challenge.description,
        type: challenge.type,
        targetValue: challenge.targetValue,
        startDate: challenge.startDate,
        endDate: challenge.endDate,
        participantIds: [...challenge.participantIds, userId],
        participantProgress: {...challenge.participantProgress, userId: 0.0},
        isActive: challenge.isActive,
      );

      _challenges[challengeIndex] = updatedChallenge;
      await _saveLocalData();
    }
  }

  // Update challenge progress
  Future<void> updateChallengeProgress(
    String challengeId,
    String userId,
    double progress,
  ) async {
    final challengeIndex = _challenges.indexWhere((c) => c.id == challengeId);
    if (challengeIndex == -1) return;

    final challenge = _challenges[challengeIndex];
    final updatedProgress = Map<String, double>.from(
      challenge.participantProgress,
    );
    updatedProgress[userId] = progress;

    final updatedChallenge = Challenge(
      id: challenge.id,
      name: challenge.name,
      description: challenge.description,
      type: challenge.type,
      targetValue: challenge.targetValue,
      startDate: challenge.startDate,
      endDate: challenge.endDate,
      participantIds: challenge.participantIds,
      participantProgress: updatedProgress,
      isActive: challenge.isActive,
    );

    _challenges[challengeIndex] = updatedChallenge;
    await _saveLocalData();
  }

  // Delete a challenge (only creator can delete)
  Future<bool> deleteChallenge(String challengeId, String userId) async {
    final challengeIndex = _challenges.indexWhere((c) => c.id == challengeId);
    if (challengeIndex == -1) return false;

    final challenge = _challenges[challengeIndex];

    // Check if user is the creator (first participant) or has admin rights
    if (challenge.participantIds.isNotEmpty &&
        challenge.participantIds.first == userId) {
      _challenges.removeAt(challengeIndex);
      await _saveLocalData();
      return true;
    }

    return false;
  }

  // Leave a challenge
  Future<void> leaveChallenge(String challengeId, String userId) async {
    final challengeIndex = _challenges.indexWhere((c) => c.id == challengeId);
    if (challengeIndex == -1) return;

    final challenge = _challenges[challengeIndex];
    final updatedParticipantIds = List<String>.from(challenge.participantIds);
    final updatedProgress = Map<String, double>.from(
      challenge.participantProgress,
    );

    updatedParticipantIds.remove(userId);
    updatedProgress.remove(userId);

    // If no participants left, delete the challenge
    if (updatedParticipantIds.isEmpty) {
      _challenges.removeAt(challengeIndex);
    } else {
      final updatedChallenge = Challenge(
        id: challenge.id,
        name: challenge.name,
        description: challenge.description,
        type: challenge.type,
        targetValue: challenge.targetValue,
        startDate: challenge.startDate,
        endDate: challenge.endDate,
        participantIds: updatedParticipantIds,
        participantProgress: updatedProgress,
        isActive: challenge.isActive,
      );

      _challenges[challengeIndex] = updatedChallenge;
    }

    await _saveLocalData();
  }

  // Refresh data
  Future<void> refreshData() async {
    await _loadRealFriendsFromFirestore();
    _updateWeeklyStats();
  }

  // Debug method to check Firebase friendship data
  Future<void> debugFriendshipData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('DEBUG: No current user');
        return;
      }

      print('DEBUG: Current user UID: ${currentUser.uid}');

      // Check user_friends collection
      final friendsSnapshot = await _firestore
          .collection('user_friends')
          .doc(currentUser.uid)
          .collection('friends')
          .get();

      print('DEBUG: Found ${friendsSnapshot.docs.length} friend documents');

      for (var doc in friendsSnapshot.docs) {
        print('DEBUG: Friend doc ID: ${doc.id}, data: ${doc.data()}');

        // Check if friend user exists
        final friendUserDoc = await _firestore
            .collection('users')
            .doc(doc.id)
            .get();

        if (friendUserDoc.exists) {
          print('DEBUG: Friend user data: ${friendUserDoc.data()}');
        } else {
          print(
            'DEBUG: Friend user ${doc.id} does not exist in users collection',
          );
        }
      }

      // Check all users
      final allUsersSnapshot = await _firestore.collection('users').get();

      print('DEBUG: Total users in database: ${allUsersSnapshot.docs.length}');
      for (var doc in allUsersSnapshot.docs) {
        print('DEBUG: User ${doc.id}: ${doc.data()}');
      }
    } catch (e) {
      print('DEBUG: Error checking friendship data: $e');
    }
  }

  // Helper method to manually create friendship relationship in Firebase
  Future<void> createFriendshipManually(String userId1, String userId2) async {
    try {
      final batch = _firestore.batch();

      // Add user2 as friend of user1
      final user1FriendRef = _firestore
          .collection('user_friends')
          .doc(userId1)
          .collection('friends')
          .doc(userId2);

      // Add user1 as friend of user2
      final user2FriendRef = _firestore
          .collection('user_friends')
          .doc(userId2)
          .collection('friends')
          .doc(userId1);

      final now = DateTime.now();
      final friendshipData = {
        'friendSince': Timestamp.fromDate(now),
        'createdAt': Timestamp.fromDate(now),
      };

      batch.set(user1FriendRef, friendshipData);
      batch.set(user2FriendRef, friendshipData);

      await batch.commit();

      print('✅ Friendship created between $userId1 and $userId2');

      // Refresh data after creating friendship
      await _loadRealFriendsFromFirestore();
    } catch (e) {
      print('❌ Error creating friendship: $e');
    }
  }

  // Dispose
  void dispose() {
    _friendsController.close();
    _friendRequestsController.close();
  }

  // Force emit current friends data (useful for immediate UI update)
  void emitCurrentData() {
    print(
      'Emitting current data: ${_friends.length} friends, ${_friendRequests.length} requests',
    );
    _friendsController.add(_friends);
    _friendRequestsController.add(_friendRequests);
  }

  // Check if there's a pending friend request between current user and target user
  Future<bool> hasPendingFriendRequest(String targetUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Check if current user sent a request to target user
      final sentRequest = await _firestore
          .collection('friend_requests')
          .where('fromUserId', isEqualTo: currentUser.uid)
          .where('toUserId', isEqualTo: targetUserId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (sentRequest.docs.isNotEmpty) return true;

      // Check if target user sent a request to current user
      final receivedRequest = await _firestore
          .collection('friend_requests')
          .where('fromUserId', isEqualTo: targetUserId)
          .where('toUserId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      return receivedRequest.docs.isNotEmpty;
    } catch (e) {
      print('Error checking pending friend request: $e');
      return false;
    }
  }

  // Check if user is already a friend or has pending request
  Future<String> getFriendshipStatus(String userId) async {
    // Check if already friends (both locally and in Firestore for accuracy)
    final isLocalFriend = _isAlreadyFriend(userId);
    final isFirestoreFriend = await isAlreadyFriendInFirestore(userId);

    if (isLocalFriend || isFirestoreFriend) {
      return 'friends';
    }

    // Check if has pending request
    final hasPending = await hasPendingFriendRequest(userId);
    if (hasPending) {
      return 'pending';
    }

    return 'none';
  }
}
