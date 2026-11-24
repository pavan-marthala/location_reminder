import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminders/core/database/app_database.dart';
import 'package:reminders/core/services/pending_trigger_service.dart';
import 'package:reminders/features/reminders/data/datasources/reminder_local_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final now = DateTime(2026, 11, 23, 12);

  Future<(ReminderLocalDatasourceImpl, PendingTriggerService, int)> arrange()
      async {
    SharedPreferences.setMockInitialValues({
      PendingTriggerService.keyId: 1,
      PendingTriggerService.keyAt: now.toIso8601String(),
    });
    final db = AppDatabase(NativeDatabase.memory());
    final datasource = ReminderLocalDatasourceImpl(db);
    final id = await db.into(db.reminders).insert(
          RemindersCompanion.insert(
            title: 'Reminder',
            latitude: 17.38,
            longitude: 78.48,
            radius: 200,
            createdAt: DateTime(2026),
          ),
        );
    // The fixture's id is generated as 1; reflect it in the native envelope.
    SharedPreferences.setMockInitialValues({
      PendingTriggerService.keyId: id,
      PendingTriggerService.keyAt: now.toIso8601String(),
    });
    final pending = PendingTriggerService(await SharedPreferences.getInstance());
    return (datasource, pending, id);
  }

  test('system claim then live evaluation produces one alarm', () async {
    final (datasource, pending, id) = await arrange();
    final envelope = await pending.readFresh(now: now);
    expect(envelope, isNotNull);

    await pending.clear();
    final systemClaim = await datasource.claimTrigger(id, now);
    final liveClaim = await datasource.claimTrigger(id, now);

    expect(systemClaim, 1);
    expect(liveClaim, 0);
    expect(await pending.readFresh(now: now), isNull);
  });

  test('a deleted reminder cannot be claimed', () async {
    final (datasource, _, id) = await arrange();
    await datasource.deleteReminder(id);

    expect(await datasource.claimTrigger(id, now), 0);
  });

  test('live claim clears the envelope so no later system alarm fires',
      () async {
    final (datasource, pending, id) = await arrange();

    final liveClaim = await datasource.claimTrigger(id, now);
    await pending.clearId(id);

    expect(liveClaim, 1);
    expect(await pending.readFresh(now: now), isNull);
    expect(await datasource.claimTrigger(id, now), 0);
  });
}
