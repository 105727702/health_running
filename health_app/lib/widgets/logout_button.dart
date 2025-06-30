import 'package:flutter/material.dart';
import '../services/auth_controller.dart';
import '../services/google_auth_service.dart';
import '../services/firebase_services_manager.dart';
import '../services/firebase_auth_service.dart';
import '../utils/snackbar_utils.dart';
import '../utils/firebase_utils.dart';

class LogoutButton extends StatelessWidget {
  final VoidCallback? onLogoutSuccess;
  final bool showConfirmDialog;
  final String? customText;
  final IconData? customIcon;
  final ButtonStyle? customStyle;

  const LogoutButton({
    super.key,
    this.onLogoutSuccess,
    this.showConfirmDialog = true,
    this.customText,
    this.customIcon,
    this.customStyle,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _handleLogout(context),
      icon: Icon(customIcon ?? Icons.logout),
      label: Text(customText ?? 'Logout'),
      style:
          customStyle ??
          ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
    );
  }

  void _handleLogout(BuildContext context) {
    if (showConfirmDialog) {
      _showLogoutConfirmDialog(context);
    } else {
      _performLogout(context);
    }
  }

  void _showLogoutConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performLogout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _performLogout(BuildContext context) async {
    try {
      // Track logout attempt
      await FirebaseUtils.trackButtonTap('logout_button');

      final authController = AuthController();

      // Track logout operation with performance monitoring
      final result = await FirebaseUtils.trackAuthOperation('logout', () async {
        // Sign out from both Firebase and Google
        await GoogleAuthService.signOut();
        return await authController.logout();
      });

      // ignore: use_build_context_synchronously
      SnackBarUtils.showAuthSnackBar(context, result);

      if (result.isSuccess) {
        // Log successful logout
        await FirebaseServicesManager.logUserLogout();

        // Clear user session
        await FirebaseUtils.clearUserSession();

        if (onLogoutSuccess != null) {
          onLogoutSuccess!();
        }
      } else {
        // Log logout error
        await FirebaseUtils.logNonFatalError(
          Exception('Logout failed'),
          StackTrace.current,
          context: 'User logout attempt failed',
          screenName: 'logout',
        );
      }
    } catch (error, stackTrace) {
      // Log unexpected error
      await FirebaseUtils.logNonFatalError(
        error,
        stackTrace,
        context: 'Unexpected error during logout',
        screenName: 'logout',
      );

      // ignore: use_build_context_synchronously
      SnackBarUtils.showAuthSnackBar(
        context,
        AuthResult.error('An unexpected error occurred'),
      );
    }
  }
}

// Simple logout icon button for app bars
class LogoutIconButton extends StatelessWidget {
  final VoidCallback? onLogoutSuccess;
  final bool showConfirmDialog;

  const LogoutIconButton({
    super.key,
    this.onLogoutSuccess,
    this.showConfirmDialog = true,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _handleLogout(context),
      icon: const Icon(Icons.logout),
      tooltip: 'Logout',
    );
  }

  void _handleLogout(BuildContext context) {
    if (showConfirmDialog) {
      _showLogoutConfirmDialog(context);
    } else {
      _performLogout(context);
    }
  }

  void _showLogoutConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performLogout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _performLogout(BuildContext context) async {
    final authController = AuthController();

    // Sign out from both Firebase and Google
    await GoogleAuthService.signOut();
    final result = await authController.logout();

    // ignore: use_build_context_synchronously
    SnackBarUtils.showAuthSnackBar(context, result);

    if (result.isSuccess && onLogoutSuccess != null) {
      onLogoutSuccess!();
    }
  }
}
