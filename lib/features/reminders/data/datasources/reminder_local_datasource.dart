import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:reminders/core/database/app_database.dart';
import 'package:flutter/foundation.dart';

abstract class ReminderLocalDatasource {
  Future<List<ReminderData>> getAllReminders();
  Stream<List<ReminderData>> watchAllReminders();
  Stream<ReminderData?> watchReminderById(int id);
  Future<ReminderData?> getReminderById(int id);
  Future<int> createReminder(RemindersCompanion companion);
  Future<void> updateReminder(RemindersCompanion companion);
  Future<void> deleteReminder(int id);
  Future<void> toggleReminder(int id, bool isEnabled);
  Future<int> reactivateExpiredSnoozes();
}

@LazySingleton(as: ReminderLocalDatasource)
class ReminderLocalDatasourceImpl implements ReminderLocalDatasource {
  final AppDatabase _db;

  ReminderLocalDatasourceImpl(this._db);

  @override
  Future<List<ReminderData>> getAllReminders() {
    return (_db.select(_db.reminders)
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  @override
  Stream<List<ReminderData>> watchAllReminders() {
    return (_db.select(_db.reminders)
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  @override
  Stream<ReminderData?> watchReminderById(int id) {
    return (_db.select(_db.reminders)..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  }

  @override
  Future<ReminderData?> getReminderById(int id) {
    return (_db.select(_db.reminders)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> _logDiff(int id, RemindersCompanion companion, String action) async {
    final oldRecord = await getReminderById(id);
    if (oldRecord != null) {
      final changedFields = <String>[];
      final oldValues = <String>[];
      final newValues = <String>[];
      
      if (companion.title.present && companion.title.value != oldRecord.title) {
        changedFields.add('title');
        oldValues.add(oldRecord.title);
        newValues.add(companion.title.value);
      }
      if (companion.isEnabled.present && companion.isEnabled.value != oldRecord.isEnabled) {
        changedFields.add('isEnabled');
        oldValues.add(oldRecord.isEnabled.toString());
        newValues.add(companion.isEnabled.value.toString());
      }
      if (companion.isTriggered.present && companion.isTriggered.value != oldRecord.isTriggered) {
        changedFields.add('isTriggered');
        oldValues.add(oldRecord.isTriggered.toString());
        newValues.add(companion.isTriggered.value.toString());
      }
      if (companion.status.present && companion.status.value != oldRecord.status) {
        changedFields.add('status');
        oldValues.add(oldRecord.status);
        newValues.add(companion.status.value);
      }
      if (companion.snoozedUntil.present && companion.snoozedUntil.value != oldRecord.snoozedUntil) {
        changedFields.add('snoozedUntil');
        oldValues.add(oldRecord.snoozedUntil?.toIso8601String() ?? 'null');
        newValues.add(companion.snoozedUntil.value?.toIso8601String() ?? 'null');
      }

      debugPrint(
        '[DATABASE_UPDATE] ID=$id Action=$action\n'
        '  Time: ${DateTime.now().toIso8601String()}\n'
        '  Fields Changed: ${changedFields.join(', ')}\n'
        '  Old Values: ${oldValues.join(', ')}\n'
        '  New Values: ${newValues.join(', ')}'
      );
    }
  }

  @override
  Future<int> createReminder(RemindersCompanion companion) {
    debugPrint('[DATABASE_CREATE] Title=${companion.title.value} Time=${DateTime.now().toIso8601String()}');
    return _db.into(_db.reminders).insert(companion);
  }

  @override
  Future<void> updateReminder(RemindersCompanion companion) async {
    final id = companion.id.value;
    await _logDiff(id, companion, 'updateReminder');
    await (_db.update(_db.reminders)
          ..where((t) => t.id.equals(id)))
        .write(companion);
  }

  @override
  Future<void> deleteReminder(int id) async {
    debugPrint('[DATABASE_DELETE] ID=$id Time=${DateTime.now().toIso8601String()}');
    await (_db.delete(_db.reminders)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> toggleReminder(int id, bool isEnabled) async {
    final companion = RemindersCompanion(
      isEnabled: Value(isEnabled),
      updatedAt: Value(DateTime.now()),
    );
    await _logDiff(id, companion, 'toggleReminder');
    await (_db.update(_db.reminders)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  @override
  Future<int> reactivateExpiredSnoozes() async {
    final now = DateTime.now();
    final companion = RemindersCompanion(
      status: const Value('active'),
      isTriggered: const Value(false),
      snoozedUntil: const Value(null),
      updatedAt: Value(now),
    );

    final snoozedReminders = await (_db.select(_db.reminders)
      ..where((t) => t.status.equals('snoozed') & t.snoozedUntil.isSmallerOrEqualValue(now))).get();

    for (final r in snoozedReminders) {
      await _logDiff(r.id, companion, 'reactivateExpiredSnoozes');
    }

    final query = _db.update(_db.reminders)
      ..where((t) => t.status.equals('snoozed') & t.snoozedUntil.isSmallerOrEqualValue(now));
    
    final count = await query.write(companion);
    debugPrint('[DATABASE] Reactivated $count reminder(s) Time=${now.toIso8601String()}');
    return count;
  }
}
