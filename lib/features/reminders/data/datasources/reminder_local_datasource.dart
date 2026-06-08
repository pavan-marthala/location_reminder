import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:reminders/core/database/app_database.dart';

abstract class ReminderLocalDatasource {
  Future<List<ReminderData>> getAllReminders();
  Stream<List<ReminderData>> watchAllReminders();
  Future<ReminderData?> getReminderById(int id);
  Future<int> createReminder(RemindersCompanion companion);
  Future<void> updateReminder(RemindersCompanion companion);
  Future<void> deleteReminder(int id);
  Future<void> toggleReminder(int id, bool isEnabled);
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
  Future<ReminderData?> getReminderById(int id) {
    return (_db.select(_db.reminders)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  @override
  Future<int> createReminder(RemindersCompanion companion) {
    return _db.into(_db.reminders).insert(companion);
  }

  @override
  Future<void> updateReminder(RemindersCompanion companion) async {
    await (_db.update(_db.reminders)
          ..where((t) => t.id.equals(companion.id.value)))
        .write(companion);
  }

  @override
  Future<void> deleteReminder(int id) async {
    await (_db.delete(_db.reminders)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> toggleReminder(int id, bool isEnabled) async {
    await (_db.update(_db.reminders)..where((t) => t.id.equals(id)))
        .write(RemindersCompanion(
      isEnabled: Value(isEnabled),
      updatedAt: Value(DateTime.now()),
    ));
  }
}
