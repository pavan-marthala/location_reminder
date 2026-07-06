import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:reminders/core/database/app_database.dart';
import 'package:reminders/features/reminders/data/datasources/reminder_local_datasource.dart';
import 'package:reminders/features/reminders/data/repositories/reminder_repository_impl.dart';
import 'package:reminders/features/reminders/domain/entities/reminder_entity.dart';
import 'package:drift/drift.dart' hide isNull;

void main() {
  test('Simulate geofence triggers and check database states', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final datasource = ReminderLocalDatasourceImpl(db);
    final repo = ReminderRepositoryImpl(datasource);

    print('=== STEP 1: App starts. Database is empty ===');
    var all = await repo.getAllReminders();
    print('Total reminders: ${all.length}');

    print('\n=== STEP 2: Creating FIRST reminder ===');
    final r1 = ReminderEntity(
      id: 1,
      title: 'First Reminder',
      latitude: 1.0,
      longitude: 1.0,
      radiusMeters: 100.0,
      alarmTone: 'daybreak',
      createdAt: DateTime.now(),
    );
    await repo.createReminder(r1);

    all = await repo.getAllReminders();
    print('Total reminders: ${all.length}');
    print('First reminder details:');
    for (var r in all) {
      print('  ID: ${r.id}, Title: ${r.title}, isEnabled: ${r.isEnabled}, isTriggered: ${r.isTriggered}, status: ${r.status}');
    }

    // Simulate MonitoringCoordinator check
    bool evaluateMonitoring(List<ReminderEntity> list) {
      final explicitlyEnabled = true;
      final hasActiveReminder = list.any((r) => r.isEnabled && !r.isTriggered && r.status != 'snoozed');
      final shouldBeRunning = explicitlyEnabled && hasActiveReminder;
      print('  [Coordinator] hasActiveReminder: $hasActiveReminder, shouldBeRunning: $shouldBeRunning');
      return shouldBeRunning;
    }
    evaluateMonitoring(all);

    print('\n=== STEP 3: First reminder triggers ===');
    // In evaluatePosition:
    final triggerCompanion = RemindersCompanion(
      id: const Value(1),
      isTriggered: const Value(true),
      status: const Value('triggered'),
      triggeredAt: Value(DateTime.now()),
      lastTriggeredAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );
    await datasource.updateReminder(triggerCompanion);

    all = await repo.getAllReminders();
    print('First reminder after trigger:');
    for (var r in all) {
      print('  ID: ${r.id}, Title: ${r.title}, isEnabled: ${r.isEnabled}, isTriggered: ${r.isTriggered}, status: ${r.status}');
    }
    evaluateMonitoring(all);

    print('\n=== STEP 4: First reminder is completed/dismissed ===');
    final dismissUpdated = all.first.copyWith(
      status: 'completed',
      isEnabled: false,
      isTriggered: false,
      completedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await repo.updateReminder(dismissUpdated);

    all = await repo.getAllReminders();
    print('First reminder after completion:');
    for (var r in all) {
      print('  ID: ${r.id}, Title: ${r.title}, isEnabled: ${r.isEnabled}, isTriggered: ${r.isTriggered}, status: ${r.status}');
    }
    evaluateMonitoring(all);

    print('\n=== STEP 5: Creating SECOND reminder ===');
    final r2 = ReminderEntity(
      id: 2,
      title: 'Second Reminder',
      latitude: 2.0,
      longitude: 2.0,
      radiusMeters: 100.0,
      alarmTone: 'daybreak',
      createdAt: DateTime.now(),
    );
    await repo.createReminder(r2);

    all = await repo.getAllReminders();
    print('All reminders after second reminder created:');
    for (var r in all) {
      print('  ID: ${r.id}, Title: ${r.title}, isEnabled: ${r.isEnabled}, isTriggered: ${r.isTriggered}, status: ${r.status}');
    }
    evaluateMonitoring(all);

    await db.close();
  });

  test('Simulate 10-second snooze and expiration flow', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final datasource = ReminderLocalDatasourceImpl(db);
    final repo = ReminderRepositoryImpl(datasource);

    print('\n=== SNOOZE TEST: Creating and triggering reminder ===');
    final r = ReminderEntity(
      id: 39,
      title: 'Yenni',
      latitude: 1.0,
      longitude: 1.0,
      radiusMeters: 100.0,
      alarmTone: 'daybreak',
      createdAt: DateTime.now(),
    );
    final generatedId = await repo.createReminder(r);

    // Trigger it
    final triggerCompanion = RemindersCompanion(
      id: Value(generatedId),
      isTriggered: const Value(true),
      status: const Value('triggered'),
      triggeredAt: Value(DateTime.now()),
      lastTriggeredAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );
    await datasource.updateReminder(triggerCompanion);

    // Snooze it for 10 seconds (represented as duration in test)
    print('\n=== SNOOZE TEST: Snoozing reminder for 10 seconds ===');
    final now = DateTime.now();
    final snoozeCompanion = RemindersCompanion(
      id: Value(generatedId),
      status: const Value('snoozed'),
      isTriggered: const Value(false),
      snoozedUntil: Value(now.add(const Duration(seconds: 10))),
      updatedAt: Value(now),
    );
    await datasource.updateReminder(snoozeCompanion);

    // Evaluate coordinator logic
    print('\n=== SNOOZE TEST: Evaluating monitoring state (Should remain active due to pending snooze) ===');
    final reminders = await repo.getAllReminders();
    final hasActiveReminder = reminders.any((r) => r.isEnabled && !r.isTriggered && r.status != 'snoozed');
    final hasPendingSnooze = reminders.any((r) => r.isEnabled && r.status == 'snoozed' && r.snoozedUntil != null && r.snoozedUntil!.isAfter(DateTime.now()));
    final shouldBeRunning = hasActiveReminder || hasPendingSnooze;
    print('  hasActiveReminder=$hasActiveReminder');
    print('  hasPendingSnooze=$hasPendingSnooze');
    print('  shouldBeRunning=$shouldBeRunning');

    // Simulate waiting 11 seconds
    print('\n=== SNOOZE TEST: Simulating snooze expiration (waiting 11 seconds) ===');
    await Future.delayed(const Duration(seconds: 11));

    // Reactivate
    print('\n=== SNOOZE TEST: Reactivating expired snoozes ===');
    await datasource.reactivateExpiredSnoozes();

    await db.close();
  });
}
