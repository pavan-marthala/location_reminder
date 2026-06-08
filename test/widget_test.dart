import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:geolocator/geolocator.dart';
import 'package:reminders/core/services/alarm_service.dart';
import 'package:reminders/core/services/background_service.dart';
import 'package:reminders/core/services/location_service.dart';
import 'package:reminders/core/services/notification_service.dart';
import 'package:reminders/core/services/permission_validation_service.dart';
import 'package:reminders/features/infrastructure_validation/presentation/bloc/validation_bloc.dart';
import 'package:reminders/core/services/app_routing_notifier.dart';
import 'package:reminders/main.dart';

import 'package:reminders/core/services/settings_service.dart';
import 'package:reminders/core/services/monitoring_coordinator.dart';

class MockNotificationService implements NotificationService {
  @override
  Future<void> init() async {}
  @override
  Future<bool> requestPermissions() async => true;
  @override
  Future<void> showTestNotification({
    required String title,
    required String body,
  }) async {}
  @override
  Future<void> showFullScreenTestNotification() async {}
  @override
  Future<bool> areNotificationsEnabled() async => true;
}

class MockAlarmService implements AlarmService {
  @override
  Future<void> init() async {}
  @override
  Future<void> playAlarm([String? customPath]) async {}
  @override
  Future<void> stopAlarm() async {}
  @override
  bool get isPlaying => false;
}

class MockLocationService implements LocationService {
  @override
  Future<bool> isLocationServiceEnabled() async => true;
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.always;
  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.always;
  @override
  Future<Position> getCurrentLocation() async => Position(
        latitude: 0.0,
        longitude: 0.0,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );
  @override
  Stream<Position> getLocationStream() => const Stream.empty();
  @override
  Future<bool> openAppSettings() async => true;
  @override
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) =>
      0.0;
}

class MockBackgroundService implements BackgroundService {
  @override
  Future<void> init() async {}
  @override
  Future<void> startService() async {}
  @override
  Future<void> stopService() async {}
  @override
  Future<bool> isRunning() async => false;
  @override
  Stream<Map<String, dynamic>?> get backgroundUpdates => const Stream.empty();
}

class MockPermissionValidationService implements PermissionValidationService {
  @override
  Future<bool> isAppReady() async => false; // Route to validation page for test
  @override
  Future<bool> isLocationAlwaysGranted() async => true;
  @override
  Future<bool> isNotificationGranted() async => true;
}

class MockSettingsService implements SettingsService {
  String _alarmTone = 'assets/audio/Daybreak.mp3';
  bool _monitoringEnabled = true;

  @override
  Future<void> saveSelectedAlarmTonePath(String path) async {
    _alarmTone = path;
  }

  @override
  String getSelectedAlarmTonePath() => _alarmTone;

  @override
  Future<void> saveMonitoringEnabled(bool enabled) async {
    _monitoringEnabled = enabled;
  }

  @override
  bool isMonitoringEnabled() => _monitoringEnabled;
}

class MockMonitoringCoordinator implements MonitoringCoordinator {
  bool _monitoringEnabled = true;

  @override
  Future<void> evaluateMonitoringState() async {}

  @override
  Future<void> setMonitoringEnabled(bool enabled) async {
    _monitoringEnabled = enabled;
  }

  @override
  bool isMonitoringEnabled() => _monitoringEnabled;
}

void main() {
  setUpAll(() {
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<NotificationService>()) {
      getIt.registerLazySingleton<NotificationService>(
        () => MockNotificationService(),
      );
      getIt.registerLazySingleton<AlarmService>(() => MockAlarmService());
      getIt.registerLazySingleton<LocationService>(() => MockLocationService());
      getIt.registerLazySingleton<BackgroundService>(
        () => MockBackgroundService(),
      );
      getIt.registerLazySingleton<SettingsService>(
        () => MockSettingsService(),
      );
      getIt.registerLazySingleton<MonitoringCoordinator>(
        () => MockMonitoringCoordinator(),
      );
      getIt.registerLazySingleton<PermissionValidationService>(
        () => MockPermissionValidationService(),
      );
      getIt.registerLazySingleton<AppRoutingNotifier>(
        () => AppRoutingNotifier(getIt<PermissionValidationService>()),
      );
      getIt.registerFactory<ValidationBloc>(
        () => ValidationBloc(
          getIt<NotificationService>(),
          getIt<AlarmService>(),
          getIt<LocationService>(),
          getIt<BackgroundService>(),
          getIt<AppRoutingNotifier>(),
          getIt<SettingsService>(),
          getIt<MonitoringCoordinator>(),
        ),
      );
    }
  });

  testWidgets('Infrastructure Validation screen mounts successfully',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Allow asynchronous operations to run
    await tester.pumpAndSettle();

    // Verify that the title is displayed.
    expect(find.text('Infrastructure Validation'), findsOneWidget);
  });
}
