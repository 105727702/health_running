import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';

class LocationService {
  StreamSubscription<Position>? _positionStreamSubscription;

  // Get current location and check permissions
  static Future<LatLng?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission denied forever. Please enable it in settings',
      );
    }

    Position position = await Geolocator.getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }

  // Start location tracking
  StreamSubscription<Position> startLocationTracking({
    required Function(LatLng) onLocationUpdate,
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 5,
  }) {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            LatLng newPosition = LatLng(position.latitude, position.longitude);
            onLocationUpdate(newPosition);
          },
        );

    return _positionStreamSubscription!;
  }

  // Stop location tracking
  void stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  void dispose() {
    stopLocationTracking();
  }
}
