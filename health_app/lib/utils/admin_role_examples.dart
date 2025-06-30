// Example usage of admin role service
// This file demonstrates how to integrate admin role checks into your widgets

import 'package:flutter/material.dart';
import '../services/authen_service/role_service.dart';

class AdminProtectedWidget extends StatefulWidget {
  final Widget child;
  final String? restrictedMessage;

  const AdminProtectedWidget({
    super.key,
    required this.child,
    this.restrictedMessage,
  });

  @override
  State<AdminProtectedWidget> createState() => _AdminProtectedWidgetState();
}

class _AdminProtectedWidgetState extends State<AdminProtectedWidget> {
  final RoleService _roleService = RoleService();
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
  }

  Future<void> _checkAdminRole() async {
    try {
      final isAdmin = await _roleService.isCurrentUserAdmin();
      setState(() {
        _isAdmin = isAdmin;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_isAdmin) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: Colors.grey.shade100,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.grey.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.restrictedMessage ?? 'Admin access required',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}

// Example usage in a widget
class ExampleAdminFeature extends StatelessWidget {
  const ExampleAdminFeature({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminProtectedWidget(
      restrictedMessage: 'Only admin users can access this feature',
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              // This button is only shown to admin users
              print('Admin action performed');
            },
            child: const Text('Admin Only Button'),
          ),
          // More admin-only content here
        ],
      ),
    );
  }
}

// Example usage for button protection
class ExampleButtonWithAdminCheck extends StatefulWidget {
  const ExampleButtonWithAdminCheck({super.key});

  @override
  State<ExampleButtonWithAdminCheck> createState() =>
      _ExampleButtonWithAdminCheckState();
}

class _ExampleButtonWithAdminCheckState
    extends State<ExampleButtonWithAdminCheck> {
  final RoleService _roleService = RoleService();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
  }

  Future<void> _checkAdminRole() async {
    final isAdmin = await _roleService.isCurrentUserAdmin();
    setState(() {
      _isAdmin = isAdmin;
    });
  }

  void _handleAdminAction() async {
    // Double-check admin status before performing action
    if (!await _roleService.isCurrentUserAdmin()) {
      RoleService.showAccessDeniedDialog(context);
      return;
    }

    // Confirm admin action
    final confirmed = await RoleService.showAdminConfirmationDialog(
      context,
      'Delete All Data',
      'Are you sure you want to delete all user data? This action cannot be undone.',
    );

    if (confirmed) {
      // Perform admin action
      print('Admin action confirmed and performed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isAdmin ? _handleAdminAction : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: _isAdmin ? Colors.red : Colors.grey,
        foregroundColor: Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isAdmin) ...[
            const Icon(Icons.admin_panel_settings, size: 16),
            const SizedBox(width: 4),
            const Text('Admin Action'),
          ] else ...[
            const Icon(Icons.lock_outline, size: 16),
            const SizedBox(width: 4),
            const Text('Admin Only'),
          ],
        ],
      ),
    );
  }
}
