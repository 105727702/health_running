import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

class DistanceCalculator {
  // Calculate distance between two points using Haversine formula
  static double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // km

    double lat1Rad = point1.latitude * math.pi / 180;
    double lat2Rad = point2.latitude * math.pi / 180;
    double deltaLat = (point2.latitude - point1.latitude) * math.pi / 180;
    double deltaLng = (point2.longitude - point1.longitude) * math.pi / 180;

    double a =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  // Calculate total distance for a route
  static double calculateTotalDistance(List<LatLng> route) {
    if (route.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 1; i < route.length; i++) {
      totalDistance += calculateDistance(route[i - 1], route[i]);
    }
    return totalDistance;
  }
}
