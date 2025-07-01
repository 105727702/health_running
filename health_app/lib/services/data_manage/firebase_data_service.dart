import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseDataService {
  static final FirebaseDataService _instance = FirebaseDataService._internal();
  factory FirebaseDataService() => _instance;
  FirebaseDataService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user's collection reference
  CollectionReference? get _userCollection {
    final user = _auth.currentUser;
    if (user == null) return null;

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('activities');
  }

  // Save tracking session to Firestore
  Future<void> saveTrackingSession({
    required double distance,
    required double calories,
    required int duration,
    required String activityType,
    required DateTime startTime,
    required DateTime endTime,
    required List<dynamic> route,
  }) async {
    try {
      final collection = _userCollection;
      if (collection == null) {
        print('User not authenticated');
        return;
      }

      final sessionData = {
        'distance': distance,
        'calories': calories,
        'duration': duration,
        'activityType': activityType,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'route': route.map((point) {
          // Handle both LatLng objects and Map objects
          if (point is Map<String, dynamic>) {
            return {
              'latitude': point['latitude'] ?? 0.0,
              'longitude': point['longitude'] ?? 0.0,
            };
          } else {
            // Assume it's a LatLng object or similar with latitude/longitude properties
            try {
              return {'latitude': point.latitude, 'longitude': point.longitude};
            } catch (e) {
              // Fallback for unexpected data types
              return {'latitude': 0.0, 'longitude': 0.0};
            }
          }
        }).toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'date': _formatDate(startTime),
      };

      await collection.add(sessionData);
      print('Session saved to Firebase successfully');
    } catch (e) {
      print('Error saving session to Firebase: $e');
      // Don't throw - let app continue with local storage
    }
  }

  // Get daily sessions from Firestore
  Future<List<Map<String, dynamic>>> getDailySessions(DateTime date) async {
    try {
      final collection = _userCollection;
      if (collection == null) return [];

      final dateString = _formatDate(date);
      final querySnapshot = await collection
          .where('date', isEqualTo: dateString)
          .orderBy('startTime', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();
    } catch (e) {
      print('Error getting daily sessions: $e');
      return [];
    }
  }

  // Get weekly sessions from Firestore
  Future<List<Map<String, dynamic>>> getWeeklySessions({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final collection = _userCollection;
      if (collection == null) return [];

      final startDateString = _formatDate(startDate);
      final endDateString = _formatDate(endDate);

      final querySnapshot = await collection
          .where('date', isGreaterThanOrEqualTo: startDateString)
          .where('date', isLessThanOrEqualTo: endDateString)
          .orderBy('date', descending: true)
          .orderBy('startTime', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();
    } catch (e) {
      print('Error getting weekly sessions: $e');
      return [];
    }
  }

  // Get monthly sessions for history view
  Future<List<Map<String, dynamic>>> getMonthlySessions({
    required int year,
    required int month,
  }) async {
    try {
      final collection = _userCollection;
      if (collection == null) return [];

      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0);

      return await getWeeklySessions(startDate: startDate, endDate: endDate);
    } catch (e) {
      print('Error getting monthly sessions: $e');
      return [];
    }
  }

  // Save daily summary to Firestore
  Future<void> saveDailySummary({
    required DateTime date,
    required double totalDistance,
    required double totalCalories,
    required int totalSteps,
    required int sessionCount,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final dateString = _formatDate(date);
      final summaryData = {
        'date': dateString,
        'totalDistance': totalDistance,
        'totalCalories': totalCalories,
        'totalSteps': totalSteps,
        'sessionCount': sessionCount,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('daily_summaries')
          .doc(dateString)
          .set(summaryData, SetOptions(merge: true));

      print('Daily summary saved to Firebase');
    } catch (e) {
      print('Error saving daily summary: $e');
    }
  }

  // Get daily summary from Firestore
  Future<Map<String, dynamic>?> getDailySummary(DateTime date) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final dateString = _formatDate(date);
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('daily_summaries')
          .doc(dateString)
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting daily summary: $e');
      return null;
    }
  }

  // Stream for real-time updates
  Stream<QuerySnapshot> watchDailySessions(DateTime date) {
    final collection = _userCollection;
    if (collection == null) {
      return Stream.empty();
    }

    final dateString = _formatDate(date);
    return collection
        .where('date', isEqualTo: dateString)
        .orderBy('startTime', descending: true)
        .snapshots();
  }

  // Delete session from Firestore
  Future<void> deleteSession(String sessionId) async {
    try {
      final collection = _userCollection;
      if (collection == null) return;

      await collection.doc(sessionId).delete();
      print('Session deleted from Firebase');
    } catch (e) {
      print('Error deleting session: $e');
    }
  }

  // Update session in Firestore
  Future<void> updateSession({
    required String sessionId,
    required double distance,
    required double calories,
    required int duration,
    required String activityType,
    required DateTime startTime,
    required DateTime endTime,
    required List<dynamic> route,
  }) async {
    try {
      final collection = _userCollection;
      if (collection == null) {
        print('User not authenticated');
        return;
      }

      final sessionData = {
        'distance': distance,
        'calories': calories,
        'duration': duration,
        'activityType': activityType,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'route': route.map((point) {
          // Handle both LatLng objects and Map objects
          if (point is Map<String, dynamic>) {
            return {
              'latitude': point['latitude'] ?? 0.0,
              'longitude': point['longitude'] ?? 0.0,
            };
          } else {
            // Assume it's a LatLng object or similar with latitude/longitude properties
            try {
              return {'latitude': point.latitude, 'longitude': point.longitude};
            } catch (e) {
              // Fallback for unexpected data types
              return {'latitude': 0.0, 'longitude': 0.0};
            }
          }
        }).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
        'date': _formatDate(startTime),
      };

      await collection.doc(sessionId).update(sessionData);
      print('Session updated in Firebase successfully');
    } catch (e) {
      print('Error updating session in Firebase: $e');
      // Don't throw - let app continue with local storage
    }
  }

  // Clear all user data from Firestore
  Future<void> clearAllUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userDoc = _firestore.collection('users').doc(user.uid);

      // Delete all activities
      final activitiesSnapshot = await userDoc.collection('activities').get();
      final activitiesBatch = _firestore.batch();
      for (final doc in activitiesSnapshot.docs) {
        activitiesBatch.delete(doc.reference);
      }
      await activitiesBatch.commit();

      // Delete all daily summaries
      final summariesSnapshot = await userDoc
          .collection('daily_summaries')
          .get();
      final summariesBatch = _firestore.batch();
      for (final doc in summariesSnapshot.docs) {
        summariesBatch.delete(doc.reference);
      }
      await summariesBatch.commit();

      print('All user data cleared from Firebase');
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }

  // Sync offline data when user comes online
  Future<void> syncOfflineData(
    List<Map<String, dynamic>> offlineSessions,
  ) async {
    try {
      final collection = _userCollection;
      if (collection == null) return;

      final batch = _firestore.batch();
      for (final sessionData in offlineSessions) {
        final docRef = collection.doc();
        batch.set(docRef, {
          ...sessionData,
          'createdAt': FieldValue.serverTimestamp(),
          'syncedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      print('Offline data synced successfully');
    } catch (e) {
      print('Error syncing offline data: $e');
    }
  }

  // Save user backup data to Firestore
  Future<void> saveUserBackup(Map<String, dynamic> backupData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Save to user's backup collection
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('backups')
          .doc('latest')
          .set({
            ...backupData,
            'userId': user.uid,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // Also save to backup history with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('backup_history')
          .doc(timestamp.toString())
          .set({
            ...backupData,
            'userId': user.uid,
            'createdAt': FieldValue.serverTimestamp(),
          });

      print('✅ Backup saved to Firebase successfully');
    } catch (e) {
      print('❌ Error saving backup to Firebase: $e');
      throw Exception('Failed to save backup: $e');
    }
  }

  // Get user backup data from Firestore
  Future<Map<String, dynamic>?> getUserBackup() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('backups')
          .doc('latest')
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }

      return null;
    } catch (e) {
      print('❌ Error getting backup from Firebase: $e');
      throw Exception('Failed to get backup: $e');
    }
  }

  // Get backup history
  Future<List<Map<String, dynamic>>> getBackupHistory({int limit = 10}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('backup_history')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      print('❌ Error getting backup history: $e');
      throw Exception('Failed to get backup history: $e');
    }
  }

  // Delete old backups (keep only recent ones)
  Future<void> cleanupOldBackups({int keepCount = 5}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get all backup history documents
      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('backup_history')
          .orderBy('createdAt', descending: true)
          .get();

      // Delete documents beyond keepCount
      if (querySnapshot.docs.length > keepCount) {
        final docsToDelete = querySnapshot.docs.skip(keepCount);

        final batch = _firestore.batch();
        for (final doc in docsToDelete) {
          batch.delete(doc.reference);
        }

        await batch.commit();
        print('🧹 Cleaned up ${docsToDelete.length} old backup(s)');
      }
    } catch (e) {
      print('❌ Error cleaning up old backups: $e');
      // Don't throw here as this is not critical
    }
  }

  // Helper method to format date
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final activitiesSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('activities')
          .where('date', isGreaterThanOrEqualTo: _formatDate(thirtyDaysAgo))
          .get();

      double totalDistance = 0;
      double totalCalories = 0;
      int totalSessions = activitiesSnapshot.docs.length;
      Map<String, int> activityCounts = {};

      for (final doc in activitiesSnapshot.docs) {
        final data = doc.data();
        totalDistance += (data['distance'] ?? 0).toDouble();
        totalCalories += (data['calories'] ?? 0).toDouble();

        final activity = data['activityType'] ?? 'unknown';
        activityCounts[activity] = (activityCounts[activity] ?? 0) + 1;
      }

      return {
        'totalDistance': totalDistance,
        'totalCalories': totalCalories,
        'totalSessions': totalSessions,
        'activityCounts': activityCounts,
        'period': '30 days',
      };
    } catch (e) {
      print('Error getting user statistics: $e');
      return {};
    }
  }
}
