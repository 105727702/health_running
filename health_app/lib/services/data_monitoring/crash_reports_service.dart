import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../authen_service/role_service.dart';

class CrashReportData {
  final String id;
  final String errorType;
  final String errorMessage;
  final String stackTrace;
  final String screenName;
  final String userId;
  final String? userEmail;
  final DateTime timestamp;
  final String appVersion;
  final String platform;
  final Map<String, dynamic> additionalData;

  const CrashReportData({
    required this.id,
    required this.errorType,
    required this.errorMessage,
    required this.stackTrace,
    required this.screenName,
    required this.userId,
    this.userEmail,
    required this.timestamp,
    required this.appVersion,
    required this.platform,
    required this.additionalData,
  });

  factory CrashReportData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CrashReportData(
      id: doc.id,
      errorType: data['error_type'] ?? 'Unknown Error',
      errorMessage: data['error_message'] ?? 'No message',
      stackTrace: data['stack_trace'] ?? 'No stack trace',
      screenName: data['screen_name'] ?? 'Unknown Screen',
      userId: data['user_id'] ?? 'anonymous',
      userEmail: data['user_email'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      appVersion: data['app_version'] ?? '1.0.0',
      platform: data['platform'] ?? 'unknown',
      additionalData: Map<String, dynamic>.from(data['additional_data'] ?? {}),
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String get shortMessage {
    if (errorMessage.length <= 50) return errorMessage;
    return '${errorMessage.substring(0, 50)}...';
  }
}

class CrashReportsService {
  static final CrashReportsService _instance = CrashReportsService._internal();
  factory CrashReportsService() => _instance;
  CrashReportsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Lấy danh sách crash reports
  Future<List<CrashReportData>> getCrashReports({
    int limit = 50,
    String? errorType,
    String? screenName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Check admin permission
    final role = await RoleService().getCurrentUserRole();
    if (role != UserRole.admin) {
      throw Exception('Only admins can view crash reports');
    }

    try {
      Query query = _firestore.collection('crash_reports');

      // Apply filters
      if (errorType != null && errorType.isNotEmpty) {
        query = query.where('error_type', isEqualTo: errorType);
      }

      if (screenName != null && screenName.isNotEmpty) {
        query = query.where('screen_name', isEqualTo: screenName);
      }

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }

      // Order by timestamp (newest first)
      query = query.orderBy('timestamp', descending: true);

      // Apply limit
      query = query.limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => CrashReportData.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting crash reports: $e');
      return [];
    }
  }

  // Lấy thống kê crash
  Future<Map<String, dynamic>> getCrashStatistics({int days = 30}) async {
    final role = await RoleService().getCurrentUserRole();
    if (role != UserRole.admin) {
      throw Exception('Only admins can view crash statistics');
    }

    try {
      final daysAgo = DateTime.now().subtract(Duration(days: days));
      final snapshot = await _firestore
          .collection('crash_reports')
          .where('timestamp', isGreaterThan: daysAgo)
          .get();

      final Map<String, int> errorTypes = {};
      final Map<String, int> screens = {};
      final Map<String, int> dailyCrashes = {};
      int totalCrashes = snapshot.docs.length;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final errorType = data['error_type'] ?? 'Unknown';
        final screenName = data['screen_name'] ?? 'Unknown';
        final timestamp =
            (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        final dayKey = '${timestamp.day}/${timestamp.month}';

        errorTypes[errorType] = (errorTypes[errorType] ?? 0) + 1;
        screens[screenName] = (screens[screenName] ?? 0) + 1;
        dailyCrashes[dayKey] = (dailyCrashes[dayKey] ?? 0) + 1;
      }

      return {
        'totalCrashes': totalCrashes,
        'errorTypes': errorTypes,
        'screens': screens,
        'dailyCrashes': dailyCrashes,
        'period': days,
      };
    } catch (e) {
      print('Error getting crash statistics: $e');
      return {
        'totalCrashes': 0,
        'errorTypes': <String, int>{},
        'screens': <String, int>{},
        'dailyCrashes': <String, int>{},
        'period': days,
      };
    }
  }

  // Lấy danh sách error types
  Future<List<String>> getErrorTypes() async {
    try {
      final snapshot = await _firestore.collection('crash_reports').get();
      final Set<String> errorTypes = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final errorType = data['error_type'] as String?;
        if (errorType != null && errorType.isNotEmpty) {
          errorTypes.add(errorType);
        }
      }

      return errorTypes.toList()..sort();
    } catch (e) {
      print('Error getting error types: $e');
      return [];
    }
  }

  // Lấy danh sách screen names
  Future<List<String>> getScreenNames() async {
    try {
      final snapshot = await _firestore.collection('crash_reports').get();
      final Set<String> screenNames = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final screenName = data['screen_name'] as String?;
        if (screenName != null && screenName.isNotEmpty) {
          screenNames.add(screenName);
        }
      }

      return screenNames.toList()..sort();
    } catch (e) {
      print('Error getting screen names: $e');
      return [];
    }
  }

  // Xóa crash report (admin only)
  Future<bool> deleteCrashReport(String reportId) async {
    final role = await RoleService().getCurrentUserRole();
    if (role != UserRole.admin) {
      throw Exception('Only admins can delete crash reports');
    }

    try {
      await _firestore.collection('crash_reports').doc(reportId).delete();
      return true;
    } catch (e) {
      print('Error deleting crash report: $e');
      return false;
    }
  }

  // Delete a single crash report
  Future<bool> deleteSingleCrashReport(String reportId) async {
    try {
      await _firestore.collection('crash_reports').doc(reportId).delete();
      print('Crash report deleted: $reportId');
      return true;
    } catch (e) {
      print('Error deleting crash report: $e');
      return false;
    }
  }

  // Delete multiple crash reports
  Future<bool> deleteMultipleCrashReports(List<String> reportIds) async {
    try {
      final batch = _firestore.batch();
      for (final reportId in reportIds) {
        batch.delete(_firestore.collection('crash_reports').doc(reportId));
      }
      await batch.commit();
      print('Multiple crash reports deleted: ${reportIds.length}');
      return true;
    } catch (e) {
      print('Error deleting multiple crash reports: $e');
      return false;
    }
  }

  // Delete all crash reports (admin only)
  Future<bool> deleteAllCrashReports() async {
    try {
      // Check if user is admin
      final user = _auth.currentUser;
      if (user == null) return false;

      final isAdmin = await RoleService().isCurrentUserAdmin();
      if (!isAdmin) {
        print('Access denied: User is not admin');
        return false;
      }

      final snapshot = await _firestore.collection('crash_reports').get();
      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('All crash reports deleted: ${snapshot.docs.length}');
      return true;
    } catch (e) {
      print('Error deleting all crash reports: $e');
      return false;
    }
  }

  // Delete crash reports older than specified days
  Future<bool> deleteOldCrashReports(int daysOld) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      final snapshot = await _firestore
          .collection('crash_reports')
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      if (snapshot.docs.isEmpty) {
        print('No old crash reports to delete');
        return true;
      }

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('Old crash reports deleted: ${snapshot.docs.length}');
      return true;
    } catch (e) {
      print('Error deleting old crash reports: $e');
      return false;
    }
  }

  // Tạo crash report mới (để test)
  Future<void> logCrashReport({
    required String errorType,
    required String errorMessage,
    required String stackTrace,
    required String screenName,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final user = _auth.currentUser;
      await _firestore.collection('crash_reports').add({
        'error_type': errorType,
        'error_message': errorMessage,
        'stack_trace': stackTrace,
        'screen_name': screenName,
        'user_id': user?.uid ?? 'anonymous',
        'user_email': user?.email,
        'timestamp': FieldValue.serverTimestamp(),
        'app_version': '1.0.0',
        'platform': 'flutter',
        'additional_data': additionalData ?? {},
      });
    } catch (e) {
      print('Error logging crash report: $e');
    }
  }
}
