class Friend {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final DateTime friendSince;
  final bool isOnline;
  final WeeklyStats? currentWeekStats;

  Friend({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.friendSince,
    this.isOnline = false,
    this.currentWeekStats,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      photoUrl: json['photoUrl'],
      friendSince: DateTime.parse(json['friendSince']),
      isOnline: json['isOnline'] ?? false,
      currentWeekStats: json['currentWeekStats'] != null
          ? WeeklyStats.fromJson(json['currentWeekStats'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'friendSince': friendSince.toIso8601String(),
      'isOnline': isOnline,
      'currentWeekStats': currentWeekStats?.toJson(),
    };
  }

  Friend copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    DateTime? friendSince,
    bool? isOnline,
    WeeklyStats? currentWeekStats,
  }) {
    return Friend(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      friendSince: friendSince ?? this.friendSince,
      isOnline: isOnline ?? this.isOnline,
      currentWeekStats: currentWeekStats ?? this.currentWeekStats,
    );
  }
}

class WeeklyStats {
  final double totalDistance;
  final double totalCalories;
  final int totalSteps;
  final int activeDays;
  final int totalSessions;
  final DateTime weekStartDate;
  final DateTime weekEndDate;

  WeeklyStats({
    required this.totalDistance,
    required this.totalCalories,
    required this.totalSteps,
    required this.activeDays,
    required this.totalSessions,
    required this.weekStartDate,
    required this.weekEndDate,
  });

  factory WeeklyStats.fromJson(Map<String, dynamic> json) {
    return WeeklyStats(
      totalDistance: (json['totalDistance'] ?? 0.0).toDouble(),
      totalCalories: (json['totalCalories'] ?? 0.0).toDouble(),
      totalSteps: json['totalSteps'] ?? 0,
      activeDays: json['activeDays'] ?? 0,
      totalSessions: json['totalSessions'] ?? 0,
      weekStartDate: DateTime.parse(json['weekStartDate']),
      weekEndDate: DateTime.parse(json['weekEndDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalDistance': totalDistance,
      'totalCalories': totalCalories,
      'totalSteps': totalSteps,
      'activeDays': activeDays,
      'totalSessions': totalSessions,
      'weekStartDate': weekStartDate.toIso8601String(),
      'weekEndDate': weekEndDate.toIso8601String(),
    };
  }

  // Calculate score for competition ranking
  double get competitionScore {
    // Weight different metrics for overall score
    return (totalDistance * 10) +
        (totalCalories * 0.01) +
        (totalSteps * 0.001) +
        (activeDays * 5) +
        (totalSessions * 2);
  }
}

class FriendRequest {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final String fromUserEmail;
  final String toUserId;
  final String toUserName;
  final String toUserEmail;
  final DateTime createdAt;
  final FriendRequestStatus status;
  final String? message;

  FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    required this.fromUserEmail,
    required this.toUserId,
    required this.toUserName,
    required this.toUserEmail,
    required this.createdAt,
    required this.status,
    this.message,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] ?? '',
      fromUserId: json['fromUserId'] ?? '',
      fromUserName: json['fromUserName'] ?? '',
      fromUserEmail: json['fromUserEmail'] ?? '',
      toUserId: json['toUserId'] ?? '',
      toUserName: json['toUserName'] ?? '',
      toUserEmail: json['toUserEmail'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.toString() == 'FriendRequestStatus.${json['status']}',
        orElse: () => FriendRequestStatus.pending,
      ),
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'fromUserEmail': fromUserEmail,
      'toUserId': toUserId,
      'toUserName': toUserName,
      'toUserEmail': toUserEmail,
      'createdAt': createdAt.toIso8601String(),
      'status': status.toString().split('.').last,
      'message': message,
    };
  }
}

enum FriendRequestStatus { pending, accepted, rejected, cancelled }

class LeaderboardEntry {
  final String userId;
  final String userName;
  final String? photoUrl;
  final WeeklyStats stats;
  final int rank;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.userId,
    required this.userName,
    this.photoUrl,
    required this.stats,
    required this.rank,
    this.isCurrentUser = false,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      photoUrl: json['photoUrl'],
      stats: WeeklyStats.fromJson(json['stats']),
      rank: json['rank'] ?? 0,
      isCurrentUser: json['isCurrentUser'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'photoUrl': photoUrl,
      'stats': stats.toJson(),
      'rank': rank,
      'isCurrentUser': isCurrentUser,
    };
  }
}

class Challenge {
  final String id;
  final String name;
  final String description;
  final ChallengeType type;
  final double targetValue;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> participantIds;
  final Map<String, double> participantProgress;
  final String? winnerId;
  final bool isActive;

  Challenge({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.targetValue,
    required this.startDate,
    required this.endDate,
    this.participantIds = const [],
    this.participantProgress = const {},
    this.winnerId,
    this.isActive = true,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      type: ChallengeType.values.firstWhere(
        (e) => e.toString() == 'ChallengeType.${json['type']}',
        orElse: () => ChallengeType.distance,
      ),
      targetValue: (json['targetValue'] ?? 0.0).toDouble(),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      participantIds: List<String>.from(json['participantIds'] ?? []),
      participantProgress: Map<String, double>.from(
        json['participantProgress']?.map((k, v) => MapEntry(k, v.toDouble())) ??
            {},
      ),
      winnerId: json['winnerId'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'targetValue': targetValue,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'participantIds': participantIds,
      'participantProgress': participantProgress,
      'winnerId': winnerId,
      'isActive': isActive,
    };
  }
}

enum ChallengeType { distance, calories, steps, sessions }
