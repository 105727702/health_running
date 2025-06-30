import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HybridStorageInfoPage extends StatelessWidget {
  const HybridStorageInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isUserSignedIn = FirebaseAuth.instance.currentUser != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hybrid Storage System'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.purple.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.cloud_sync, color: Colors.white, size: 32),
                        SizedBox(width: 12),
                        Text(
                          'Hybrid Storage System',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Kết hợp tốt nhất của cả hai thế giới: Tốc độ của local storage và sự bền vững của cloud storage.',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isUserSignedIn
                            ? Colors.green.withOpacity(0.3)
                            : Colors.orange.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isUserSignedIn ? Icons.cloud_done : Icons.cloud_off,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isUserSignedIn
                                ? 'Đã đăng nhập - Sync enabled'
                                : 'Chưa đăng nhập - Local only',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // How it works section
            _buildSectionCard(
              title: 'Cách thức hoạt động',
              icon: Icons.engineering,
              color: Colors.blue,
              children: [
                _buildFeatureItem(
                  icon: Icons.speed,
                  title: '1. Local First',
                  description:
                      'Tất cả dữ liệu được lưu trong SharedPreferences trước để đảm bảo tốc độ',
                  color: Colors.green,
                ),
                _buildFeatureItem(
                  icon: Icons.cloud_upload,
                  title: '2. Auto Sync',
                  description:
                      'Dữ liệu chi tiết (sessions, routes) tự động sync lên Firebase khi có mạng',
                  color: Colors.blue,
                ),
                _buildFeatureItem(
                  icon: Icons.offline_bolt,
                  title: '3. Offline Support',
                  description:
                      'Hoạt động bình thường khi offline, sync khi có mạng trở lại',
                  color: Colors.orange,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Data Types section
            _buildSectionCard(
              title: 'Phân loại dữ liệu',
              icon: Icons.category,
              color: Colors.purple,
              children: [
                _buildDataTypeItem(
                  icon: Icons.storage,
                  title: 'SharedPreferences (Local)',
                  items: [
                    '• Dữ liệu tổng hàng ngày',
                    '• Mục tiêu cá nhân (Goals)',
                    '• Cài đặt ứng dụng',
                    '• Cache dữ liệu Firebase',
                  ],
                  color: Colors.orange,
                ),
                _buildDataTypeItem(
                  icon: Icons.cloud,
                  title: 'Firebase Firestore (Cloud)',
                  items: [
                    '• Lịch sử hoạt động chi tiết',
                    '• Routes và GPS data',
                    '• Backup dữ liệu tổng',
                    '• Sync giữa các thiết bị',
                  ],
                  color: Colors.blue,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Benefits section
            _buildSectionCard(
              title: 'Lợi ích của Hybrid Storage',
              icon: Icons.star,
              color: Colors.green,
              children: [
                _buildBenefitItem(
                  icon: Icons.flash_on,
                  title: 'Hiệu suất cao',
                  description: 'Truy cập nhanh từ local storage',
                ),
                _buildBenefitItem(
                  icon: Icons.backup,
                  title: 'Backup tự động',
                  description: 'Dữ liệu được backup lên cloud',
                ),
                _buildBenefitItem(
                  icon: Icons.sync,
                  title: 'Đồng bộ đa thiết bị',
                  description: 'Dữ liệu có thể sync giữa các thiết bị',
                ),
                _buildBenefitItem(
                  icon: Icons.offline_pin,
                  title: 'Hoạt động offline',
                  description: 'Không cần mạng để sử dụng app',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Technical Details
            _buildSectionCard(
              title: 'Chi tiết kỹ thuật',
              icon: Icons.code,
              color: Colors.deepPurple,
              children: [
                _buildTechnicalDetail(
                  'Data Flow',
                  'User Action → Local Storage → UI Update → Firebase Sync (background)',
                ),
                _buildTechnicalDetail(
                  'Conflict Resolution',
                  'Local data có ưu tiên, Firebase data merge khi cần thiết',
                ),
                _buildTechnicalDetail(
                  'Offline Queue',
                  'Actions offline được queue và sync khi có mạng',
                ),
                _buildTechnicalDetail(
                  'Error Handling',
                  'Firebase errors không ảnh hưởng đến local functionality',
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Status Card
            _buildStatusCard(isUserSignedIn),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTypeItem({
    required IconData icon,
    required String title,
    required List<String> items,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                item,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.green, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
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
      ),
    );
  }

  Widget _buildTechnicalDetail(String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(bool isSignedIn) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isSignedIn
                ? [Colors.green.shade400, Colors.blue.shade400]
                : [Colors.orange.shade400, Colors.red.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSignedIn ? Icons.cloud_done : Icons.cloud_off,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  isSignedIn
                      ? 'System Status: Active'
                      : 'System Status: Local Only',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isSignedIn
                  ? 'Hybrid storage đang hoạt động với đầy đủ tính năng sync. Dữ liệu của bạn được backup tự động.'
                  : 'Đang sử dụng local storage. Đăng nhập để kích hoạt sync và backup dữ liệu.',
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
            if (!isSignedIn) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Navigate to login or show login dialog
                  // You can implement login navigation here
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.orange.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Đăng nhập để kích hoạt'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
