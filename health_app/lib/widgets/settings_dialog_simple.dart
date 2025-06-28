import 'package:flutter/material.dart';
import '../widgets/logout_button.dart';
import '../widgets/session_info_widget.dart';
import '../page/Login_Screen.dart';

class SettingsDialogSimple extends StatelessWidget {
  const SettingsDialogSimple({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.all(20),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      title: const Text(
        'Settings',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300, maxHeight: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Account Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const SessionInfoWidget(
                      showSessionDuration: true,
                      showAsCard: false,
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 12),
                    LogoutButton(
                      customText: 'Logout',
                      customIcon: Icons.logout,
                      showConfirmDialog: true,
                      onLogoutSuccess: () {
                        Navigator.of(context).pop(); // Close settings dialog
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      ],
    );
  }
}
