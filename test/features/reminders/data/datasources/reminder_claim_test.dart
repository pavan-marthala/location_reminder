import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminders/core/database/app_database.dart';
import 'package:reminders/features/reminders/data/datasources/reminder_local_datasource.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase database;
  late ReminderLocalDatasourceImpl datasource;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    datasource = ReminderLocalDatasourceImpl(database);
  });

  tearDown(() => database.close());

  Future<int> insertReminder({String status = 'active'}) {
    return database.into(database.reminders).insert(
          RemindersCompanion.insert(
            title: 'Reminder',
            latitude: 17.38,
            longitude: 78.48,
            radius: 200,
            status: Value(status),
            createdAt: DateTime(2026),
          ),
        );
  }

  test('claimTrigger succeeds once for an eligible reminder', () async {
    final id = await insertReminder();

    expect(await datasource.claimTrigger(id, DateTime(2026, 11, 23)), 1);
    expect(await datasource.claimTrigger(id, DateTime(2026, 11, 23)), 0);

    final row = await datasource.getReminderById(id);
    expect(row!.isTriggered, isTrue);
    expect(row.status, 'triggered');
  });

  test('expired snoozes are reactivated for monitoring', () async {
    final id = await database.into(database.reminders).insert(
          RemindersCompanion.insert(
            title: 'Snoozed reminder',
            latitude: 17.38,
            longitude: 78.48,
            radius: 200,
            status: const Value('snoozed'),
            snoozedUntil: Value(DateTime(2020)),
            createdAt: DateTime(2026),
          ),
        );

    expect(await datasource.reactivateExpiredSnoozes(), 1);
    final row = await datasource.getReminderById(id);
    expect(row!.status, 'active');
    expect(row.isTriggered, isFalse);
    expect(row.snoozedUntil, isNull);
  });

  test('claimTrigger ignores snoozed and completed reminders', () async {
    final snoozed = await insertReminder(status: 'snoozed');
    final completed = await insertReminder(status: 'completed');

    expect(await datasource.claimTrigger(snoozed, DateTime(2026)), 0);
    expect(await datasource.claimTrigger(completed, DateTime(2026)), 0);
  });
}
