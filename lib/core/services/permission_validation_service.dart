import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';
import 'package:reminders/core/di/injection.dart';
import 'package:reminders/core/services/background_protection_service.dart';
import 'package:reminders/core/services/settings_service.dart';
import 'location_service.dart';
import 'notification_service.dart';

abstract class PermissionValidationService {
  Future<bool> isAppReady();
  Future<bool> isLocationAlwaysGranted();
  Future<bool> isNotificationGranted();
}

@LazySingleton(as: PermissionValidationService)
class PermissionValidationServiceImpl implements PermissionValidationService {
  final LocationService _locationService;
  final NotificationService _notificationService;

  PermissionValidationServiceImpl(
    this._locationService,
    this._notificationService,
  );

  @override
  Future<bool> isAppReady() async {
    final locationReady = await isLocationAlwaysGranted();
    final onboardingCompleted = getIt<SettingsService>().isOnboardingCompleted();
    final reliabilityReady = await _isBackgroundReliabilityReady();
    return locationReady && onboardingCompleted && reliabilityReady;
  }

  /// Background monitoring can only survive screen lock and Doze when the app
  /// is exempt from battery optimizations. Without the exemption the platform
  /// also refuses to restart the location foreground service from a background
  /// broadcast (Android 12+), so this is a hard requirement on Android.
  Future<bool> _isBackgroundReliabilityReady() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;
    try {
      return await getIt<BackgroundProtectionService>()
          .isIgnoringBatteryOptimizations();
    } catch (e) {
      debugPrint('[PERMISSIONS] Battery exemption check failed: $e');
      return false;
    }
  }

  /// "While using the app" is not enough: geofences and the foreground
  /// location service need "Allow all the time" to work while the screen is
  /// locked (and to restart on Android 14+).
  @override
  Future<bool> isLocationAlwaysGranted() async {
    final status = await _locationService.checkPermission();
    return status == LocationPermission.always;
  }

  @override
  Future<bool> isNotificationGranted() async {
    return _notificationService.areNotificationsEnabled();
  }
}
