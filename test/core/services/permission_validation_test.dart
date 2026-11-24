import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:reminders/core/di/injection.dart';
import 'package:reminders/core/services/background_protection_service.dart';
import 'package:reminders/core/services/location_service.dart';
import 'package:reminders/core/services/notification_service.dart';
import 'package:reminders/core/services/permission_validation_service.dart';
import 'package:reminders/core/services/settings_service.dart';

import 'monitoring_coordinator_test.dart' as fixtures;

class FakeLocationService implements LocationService {
  LocationPermission permission = LocationPermission.always;

  @override
  Future<LocationPermission> checkPermission() async => permission;
  @override
  Future<bool> isLocationServiceEnabled() async => true;
  @override
  Future<LocationPermission> requestPermission() async => permission;
  @override
  Future<Position> getCurrentLocation() => throw UnimplementedError();
  @override
  Stream<Position> getLocationStream() => const Stream.empty();
  @override
  Future<bool> openAppSettings() async => true;
  @override
  double calculateDistance(double a, double b, double c, double d) => 0;
}

class FakeNotificationService implements NotificationService {
  bool granted = true;

  @override
  Future<bool> areNotificationsEnabled() async => granted;
  @override
  Future<void> init() async {}
  @override
  Future<bool> requestPermissions() async => granted;
  @override
  Future<void> showTestNotification({
    required String title,
    required String body,
  }) async {}
  @override
  Future<void> showFullScreenTestNotification() async {}
  @override
  Future<void> cancelAlarm(int reminderId) async {}
  @override
  int? takePendingLaunchReminderId() => null;
}

class FakeBackgroundProtectionService implements BackgroundProtectionService {
  bool exempt = true;

  @override
  Future<bool> isIgnoringBatteryOptimizations() async => exempt;
  @override
  Future<DeviceInfo> getDeviceInfo() async => const DeviceInfo(
        manufacturer: 'test',
        brand: 'test',
        model: 'test',
        sdkInt: 34,
        isOppoOrColorOS: false,
      );
  @override
  Future<bool> requestBatteryOptimizationExemption() async => exempt;
  @override
  Future<bool> openBatteryOptimizationSettings() async => true;
  @override
  Future<bool> openApplicationDetails() async => true;
  @override
  Future<bool> openOppoAutoLaunchSettings() async => true;
  @override
  Future<bool> openOppoAppBatterySettings() async => true;
  @override
  Future<ProtectionStatus> getProtectionStatus() async => ProtectionStatus(
        overallState: ProtectionOverallState.protected,
        isBatteryOptimizationExempt: exempt,
        isLocationAlwaysGranted: true,
        isNotificationGranted: true,
        isOppoOrColorOS: false,
        oemReviewNeeded: false,
        isForegroundServiceRunning: true,
      );
}

void main() {
  late FakeLocationService location;
  late FakeNotificationService notifications;
  late FakeBackgroundProtectionService protection;
  late PermissionValidationService service;

  setUp(() {
    location = FakeLocationService();
    notifications = FakeNotificationService();
    protection = FakeBackgroundProtectionService();

    if (getIt.isRegistered<SettingsService>()) {
      getIt.unregister<SettingsService>();
    }
    if (getIt.isRegistered<BackgroundProtectionService>()) {
      getIt.unregister<BackgroundProtectionService>();
    }
    getIt.registerLazySingleton<SettingsService>(
      () => fixtures.FakeSettingsService(),
    );
    getIt.registerLazySingleton<BackgroundProtectionService>(
      () => protection,
    );
    service = PermissionValidationServiceImpl(location, notifications);
  });

  tearDown(() {
    getIt.unregister<SettingsService>();
    getIt.unregister<BackgroundProtectionService>();
  });

  test('ready when all prerequisites are granted', () async {
    expect(await service.isAppReady(), isTrue);
  });

  test('not ready when notification permission is denied', () async {
    notifications.granted = false;
    expect(await service.isAppReady(), isFalse);
  });

  test('not ready when location is only while-in-use', () async {
    location.permission = LocationPermission.whileInUse;
    expect(await service.isAppReady(), isFalse);
  });

  test('not ready without battery optimisation exemption', () async {
    protection.exempt = false;
    expect(await service.isAppReady(), isFalse);
  });
}
