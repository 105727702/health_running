import 'package:flutter/material.dart';
import '../widgets/health_dashboard.dart';
import '../widgets/hybrid_health_dashboard.dart';

class DataStorageComparisonPage extends StatefulWidget {
  const DataStorageComparisonPage({super.key});

  @override
  State<DataStorageComparisonPage> createState() =>
      _DataStorageComparisonPageState();
}

class _DataStorageComparisonPageState extends State<DataStorageComparisonPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Storage Comparison'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
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
