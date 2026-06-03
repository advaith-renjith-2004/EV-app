import 'dart:math';

class GeofencingService {
  // Taxi Depot Central coordinates (Kochi, matching simulator)
  static const double depotLat = 9.9312;
  static const double depotLng = 76.2673;
  
  // Radius of the Earth in kilometers
  static const double earthRadiusKm = 6371.0;

  /// Calculates the distance in meters between two coordinates using the Haversine Formula
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c * 1000.0; // Returns distance in meters
  }

  static double _toRadians(double degree) {
    return degree * pi / 180.0;
  }

  /// Verifies if a given coordinate is within the geofence radius (default: 50 meters)
  static bool isWithinDepot(double lat, double lng, {double radiusMeters = 50.0}) {
    final distance = calculateDistance(lat, lng, depotLat, depotLng);
    return distance <= radiusMeters;
  }
}
