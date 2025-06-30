import 'package:flutter/material.dart';
import '../../widgets/health_dashboard.dart';
import '../../widgets/hybrid_health_dashboard.dart';
import '../../services/authen_service/role_service.dart';
import 'firebase_test_page.dart'; // Add this import

class DataStorageComparisonPage extends StatefulWidget {
  const DataStorageComparisonPage({super.key});

  @override
  State<DataStorageComparisonPage> createState() =>
      _DataStorageComparisonPageState();
}

class _DataStorageComparisonPageState extends State<DataStorageComparisonPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RoleService _roleService = RoleService();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final isAdmin = await _roleService.isCurrentUserAdmin();
    setState(() {
      _isAdmin = isAdmin;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is admin
    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Restricted'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Admin Access Required',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'This page is restricted to admin users only. '
                      'Data storage comparison and testing features require admin privileges.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Go Back'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Storage Comparison'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          // Admin indicator
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.admin_panel_settings, size: 16),
                const SizedBox(width: 4),
                Text('Admin', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.storage), text: 'Local Only'),
            Tab(
              icon: Icon(Icons.cloud_sync),
              text: 'Hybrid (Local + Firebase)',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Information Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.purple.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Storage Comparison Demo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 8),
                _buildComparisonRow(
                  'Local Only',
                  'SharedPreferences only - Fast, offline-first',
                  Icons.storage,
                  Colors.orange,
                ),
                const SizedBox(height: 8),
                _buildComparisonRow(
                  'Hybrid Storage',
                  'SharedPreferences + Firebase - Best of both worlds',
                  Icons.cloud_sync,
                  Colors.green,
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                // Local Only Tab
                HealthDashboard(),

                // Hybrid Tab
                HybridHealthDashboard(),
              ],
            ),
          ),

          // Firebase Test Page Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FirebaseTestPage(),
                  ),
                );
              },
              child: const Text('Test Firebase'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
