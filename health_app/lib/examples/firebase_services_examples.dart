// ============================================================================
// FIREBASE SERVICES USAGE EXAMPLES
// ============================================================================
//
// Đây là file hướng dẫn cách sử dụng các Firebase services trong ứng dụng
// Health Tracking App. File này chứa các ví dụ thực tế về cách tích hợp
// Analytics, Crashlytics và Performance Monitoring.
//
// ============================================================================

import 'package:flutter/material.dart';
import '../utils/firebase_utils.dart';
import '../services/data_monitoring/firebase_analytics_service.dart';
import '../services/data_monitoring/firebase_crashlytics_service.dart';

class FirebaseServicesExamples {
  // ========================================================================
  // 1. KHỞI TẠO SERVICES
  // ========================================================================

  /// Khởi tạo tất cả Firebase services (đã được gọi trong main.dart)
  static Future<void> initializeServices() async {
    await FirebaseUtils.initialize();
  }

  // ========================================================================
  // 2. ANALYTICS - THEO DÕI HÀNH VI NGƯỜI DÙNG
  // ========================================================================

  /// Theo dõi khi người dùng mở một màn hình
  static Future<void> trackScreenView(String screenName) async {
    // Cách 1: Sử dụng FirebaseUtils (được khuyên dùng)
    await FirebaseUtils.trackNavigation(screenName);

    // Cách 2: Sử dụng trực tiếp service
    await FirebaseAnalyticsService.logScreenView(screenName: screenName);
  }

  /// Theo dõi khi người dùng đăng nhập
  static Future<void> trackUserLogin(String method, String userId) async {
    // Đăng nhập thành công
    await FirebaseAnalyticsService.logLogin(loginMethod: method);

    // Đặt thông tin người dùng
    await FirebaseUtils.setUserSession(
      userId: userId,
      email: 'user@example.com',
      userType: 'premium',
    );
  }

  /// Theo dõi hoạt động workout
  static Future<void> trackWorkoutActivity() async {
    // Bắt đầu workout
    await FirebaseAnalyticsService.logWorkoutStart(
      workoutType: 'running',
      location: 'outdoor',
    );

    // Kết thúc workout
    await FirebaseAnalyticsService.logWorkoutEnd(
      workoutType: 'running',
      duration: 1800, // 30 phút
      distance: 5000, // 5km
      calories: 300,
    );
  }

  /// Theo dõi tương tác với nút bấm
  static Future<void> trackButtonInteraction() async {
    await FirebaseUtils.trackButtonTap(
      'start_workout_button',
      screenName: 'home_screen',
    );
  }

  /// Theo dõi mục tiêu được đạt
  static Future<void> trackGoalAchievement() async {
    await FirebaseAnalyticsService.logGoalAchievement(
      goalType: 'distance',
      goalValue: '10km',
    );
  }

  // ========================================================================
  // 3. CRASHLYTICS - THEO DÕI LỖI VÀ CRASH
  // ========================================================================

  /// Ghi lại lỗi không nghiêm trọng
  static Future<void> logNonFatalError() async {
    try {
      // Code có thể gây lỗi
      throw Exception('Something went wrong');
    } catch (error, stackTrace) {
      // Ghi lại lỗi với context
      await FirebaseUtils.logNonFatalError(
        error,
        stackTrace,
        context: 'User was trying to start workout',
        screenName: 'workout_screen',
        additionalInfo: {
          'user_action': 'start_workout',
          'workout_type': 'running',
        },
      );
    }
  }

  /// Ghi lại thông tin custom cho debugging
  static Future<void> logCustomInfo(String userId) async {
    // Đặt user ID
    await FirebaseCrashlyticsService.setUserId(userId);

    // Đặt custom keys
    await FirebaseCrashlyticsService.setCustomKey('user_type', 'premium');
    await FirebaseCrashlyticsService.setCustomKey('app_version', '1.0.0');

    // Ghi log message
    await FirebaseUtils.logCustomMessage('User started new workout session');
  }

  /// Xử lý lỗi authentication
  static Future<void> handleAuthError(dynamic error) async {
    await FirebaseCrashlyticsService.logAuthError(
      'login_failed',
      error.toString(),
    );
  }

  // ========================================================================
  // 4. PERFORMANCE - THEO DÕI HIỆU SUẤT
  // ========================================================================

  /// Theo dõi hiệu suất của operation bất đồng bộ
  static Future<String> trackAsyncOperation() async {
    return await FirebaseUtils.trackAsyncOperation(
      'load_user_data',
      () async {
        // Giả lập việc tải data
        await Future.delayed(const Duration(seconds: 2));
        return 'User data loaded';
      },
      attributes: {'data_source': 'firestore', 'cache_enabled': 'true'},
    );
  }

  /// Theo dõi hiệu suất authentication
  static Future<bool> trackAuthOperation() async {
    return await FirebaseUtils.trackAuthOperation('google_sign_in', () async {
      // Thực hiện đăng nhập Google
      await Future.delayed(const Duration(seconds: 3));
      return true;
    }, method: 'google');
  }

  /// Theo dõi hiệu suất location services
  static Future<Map<String, double>> trackLocationOperation() async {
    return await FirebaseUtils.trackLocationOperation(
      'get_current_location',
      () async {
        // Lấy vị trí hiện tại
        await Future.delayed(const Duration(seconds: 1));
        return {'latitude': 21.0285, 'longitude': 105.8542};
      },
      accuracy: 'high',
    );
  }

  /// Theo dõi hiệu suất database operations
  static Future<List<String>> trackDatabaseOperation() async {
    return await FirebaseUtils.trackDatabaseOperation(
      'fetch_workouts',
      () async {
        // Lấy danh sách workouts từ Firestore
        await Future.delayed(const Duration(milliseconds: 500));
        return ['workout1', 'workout2', 'workout3'];
      },
      collection: 'workouts',
    );
  }

  // ========================================================================
  // 5. TÍCH HỢP VÀO UI COMPONENTS
  // ========================================================================

  /// Example của một StatefulWidget có tích hợp Firebase services
  static Widget buildExampleWidget() {
    return const FirebaseIntegratedWidget();
  }
}

/// Example widget tích hợp Firebase services
class FirebaseIntegratedWidget extends StatefulWidget {
  const FirebaseIntegratedWidget({super.key});

  @override
  State<FirebaseIntegratedWidget> createState() =>
      _FirebaseIntegratedWidgetState();
}

class _FirebaseIntegratedWidgetState extends State<FirebaseIntegratedWidget> {
  @override
  void initState() {
    super.initState();
    // Track screen view khi widget được tạo
    _trackScreenView();
  }

  Future<void> _trackScreenView() async {
    await FirebaseUtils.trackNavigation('example_screen');
  }

  Future<void> _handleButtonPress() async {
    try {
      // Track button tap
      await FirebaseUtils.trackButtonTap('example_button');

      // Thực hiện operation với performance tracking
      final result = await FirebaseUtils.trackAsyncOperation(
        'example_operation',
        () async {
          // Simulate some work
          await Future.delayed(const Duration(seconds: 1));
          return 'Operation completed';
        },
      );

      // Show result
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result)));
      }
    } catch (error, stackTrace) {
      // Log error to Crashlytics
      await FirebaseUtils.logNonFatalError(
        error,
        stackTrace,
        context: 'Error in example button handler',
        screenName: 'example_screen',
      );

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('An error occurred')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Integration Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Firebase Services Integration Example',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _handleButtonPress,
              child: const Text('Test Firebase Integration'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                await FirebaseAnalyticsService.logFeatureUsage(
                  featureName: 'help_button',
                  additionalParameters: {'screen': 'example'},
                );
              },
              icon: const Icon(Icons.help),
              label: const Text('Help'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 6. BEST PRACTICES VÀ GHI CHÚ QUAN TRỌNG
// ============================================================================

/*
🔥 BEST PRACTICES:

1. ANALYTICS:
   - Sử dụng tên event nhất quán và có ý nghĩa
   - Không gửi thông tin cá nhân nhạy cảm
   - Giới hạn số lượng custom parameters (tối đa 25)
   - Sử dụng predefined events khi có thể

2. CRASHLYTICS:
   - Luôn set user ID và custom keys cho context
   - Log non-fatal errors để debug
   - Không log quá nhiều (có thể ảnh hưởng performance)
   - Sử dụng meaningful error messages

3. PERFORMANCE:
   - Chỉ track các operations quan trọng
   - Sử dụng attributes để phân loại traces
   - Đặt tên traces rõ ràng và nhất quán
   - Tránh tạo quá nhiều custom traces

4. CHUNG:
   - Luôn wrap Firebase calls trong try-catch
   - Kiểm tra kDebugMode để tránh spam logs
   - Sử dụng FirebaseUtils cho convenience
   - Test trên cả debug và release builds

⚠️ LƯU Ý:
- Firebase services chỉ hoạt động trên thiết bị thật hoặc emulator có Google Play Services
- Debug builds có thể có behavior khác với release builds
- Crashlytics có thể mất vài phút để hiển thị data trên console
- Performance data thường delay 12-24h trước khi xuất hiện

🚀 SETUP BỔ SUNG CẦN THIẾT:
1. Thêm google-services.json vào android/app/
2. Cấu hình build.gradle files
3. Thêm permissions cần thiết trong AndroidManifest.xml
4. Cấu hình iOS nếu cần (GoogleService-Info.plist)
*/
