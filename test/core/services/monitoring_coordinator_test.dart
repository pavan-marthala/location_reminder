import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:reminders/core/di/injection.dart';
import 'package:reminders/core/services/background_service.dart';
import 'package:reminders/core/services/geofence_service.dart';
import 'package:reminders/core/services/monitoring_coordinator.dart';
import 'package:reminders/core/services/settings_service.dart';
import 'package:reminders/features/reminders/domain/entities/reminder_entity.dart';
import 'package:reminders/features/reminders/domain/entities/reminder_enums.dart';
import 'package:reminders/features/reminders/domain/repositories/reminder_repository.dart';

import 'geofence_fingerprint_test.dart' as fixtures;

class FakeSettingsService implements SettingsService {
  bool _monitoringEnabled = true;

  @override
  bool isMonitoringEnabled() => _monitoringEnabled;

  @override
  Future<void> saveMonitoringEnabled(bool enabled) async {
    _monitoringEnabled = enabled;
  }

  @override
  Future<void> saveSelectedAlarmTonePath(String path) async {}
  @override
  String getSelectedAlarmTonePath() => 'assets/audio/Daybreak.mp3';
  @override
  Future<void> setOnboardingCompleted(bool completed) async {}
  @override
  bool isOnboardingCompleted() => true;
  @override
  Future<void> saveVibrationEnabled(bool enabled) async {}
  @override
  bool isVibrationEnabled() => true;
  @override
  Future<void> saveVibrationPattern(VibrationPattern pattern) async {}
  @override
  VibrationPattern getVibrationPattern() => VibrationPattern.defaultPattern;
  @override
  Future<void> saveSortOption(SortOption option) async {}
  @override
  SortOption getSortOption() => SortOption.recentlyCreated;
}

class FakeBackgroundService implements BackgroundService {
  final _updates = StreamController<Map<String, dynamic>?>.broadcast();
  int startCalls = 0;
  int stopCalls = 0;
  int refreshCalls = 0;
  bool running = false;

  @override
  Stream<Map<String, dynamic>?> get backgroundUpdates => _updates.stream;
  @override
  Future<void> init() async {}
  @override
  Future<void> startService() async {
    startCalls++;
    running = true;
  }

  @override
  Future<void> stopService() async {
    stopCalls++;
    running = false;
  }

  @override
  Future<bool> isRunning() async => running;
  @override
  Future<void> refreshMonitoring({
    int? cycleId,
    String? source,
    String? reason,
  }) async {
    refreshCalls++;
  }
}

class FakeReminderRepository implements ReminderRepository {
  final _controller = StreamController<List<ReminderEntity>>.broadcast();
  List<ReminderEntity> _reminders = [];

  @override
  Stream<List<ReminderEntity>> watchAllReminders() => _controller.stream;
  @override
  Future<List<ReminderEntity>> getAllReminders() async => _reminders;
  @override
  Future<int> reactivateExpiredSnoozes() async => 0;
  @override
  Future<int> claimTrigger(int id, DateTime now) async => 0;

  void emit(List<ReminderEntity> reminders) {
    _reminders = reminders;
    _controller.add(reminders);
  }

  @override
  Future<ReminderEntity?> getReminderById(int id) async => null;
  @override
  Stream<ReminderEntity?> watchReminderById(int id) =>
      const Stream<ReminderEntity?>.empty();
  @override
  Future<int> createReminder(ReminderEntity reminder) async => 1;
  @override
  Future<void> updateReminder(ReminderEntity reminder) async {}
  @override
  Future<void> deleteReminder(int id) async {}
  @override
  Future<void> toggleReminder(int id, bool isEnabled) async {}
}

class FakeGeofenceService implements GeofenceService {
  int syncCalls = 0;
  int clearCalls = 0;
  List<ReminderEntity> lastSynced = [];

  @override
  Future<bool> syncGeofences(List<ReminderEntity> reminders) async {
    syncCalls++;
    lastSynced = reminders;
    return true;
  }

  @override
  Future<void> clearAll() async {
    clearCalls++;
  }

  @override
  Future<GeofenceStatus> getStatus() async => const GeofenceStatus(
        syncedCount: 0,
        lastEventAt: null,
        lastEvent: null,
        lastError: null,
        hasBackgroundLocation: true,
      );
}

void main() {
  late FakeReminderRepository repository;
  late FakeBackgroundService background;
  late FakeGeofenceService geofence;
  late MonitoringCoordinator coordinator;

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 600));

  setUp(() {
    repository = FakeReminderRepository();
    background = FakeBackgroundService();
    geofence = FakeGeofenceService();
    if (getIt.isRegistered<GeofenceService>()) {
      getIt.unregister<GeofenceService>();
    }
    getIt.registerLazySingleton<GeofenceService>(() => geofence);
    coordinator = MonitoringCoordinatorImpl(
      FakeSettingsService(),
      background,
      repository,
    );
  });

  tearDown(() {
    getIt.unregister<GeofenceService>();
  });

  test('a reminder change leads to exactly one fence sync', () async {
    repository.emit([fixtures.reminder(1)]);
    await settle();

    expect(geofence.syncCalls, 1);
    expect(background.startCalls, 1);
  });

  test('an unchanged reminder set does not re-sync fences', () async {
    repository.emit([fixtures.reminder(1)]);
    await settle();
    repository.emit([fixtures.reminder(1)]);
    await settle();

    expect(geofence.syncCalls, 1);
  });

  test('a radius-only change re-syncs fences', () async {
    repository.emit([fixtures.reminder(1, radius: 200)]);
    await settle();
    repository.emit([fixtures.reminder(1, radius: 400)]);
    await settle();

    expect(geofence.syncCalls, 2);
    expect(geofence.lastSynced.single.radiusMeters, 400);
  });

  test('a forced resync re-registers fences even when the set is unchanged',
      () async {
    repository.emit([fixtures.reminder(1)]);
    await settle();
    expect(geofence.syncCalls, 1);

    await coordinator.evaluateMonitoringState(
      source: 'test',
      reason: 'cold_start',
      forceGeofenceResync: true,
    );

    expect(geofence.syncCalls, 2);
  });

  test('no eligible reminders clears fences and stops the monitor', () async {
    repository.emit([fixtures.reminder(1)]);
    await settle();
    background.running = true;

    await coordinator.evaluateMonitoringState(
      source: 'test',
      reason: 'last_reminder_completed',
    );
    repository.emit([fixtures.reminder(1, status: 'completed')]);
    await settle();

    expect(geofence.clearCalls, greaterThan(0));
    expect(background.stopCalls, greaterThan(0));
  });
}
