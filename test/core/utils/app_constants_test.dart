import 'package:flutter_test/flutter_test.dart';
import 'package:reminders/core/utils/app_constants.dart';

void main() {
  group('AppConstants geofence radius', () {
    test('clamps a radius below the minimum to 150 m', () {
      expect(AppConstants.clampGeofenceRadius(100),
          AppConstants.minGeofenceRadiusMeters);
    });

    test('accepts the maximum radius of 10 km unchanged', () {
      expect(AppConstants.clampGeofenceRadius(10000), 10000);
    });

    test('clamps a radius above the maximum to 10 km', () {
      expect(AppConstants.clampGeofenceRadius(10001),
          AppConstants.maxGeofenceRadiusMeters);
    });

    test('reports validity only inside the supported range', () {
      expect(AppConstants.isValidGeofenceRadius(149), isFalse);
      expect(AppConstants.isValidGeofenceRadius(150), isTrue);
      expect(AppConstants.isValidGeofenceRadius(10000), isTrue);
      expect(AppConstants.isValidGeofenceRadius(10001), isFalse);
    });
  });
}
