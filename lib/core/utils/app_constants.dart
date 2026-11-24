import 'dart:math' as math;

class AppConstants {
  AppConstants._();

  static const double duplicateThresholdMeters = 30.0;

  /// Smallest radius that can be registered as a geofence. Kept in sync with
  /// the native `GeofenceManager.MIN_RADIUS_METERS` floor on Android.
  static const double minGeofenceRadiusMeters = 150.0;

  /// Largest radius the picker allows for a single reminder.
  static const double maxGeofenceRadiusMeters = 10000.0;

  /// Clamps a raw distance to the supported geofence radius range.
  static double clampGeofenceRadius(double meters) {
    return math.min(
      math.max(meters, minGeofenceRadiusMeters),
      maxGeofenceRadiusMeters,
    );
  }

  /// Whether [meters] is inside the supported geofence radius range.
  static bool isValidGeofenceRadius(double meters) {
    return meters >= minGeofenceRadiusMeters &&
        meters <= maxGeofenceRadiusMeters;
  }
}
