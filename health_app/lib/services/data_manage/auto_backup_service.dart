import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'tracking_data_service.dart';
import 'firebase_data_service.dart';

class AutoBackupService {
  static final AutoBackupService _instance = AutoBackupService._internal();
  factory AutoBackupService() => _instance;
  AutoBackupService._internal();

  final TrackingDataService _trackingService = TrackingDataService();
  final FirebaseDataService _firebaseService = FirebaseDataService();

  Timer? _autoBackupTimer;
  bool _isBackupEnabled = true;

  // Khởi tạo auto backup service
  Future<void> initialize() async {
    await _loadBackupSettings();
    if (_isBackupEnabled) {
      _startAutoBackupTimer();
    }
    print('🔄 AutoBackupService initialized');
  }

  // Bắt đầu timer auto backup (24h)
  void _startAutoBackupTimer() {
    _autoBackupTimer?.cancel();

    // Tính thời gian đến lúc 2:00 AM ngày mai (thời điểm backup)
    final now = DateTime.now();
    final nextBackupTime = DateTime(now.year, now.month, now.day + 1, 2, 0, 0);
    final timeUntilBackup = nextBackupTime.difference(now);

    print('⏰ Next auto backup scheduled at: $nextBackupTime');
    print(
      '   Time until backup: ${timeUntilBackup.inHours}h ${timeUntilBackup.inMinutes % 60}m',
    );

    _autoBackupTimer = Timer(timeUntilBackup, () {
      _performAutoBackup();
      // Đặt timer lặp lại mỗi 24h
      _autoBackupTimer = Timer.periodic(
        const Duration(hours: 24),
        (timer) => _performAutoBackup(),
      );
    });
  }

  // Thực hiện auto backup
  Future<BackupResult> _performAutoBackup() async {
    try {
      print('🚀 Starting automatic backup at ${DateTime.now()}');

      // Lấy dữ liệu từ local storage
      final historicalData = _trackingService.getAllHistoricalData();
      final todayData = await _getTodayDataForBackup();

      if (historicalData.isEmpty && todayData == null) {
        print('ℹ️ No data to backup');
        return BackupResult(
          success: true,
          message: 'No data to backup',
          timestamp: DateTime.now(),
          dataCount: 0,
        );
      }

      // Chuẩn bị dữ liệu backup
      final backupData = {
        'timestamp': DateTime.now().toIso8601String(),
        'historical_data': historicalData.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
        'today_data': todayData?.toJson(),
        'backup_version': '1.0',
      };

      // Upload lên Firebase
      await _firebaseService.saveUserBackup(backupData);

      // Lưu timestamp backup cuối cùng
      await _saveLastBackupTime();

      final dataCount = historicalData.length + (todayData != null ? 1 : 0);

      print('✅ Auto backup completed successfully');
      print('   - Historical days: ${historicalData.length}');
      print('   - Today data: ${todayData != null ? 'Yes' : 'No'}');

      return BackupResult(
        success: true,
        message: 'Backup completed successfully',
        timestamp: DateTime.now(),
        dataCount: dataCount,
      );
    } catch (e) {
      print('❌ Auto backup failed: $e');

      return BackupResult(
        success: false,
        message: 'Backup failed: $e',
        timestamp: DateTime.now(),
        dataCount: 0,
      );
    }
  }

  // Lấy dữ liệu hôm nay để backup
  Future<DailySummary?> _getTodayDataForBackup() async {
    try {
      final distance = _trackingService.dailyDistance;
      final calories = _trackingService.dailyCalories;
      final steps = _trackingService.dailySteps;
      final sessions = _trackingService.todaySessions;

      if (distance > 0 || calories > 0 || steps > 0 || sessions.isNotEmpty) {
        return DailySummary(
          date: _formatDate(DateTime.now()),
          totalDistance: distance,
          totalCalories: calories,
          totalSteps: steps,
          sessionCount: sessions.length,
          sessions: sessions,
        );
      }

      return null;
    } catch (e) {
      print('❌ Error getting today data: $e');
      return null;
    }
  }

  // Test manual backup (cho testing)
  Future<BackupResult> performManualBackup() async {
    print('🧪 Manual backup test initiated');
    return await _performAutoBackup();
  }

  // Simulate backup cho testing
  Future<BackupResult> simulateBackupAfter24Hours() async {
    print('🧪 Simulating 24h backup test...');

    // Tạo dữ liệu test
    await _createTestData();

    // Thực hiện backup
    final result = await _performAutoBackup();

    print('🧪 Simulation completed');
    return result;
  }

  // Tạo dữ liệu test
  Future<void> _createTestData() async {
    print('📊 Creating test data for backup simulation...');

    // Tạo dữ liệu test cho 3 ngày qua
    for (int i = 1; i <= 3; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final testSession = TrackingSession(
        distance: 2.5 + (i * 0.5),
        calories: 150 + (i * 20),
        duration: 25 + (i * 5),
        activityType: i % 2 == 0 ? 'running' : 'walking',
        startTime: date.subtract(Duration(hours: 1)),
        endTime: date,
        route: [],
      );

      // Thêm vào historical data
      // (Trong thực tế, điều này sẽ được xử lý bởi tracking service)
    }

    print('✅ Test data created');
  }

  // Kiểm tra trạng thái backup
  Future<BackupStatus> getBackupStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBackupString = prefs.getString('last_backup_time');
    final isEnabled = prefs.getBool('auto_backup_enabled') ?? true;

    DateTime? lastBackup;
    if (lastBackupString != null) {
      lastBackup = DateTime.parse(lastBackupString);
    }

    // Tính next backup time
    DateTime? nextBackup;
    if (isEnabled) {
      final now = DateTime.now();
      nextBackup = DateTime(now.year, now.month, now.day + 1, 2, 0, 0);
      if (now.hour >= 2) {
        // Nếu đã qua 2h sáng hôm nay, next backup là 2h sáng ngày mai
      } else {
        // Nếu chưa tới 2h sáng hôm nay, next backup là 2h sáng hôm nay
        nextBackup = DateTime(now.year, now.month, now.day, 2, 0, 0);
      }
    }

    return BackupStatus(
      isEnabled: isEnabled,
      lastBackupTime: lastBackup,
      nextBackupTime: nextBackup,
      isTimerActive: _autoBackupTimer?.isActive ?? false,
    );
  }

  // Bật/tắt auto backup
  Future<void> setBackupEnabled(bool enabled) async {
    _isBackupEnabled = enabled;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_backup_enabled', enabled);

    if (enabled) {
      _startAutoBackupTimer();
      print('✅ Auto backup enabled');
    } else {
      _autoBackupTimer?.cancel();
      print('❌ Auto backup disabled');
    }
  }

  // Load backup settings
  Future<void> _loadBackupSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isBackupEnabled = prefs.getBool('auto_backup_enabled') ?? true;
    } catch (e) {
      print('❌ Error loading backup settings: $e');
      _isBackupEnabled = true;
    }
  }

  // Lưu thời gian backup cuối cùng
  Future<void> _saveLastBackupTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'last_backup_time',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      print('❌ Error saving last backup time: $e');
    }
  }

  // Format date
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Dispose
  void dispose() {
    _autoBackupTimer?.cancel();
    print('🛑 AutoBackupService disposed');
  }
}

// Models cho backup
class BackupResult {
  final bool success;
  final String message;
  final DateTime timestamp;
  final int dataCount;

  BackupResult({
    required this.success,
    required this.message,
    required this.timestamp,
    required this.dataCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'dataCount': dataCount,
    };
  }
}

class BackupStatus {
  final bool isEnabled;
  final DateTime? lastBackupTime;
  final DateTime? nextBackupTime;
  final bool isTimerActive;

  BackupStatus({
    required this.isEnabled,
    this.lastBackupTime,
    this.nextBackupTime,
    required this.isTimerActive,
  });
}

// Import classes cần thiết
// Note: Sử dụng classes từ tracking_data_service.dart để tránh duplicate
