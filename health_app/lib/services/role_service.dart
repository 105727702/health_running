import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum UserRole { admin, user }

class RoleService {
  static final RoleService _instance = RoleService._internal();
  factory RoleService() => _instance;
  RoleService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Admin email list - có thể config trong Firebase Remote Config sau này
  static const List<String> _adminEmails = [
    'admin@healthapp.com',
    'huyhoang17012006@gmail.com',
    // Thêm email admin khác tại đây
  ];

  // Lấy role hiện tại của user
  Future<UserRole> getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return UserRole.user;

    // Kiểm tra trong admin email list trước
    if (_adminEmails.contains(user.email?.toLowerCase())) {
      await _setUserRole(user.uid, UserRole.admin); // Sync to Firestore
      return UserRole.admin;
    }

    // Kiểm tra trong Firestore
    try {
      final doc = await _firestore.collection('user_roles').doc(user.uid).get();

      if (doc.exists) {
        final roleString = doc.data()?['role'] as String?;
        if (roleString == 'admin') {
          return UserRole.admin;
        }
      }
    } catch (e) {
      print('Error getting user role: $e');
    }

    return UserRole.user;
  }

  // Kiểm tra user có phải admin không
  Future<bool> isCurrentUserAdmin() async {
    final role = await getCurrentUserRole();
    return role == UserRole.admin;
  }

  // Stream để theo dõi thay đổi role real-time
  Stream<UserRole> getCurrentUserRoleStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(UserRole.user);
    }

    // Kiểm tra admin email list trước
    if (_adminEmails.contains(user.email?.toLowerCase())) {
      return Stream.value(UserRole.admin);
    }

    // Stream từ Firestore
    return _firestore.collection('user_roles').doc(user.uid).snapshots().map((
      doc,
    ) {
      if (doc.exists) {
        final roleString = doc.data()?['role'] as String?;
        if (roleString == 'admin') {
          return UserRole.admin;
        }
      }
      return UserRole.user;
    });
  }

  // Set role cho user (chỉ admin mới có thể gọi)
  Future<void> _setUserRole(String userId, UserRole role) async {
    try {
      await _firestore.collection('user_roles').doc(userId).set({
        'role': role.name,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid,
      });
    } catch (e) {
      print('Error setting user role: $e');
    }
  }

  // Promote user to admin (chỉ super admin mới có thể gọi)
  Future<bool> promoteUserToAdmin(String userEmail) async {
    final currentRole = await getCurrentUserRole();
    if (currentRole != UserRole.admin) {
      throw Exception('Only admins can promote users');
    }

    try {
      // Tìm user bằng email
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: userEmail.toLowerCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return false; // User không tồn tại
      }

      final userDoc = querySnapshot.docs.first;
      final userId = userDoc.id;

      await _setUserRole(userId, UserRole.admin);
      return true;
    } catch (e) {
      print('Error promoting user: $e');
      return false;
    }
  }

  // Demote admin to user
  Future<bool> demoteAdminToUser(String userEmail) async {
    final currentRole = await getCurrentUserRole();
    if (currentRole != UserRole.admin) {
      throw Exception('Only admins can demote users');
    }

    // Không thể demote admin email trong hardcoded list
    if (_adminEmails.contains(userEmail.toLowerCase())) {
      throw Exception('Cannot demote hardcoded admin');
    }

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: userEmail.toLowerCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return false;
      }

      final userDoc = querySnapshot.docs.first;
      final userId = userDoc.id;

      await _setUserRole(userId, UserRole.user);
      return true;
    } catch (e) {
      print('Error demoting user: $e');
      return false;
    }
  }

  // Lấy danh sách tất cả admin
  Future<List<Map<String, dynamic>>> getAllAdmins() async {
    final currentRole = await getCurrentUserRole();
    if (currentRole != UserRole.admin) {
      throw Exception('Only admins can view admin list');
    }

    try {
      final querySnapshot = await _firestore
          .collection('user_roles')
          .where('role', isEqualTo: 'admin')
          .get();

      final admins = <Map<String, dynamic>>[];

      // Thêm hardcoded admins
      for (final email in _adminEmails) {
        admins.add({'email': email, 'type': 'hardcoded', 'canDemote': false});
      }

      // Thêm admins từ Firestore
      for (final doc in querySnapshot.docs) {
        final userId = doc.id;
        final userDoc = await _firestore.collection('users').doc(userId).get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final email = userData['email'] as String?;

          if (email != null && !_adminEmails.contains(email.toLowerCase())) {
            admins.add({
              'email': email,
              'type': 'promoted',
              'canDemote': true,
              'userId': userId,
            });
          }
        }
      }

      return admins;
    } catch (e) {
      print('Error getting admin list: $e');
      return [];
    }
  }

  // Log admin action
  Future<void> _logAdminAction(
    String action,
    Map<String, dynamic> details,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('admin_logs').add({
        'adminId': user.uid,
        'adminEmail': user.email,
        'action': action,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error logging admin action: $e');
    }
  }

  // Utility method to show admin confirmation dialog
  static Future<bool> showAdminConfirmationDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.red),
                const SizedBox(width: 8),
                Text(title),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // Utility method to show access denied dialog
  static void showAccessDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Access Denied'),
          ],
        ),
        content: const Text(
          'You need admin privileges to perform this action. '
          'Please contact your system administrator.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
