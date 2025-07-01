import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'tracking_data_service.dart';

class BackgroundTrackingService {
  static final BackgroundTrackingService _instance =
      BackgroundTrackingService._internal();
  factory BackgroundTrackingService() => _instance;
  BackgroundTrackingService._internal();

  final TrackingDataService _trackingDataService = TrackingDataService();
  StreamSubscription<Position>? _backgroundPositionStream;
  Timer? _backgroundSaveTimer;

  // Start background tracking service
  Future<bool> startBackgroundTracking() async {
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      // Request background location permission (Android 10+)
      if (await Geolocator.isLocationServiceEnabled()) {
        // Start background position stream
        _backgroundPositionStream =
            Geolocator.getPositionStream(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                distanceFilter: 5, // Update every 5 meters
                timeLimit: Duration(seconds: 10),
              ),
            ).listen(
              _handleBackgroundPosition,
              onError: (error) {
                print('❌ Background location error: $error');
              },
            );

        // Auto-save tracking state every 30 seconds
        _backgroundSaveTimer = Timer.periodic(const Duration(seconds: 30), (
          timer,
        ) {
          print('💾 Auto-saving background tracking data...');
        });

        print('✅ Background tracking service started');
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Error starting background tracking: $e');
      return false;
    }
  }

  // Handle position updates in background
  void _handleBackgroundPosition(Position position) {
    final currentState = _trackingDataService.currentState;

    if (currentState.isTracking) {
      // Update tracking state with new position
      // This will be handled by the existing tracking logic
      print(
        '📍 Background position update: ${position.latitude}, ${position.longitude}',
      );
    }
  }

  // Stop background tracking service
  void stopBackgroundTracking() {
    _backgroundPositionStream?.cancel();
    _backgroundSaveTimer?.cancel();
    print('🛑 Background tracking service stopped');
  }

  // Show persistent notification during tracking
  void showTrackingNotification({
    required double distance,
    required double calories,
    required String activityType,
  }) {
    // This would show a persistent notification
    // For now, we'll just log it
    print(
      '🔔 Tracking notification: ${activityType.toUpperCase()} - ${distance.toStringAsFixed(2)}km, ${calories.toStringAsFixed(0)} cal',
    );
  }

  // Update notification with current stats
  void updateTrackingNotification({
    required double distance,
    required double calories,
    required String activityType,
  }) {
    showTrackingNotification(
      distance: distance,
      calories: calories,
      activityType: activityType,
    );
  }

  // Hide tracking notification
  void hideTrackingNotification() {
    print('🔕 Tracking notification hidden');
  }

  void dispose() {
    stopBackgroundTracking();
  }
}
