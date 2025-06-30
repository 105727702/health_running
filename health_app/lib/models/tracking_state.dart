import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import '../utils/firebase_utils.dart';

class TrackingState {
  final List<LatLng> route;
  final double totalDistance;
  final double totalCalories;
  final bool isTracking;
  final LatLng? lastPosition;
  final LatLng? currentPosition;
  final double userWeight;
  final String activityType;
  final DateTime? startTime;
  final DateTime? endTime;
  final int sessionId;

  TrackingState({
    this.route = const [],
    this.totalDistance = 0.0,
    this.totalCalories = 0.0,
    this.isTracking = false,
    this.lastPosition,
    this.currentPosition,
    this.userWeight = 70.0,
    this.activityType = 'walking',
    this.startTime,
    this.endTime,
    this.sessionId = 0,
  });

  TrackingState copyWith({
    List<LatLng>? route,
    double? totalDistance,
    double? totalCalories,
    bool? isTracking,
    LatLng? lastPosition,
    LatLng? currentPosition,
    double? userWeight,
    String? activityType,
    DateTime? startTime,
    DateTime? endTime,
    int? sessionId,
  }) {
    return TrackingState(
      route: route ?? List.from(this.route),
      totalDistance: totalDistance ?? this.totalDistance,
      totalCalories: totalCalories ?? this.totalCalories,
      isTracking: isTracking ?? this.isTracking,
      lastPosition: lastPosition ?? this.lastPosition,
      currentPosition: currentPosition ?? this.currentPosition,
      userWeight: userWeight ?? this.userWeight,
      activityType: activityType ?? this.activityType,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  /// Start tracking with Firebase analytics
  TrackingState startTracking() {
    final now = DateTime.now();
    final newState = copyWith(
      isTracking: true,
      startTime: now,
      sessionId: now.millisecondsSinceEpoch,
    );

    // Track workout start with Firebase
    _trackWorkoutStart(newState);

    return newState;
  }

  /// Stop tracking with Firebase analytics
  TrackingState stopTracking() {
    final now = DateTime.now();
    final newState = copyWith(isTracking: false, endTime: now);

    // Track workout end with Firebase
    _trackWorkoutEnd(newState);

    return newState;
  }

  /// Add position to route with Firebase performance tracking
  Future<TrackingState> addPosition(LatLng position) async {
    return await FirebaseUtils.trackAsyncOperation(
      'add_position_to_route',
      () async {
        final updatedRoute = List<LatLng>.from(route)..add(position);

        // Calculate new distance
        double newDistance = totalDistance;
        if (lastPosition != null) {
          final distance = _calculateDistance(lastPosition!, position);
          newDistance += distance;
        }

        // Calculate calories
        final newCalories = _calculateCalories(newDistance);

        return copyWith(
          route: updatedRoute,
          totalDistance: newDistance,
          totalCalories: newCalories,
          lastPosition: currentPosition,
          currentPosition: position,
        );
      },
      attributes: {
        'activity_type': activityType,
        'route_points': route.length.toString(),
      },
    );
  }

  /// Track workout start
  static void _trackWorkoutStart(TrackingState state) {
    FirebaseUtils.trackWorkoutSession(
      workoutType: state.activityType,
      durationSeconds: 0,
      distance: 0.0,
      calories: 0,
      location: 'outdoor',
    );

    FirebaseUtils.logCustomMessage('Workout started: ${state.activityType}');
  }

  /// Track workout end
  static void _trackWorkoutEnd(TrackingState state) {
    final duration = state.startTime != null && state.endTime != null
        ? state.endTime!.difference(state.startTime!).inSeconds
        : 0;

    FirebaseUtils.trackWorkoutSession(
      workoutType: state.activityType,
      durationSeconds: duration,
      distance: state.totalDistance,
      calories: state.totalCalories.round(),
      location: 'outdoor',
    );

    FirebaseUtils.logCustomMessage(
      'Workout completed: ${state.activityType}, '
      'Distance: ${state.totalDistance.toStringAsFixed(2)}m, '
      'Duration: ${duration}s, '
      'Calories: ${state.totalCalories.round()}',
    );
  }

  /// Calculate distance between two points
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Earth radius in meters
    final double lat1Rad = point1.latitude * (math.pi / 180);
    final double lat2Rad = point2.latitude * (math.pi / 180);
    final double deltaLatRad =
        (point2.latitude - point1.latitude) * (math.pi / 180);
    final double deltaLngRad =
        (point2.longitude - point1.longitude) * (math.pi / 180);

    final double a =
        math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLngRad / 2) *
            math.sin(deltaLngRad / 2);
    final double c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  /// Calculate calories based on distance and activity
  double _calculateCalories(double distanceInMeters) {
    // Calories per meter based on activity type and weight
    double caloriesPerMeter;
    switch (activityType.toLowerCase()) {
      case 'running':
        caloriesPerMeter = userWeight * 0.001 * 1.2;
        break;
      case 'cycling':
        caloriesPerMeter = userWeight * 0.001 * 0.8;
        break;
      case 'walking':
      default:
        caloriesPerMeter = userWeight * 0.001 * 0.5;
        break;
    }
    return distanceInMeters * caloriesPerMeter;
  }

  /// Get workout summary for analytics
  Map<String, Object> getWorkoutSummary() {
    final duration = startTime != null && endTime != null
        ? endTime!.difference(startTime!).inSeconds
        : 0;

    return {
      'activity_type': activityType,
      'duration_seconds': duration,
      'distance_meters': totalDistance,
      'calories': totalCalories.round(),
      'route_points': route.length,
      'user_weight': userWeight,
      'session_id': sessionId,
    };
  }
}
