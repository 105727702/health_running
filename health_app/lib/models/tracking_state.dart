import 'package:latlong2/latlong.dart';

class TrackingState {
  final List<LatLng> route;
  final double totalDistance;
  final double totalCalories;
  final bool isTracking;
  final LatLng? lastPosition;
  final LatLng? currentPosition;
  final double userWeight;
  final String activityType;

  TrackingState({
    this.route = const [],
    this.totalDistance = 0.0,
    this.totalCalories = 0.0,
    this.isTracking = false,
    this.lastPosition,
    this.currentPosition,
    this.userWeight = 70.0,
    this.activityType = 'walking',
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
    );
  }
}
