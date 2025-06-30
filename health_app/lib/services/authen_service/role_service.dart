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

  // Admin email list - can be configured in Firebase Remote Config later
  static const List<String> _adminEmails = [
    'admin@healthapp.com',
    'huyhoang17012006@gmail.com',
    // Add other admin emails here
  ];

  // Get current user role
  Future<UserRole> getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return UserRole.user;

    // Check admin email list first
    if (_adminEmails.contains(user.email?.toLowerCase())) {
      await _setUserRole(user.uid, UserRole.admin); // Sync to Firestore
      return UserRole.admin;
    }

    // Check in Firestore
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

  // Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    final role = await getCurrentUserRole();
    return role == UserRole.admin;
  }

  // Stream to monitor role changes in real-time
  Stream<UserRole> getCurrentUserRoleStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(UserRole.user);
    }

    // Check admin email list first
    if (_adminEmails.contains(user.email?.toLowerCase())) {
      return Stream.value(UserRole.admin);
    }

    // Stream from Firestore
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

  // Set role for user (only admin can call this)
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

  // Promote user to admin (only super admin can call this)
  Future<bool> promoteUserToAdmin(String userEmail) async {
    final currentRole = await getCurrentUserRole();
    if (currentRole != UserRole.admin) {
      throw Exception('Only admins can promote users');
    }

    try {
      // Find user by email
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: userEmail.toLowerCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return false; // User does not exist
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

    // Cannot demote admin email in hardcoded list
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

  // Get list of all admins
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

      // Add hardcoded admins
      for (final email in _adminEmails) {
        admins.add({'email': email, 'type': 'hardcoded', 'canDemote': false});
      }

      // Add admins from Firestore
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
  // ignore: unused_element
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
