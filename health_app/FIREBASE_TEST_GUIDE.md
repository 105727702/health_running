# 🚀 Firebase Services Test Guide

## Cách sử dụng Firebase Services Test

### 1. Khởi chạy ứng dụng
```bash
flutter run
```

### 2. Truy cập Firebase Test Page (Admin Only)
- Đăng nhập với tài khoản **Admin**
- Vào **Settings** page từ bottom navigation
- Tìm section **Admin Panel** (chỉ hiển thị cho admin)
- Tap **Firebase Test** để mở test interface

> **Lưu ý**: Firebase Test page chỉ có thể truy cập bởi users có role `Admin`. Nếu bạn không thấy Admin Panel section trong Settings, hãy đảm bảo tài khoản của bạn có role admin trong Firestore.

### 3. Các test có sẵn

#### 📊 **Test Analytics**
- Track screen views
- Log button taps
- Custom events
- User properties
- **Kết quả**: Xem trong Firebase Console > Analytics

#### 💥 **Test Crashlytics** 
- Custom messages
- Non-fatal errors
- User actions
- Custom keys
- **Kết quả**: Xem trong Firebase Console > Crashlytics

#### ⚡ **Test Performance**
- Async operations
- Auth operations
- Location services
- Database operations
- **Kết quả**: Xem trong Firebase Console > Performance (delay 12-24h)

#### 🏃 **Test Tracking State**
- Start/stop workout tracking
- Add GPS positions
- Calculate distance & calories
- Integration với Firebase services
- **Kết quả**: Realtime trong app logs

#### 🔥 **Test Error Simulation**
- Network errors
- Auth errors
- Custom error handling
- **Kết quả**: Logs trong Crashlytics

#### 🚀 **Test All Services**
- Chạy tất cả tests theo sequence
- Comprehensive testing
- **Kết quả**: Full Firebase integration test

### 4. Xem kết quả

#### Real-time Logs
- Trong app: Test logs section
- Theo dõi real-time execution
- Color-coded results (✅ success, ❌ error, 🎉 completion)

#### Firebase Console
1. **Analytics**: `https://console.firebase.google.com/project/YOUR_PROJECT/analytics`
2. **Crashlytics**: `https://console.firebase.google.com/project/YOUR_PROJECT/crashlytics`  
3. **Performance**: `https://console.firebase.google.com/project/YOUR_PROJECT/performance`

### 5. Debug Information

#### Debug Logs
Trong debug mode, check console output:
```
🔥 Initializing Firebase...
✅ Firebase initialized successfully
📊 Analytics event logged: button_tap
💥 Crashlytics error recorded
⚡ Performance trace started: test_async_operation
```

#### Common Issues
- **No data in console**: Wait 5-10 minutes for Analytics/Crashlytics
- **Performance data missing**: Wait 12-24 hours
- **Build errors**: Run `flutter clean && flutter pub get`

### 6. TrackingState với Firebase

```dart
// Start tracking
TrackingState state = TrackingState().startTracking();

// Add positions (with Firebase performance tracking)
state = await state.addPosition(LatLng(21.0285, 105.8542));

// Stop tracking (logs to Firebase Analytics)
state = state.stopTracking();

// Get analytics summary
Map<String, Object> summary = state.getWorkoutSummary();
```

### 7. Custom Firebase Usage

```dart
// Track custom events
await FirebaseUtils.trackButtonTap('my_button');
await FirebaseUtils.trackNavigation('my_screen');

// Log errors with context
await FirebaseUtils.logNonFatalError(
  error,
  stackTrace,
  context: 'My operation failed',
  screenName: 'my_screen',
);

// Performance tracking
await FirebaseUtils.trackAsyncOperation(
  'my_operation',
  () => myAsyncFunction(),
  attributes: {'param': 'value'},
);
```

### 8. Best Practices

#### Testing
- Test trên device thật (có Google Play Services)
- Test cả debug và release builds
- Verify data trong Firebase Console
- Check logs cho errors

#### Production
- Disable debug logging
- Monitor crash rates
- Set up alerts
- Regular data analysis

### 9. Setup Admin Role

Để truy cập Firebase Test page, bạn cần có admin role:

#### Firestore Setup
1. Mở Firebase Console > Firestore
2. Tạo collection `users` (nếu chưa có)
3. Tạo document với ID = user UID
4. Thêm field `role` với value `admin`

```json
// Firestore: collection "users", document "<user-uid>"
{
  "role": "admin",
  "email": "admin@example.com",
  "createdAt": "2025-06-30T..."
}
```

#### Code Implementation
```dart
// Check user role in Firestore
final userDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(FirebaseAuth.instance.currentUser?.uid)
    .get();

final userRole = userDoc.data()?['role'] ?? 'user';
bool isAdmin = userRole == 'admin';
```

### 10. Setup Admin Role

#### Tạo Admin Role trong Firestore
1. Mở Firebase Console > Firestore Database
2. Tạo collection `user_roles` 
3. Tạo document với ID = User UID
4. Thêm field:
   ```json
   {
     "role": "admin",
     "email": "your-email@gmail.com",
     "created_at": "timestamp"
   }
   ```

#### Hoặc thêm email vào admin list
Trong `lib/services/role_service.dart`:
```dart
static const List<String> _adminEmails = [
  'admin@healthapp.com',
  'huyhoang17012006@gmail.com',
  'your-email@gmail.com', // Thêm email admin của bạn
];
```

#### Kiểm tra Admin Role
```dart
// Check user role in current app
final role = await RoleService().getCurrentUserRole();
bool isAdmin = role == UserRole.admin;
```

### 11. Next Steps

- ✅ Basic Firebase integration working
- ✅ Test page với comprehensive testing
- ✅ TrackingState integration
- ✅ Admin-only Firebase Test access
- 🔄 Production deployment
- 🔄 Advanced analytics setup
- 🔄 Custom dashboards

---

**🎉 Firebase Services đã sẵn sàng sử dụng!**

Chạy tests và check Firebase Console để xác nhận data collection hoạt động đúng.
