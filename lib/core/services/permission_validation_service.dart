import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';
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
    final notificationsReady = await isNotificationGranted();
    return locationReady && notificationsReady;
  }

  @override
  Future<bool> isLocationAlwaysGranted() async {
    final status = await _locationService.checkPermission();
    return status == LocationPermission.always ||
        status == LocationPermission.whileInUse;
  }

  @override
  Future<bool> isNotificationGranted() async {
    return _notificationService.areNotificationsEnabled();
  }
}
