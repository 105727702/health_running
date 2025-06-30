import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';

class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final String? phoneNumber;
  final DateTime? birthDate;
  final String? gender;
  final double? height; // cm
  final double? weight; // kg
  final String? bio;
  final String? location;
  final DateTime? joinDate;
  final DateTime? lastActive;
  final Map<String, dynamic> preferences;
  final Map<String, dynamic> stats;

  const UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    this.phoneNumber,
    this.birthDate,
    this.gender,
    this.height,
    this.weight,
    this.bio,
    this.location,
    this.joinDate,
    this.lastActive,
    this.preferences = const {},
    this.stats = const {},
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserProfile(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      phoneNumber: data['phoneNumber'],
      birthDate: (data['birthDate'] as Timestamp?)?.toDate(),
      gender: data['gender'],
      height: (data['height'] as num?)?.toDouble(),
      weight: (data['weight'] as num?)?.toDouble(),
      bio: data['bio'],
      location: data['location'],
      joinDate: (data['joinDate'] as Timestamp?)?.toDate(),
      lastActive: (data['lastActive'] as Timestamp?)?.toDate(),
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
      stats: Map<String, dynamic>.from(data['stats'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'phoneNumber': phoneNumber,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'gender': gender,
      'height': height,
      'weight': weight,
      'bio': bio,
      'location': location,
      'joinDate': joinDate != null ? Timestamp.fromDate(joinDate!) : null,
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : null,
      'preferences': preferences,
      'stats': stats,
    };
  }

  UserProfile copyWith({
    String? displayName,
    String? photoURL,
    String? phoneNumber,
    DateTime? birthDate,
    String? gender,
    double? height,
    double? weight,
    String? bio,
    String? location,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? stats,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      joinDate: joinDate,
      lastActive: lastActive,
      preferences: preferences ?? this.preferences,
      stats: stats ?? this.stats,
    );
  }

  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  double? get bmi {
    if (height == null || weight == null || height! <= 0) return null;
    final heightM = height! / 100; // Convert cm to m
    return weight! / (heightM * heightM);
  }

  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == null) return 'Unknown';

    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue < 25) return 'Normal';
    if (bmiValue < 30) return 'Overweight';
    return 'Obese';
  }

  String get initials {
    if (displayName != null && displayName!.isNotEmpty) {
      final names = displayName!.split(' ');
      if (names.length >= 2) {
        return '${names[0][0]}${names[1][0]}'.toUpperCase();
      }
      return displayName![0].toUpperCase();
    }
    return email[0].toUpperCase();
  }
}

class UserProfileService {
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;
  UserProfileService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user profile
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      } else {
        // Create initial profile from Firebase Auth data
        final profile = UserProfile(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          photoURL: user.photoURL,
          phoneNumber: user.phoneNumber,
          joinDate: user.metadata.creationTime,
          lastActive: DateTime.now(),
        );

        // Save to Firestore
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(profile.toFirestore());
        return profile;
      }
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<bool> updateProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection('users')
          .doc(profile.uid)
          .set(profile.toFirestore(), SetOptions(merge: true));

      // Update Firebase Auth display name if changed
      final user = _auth.currentUser;
      if (user != null && user.displayName != profile.displayName) {
        await user.updateDisplayName(profile.displayName);
      }

      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // Update last active timestamp
  Future<void> updateLastActive() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating last active: $e');
    }
  }

  // Get user stats (workout statistics)
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      // Get workout sessions
      final workoutSnapshot = await _firestore
          .collection('workout_sessions')
          .where('userId', isEqualTo: userId)
          .get();

      double totalDistance = 0;
      double totalDuration = 0;
      double totalCalories = 0;
      int totalSessions = workoutSnapshot.docs.length;

      DateTime? firstWorkout;
      DateTime? lastWorkout;

      for (final doc in workoutSnapshot.docs) {
        final data = doc.data();
        totalDistance += (data['distance'] ?? 0.0).toDouble();
        totalDuration += (data['duration'] ?? 0.0).toDouble();
        totalCalories += (data['calories'] ?? 0.0).toDouble();

        final workoutDate = (data['date'] as Timestamp?)?.toDate();
        if (workoutDate != null) {
          if (firstWorkout == null || workoutDate.isBefore(firstWorkout)) {
            firstWorkout = workoutDate;
          }
          if (lastWorkout == null || workoutDate.isAfter(lastWorkout)) {
            lastWorkout = workoutDate;
          }
        }
      }

      return {
        'totalSessions': totalSessions,
        'totalDistance': totalDistance,
        'totalDuration': totalDuration,
        'totalCalories': totalCalories,
        'avgDistance': totalSessions > 0 ? totalDistance / totalSessions : 0,
        'avgDuration': totalSessions > 0 ? totalDuration / totalSessions : 0,
        'avgCalories': totalSessions > 0 ? totalCalories / totalSessions : 0,
        'firstWorkout': firstWorkout,
        'lastWorkout': lastWorkout,
      };
    } catch (e) {
      print('Error getting user stats: $e');
      return {};
    }
  }

  // Update user preferences
  Future<bool> updatePreferences(Map<String, dynamic> preferences) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'preferences': preferences,
      });
      return true;
    } catch (e) {
      print('Error updating preferences: $e');
      return false;
    }
  }

  // Delete user account
  Future<bool> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Delete user data from Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete workout sessions
      final workoutSnapshot = await _firestore
          .collection('workout_sessions')
          .where('userId', isEqualTo: user.uid)
          .get();

      final batch = _firestore.batch();
      for (final doc in workoutSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Delete Firebase Auth account
      await user.delete();

      return true;
    } catch (e) {
      print('Error deleting account: $e');
      return false;
    }
  }

  // Get user profile by UID - returns UserModel
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return UserModel.fromMap(data, uid);
      } else {
        // Get user from Firebase Auth if exists
        final user = _auth.currentUser;
        if (user != null && user.uid == uid) {
          final userModel = UserModel(
            uid: uid,
            name: user.displayName ?? '',
            email: user.email ?? '',
            phone: user.phoneNumber,
            photoUrl: user.photoURL,
            createdAt: user.metadata.creationTime ?? DateTime.now(),
            updatedAt: DateTime.now(),
          );

          // Save to Firestore
          await _firestore.collection('users').doc(uid).set(userModel.toMap());
          return userModel;
        }
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile - accepts Map<String, dynamic>
  Future<bool> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }
}
