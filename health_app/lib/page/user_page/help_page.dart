import 'package:flutter/material.dart';
import 'settings_page.dart';
import '../admin_page/data_storage_comparison_page.dart';
import '../../services/authen_service/role_service.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final RoleService _roleService = RoleService();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final isAdmin = await _roleService.isCurrentUserAdmin();
    setState(() {
      _isAdmin = isAdmin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Help Header
            Center(
              child: Column(
                children: [
                  Icon(Icons.help_center, size: 80, color: Colors.deepPurple),
                  SizedBox(height: 16),
                  Text(
                    'Help & Support',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Get help with your health tracking',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),

            // Help Options
            Expanded(
              child: ListView(
                children: [
                  HelpTile(
                    icon: Icons.question_answer,
                    title: 'FAQ',
                    subtitle: 'Frequently asked questions',
                  ),
                  if (_isAdmin)
                    HelpTile(
                      icon: Icons.storage,
                      title: 'Data Storage Comparison',
                      subtitle: 'Compare local vs hybrid storage (Admin only)',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const DataStorageComparisonPage(),
                          ),
                        );
                      },
                    ),
                  HelpTile(
                    icon: Icons.contact_support,
                    title: 'Contact Support',
                    subtitle: 'Get in touch with our support team',
                  ),
                  HelpTile(
                    icon: Icons.info,
                    title: 'App Information',
                    subtitle: 'Learn more about the app',
                  ),
                  HelpTile(
                    icon: Icons.feedback,
                    title: 'Send Feedback',
                    subtitle: 'Help us improve the app',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HelpTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const HelpTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap:
            onTap ??
            () {
              // Handle help item tap
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('$title tapped')));
            },
      ),
    );
  }
}
