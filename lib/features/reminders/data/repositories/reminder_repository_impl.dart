import 'package:injectable/injectable.dart';
import 'package:reminders/features/reminders/data/datasources/reminder_local_datasource.dart';
import 'package:reminders/features/reminders/data/models/reminder_mapper.dart';
import 'package:reminders/features/reminders/domain/entities/reminder_entity.dart';
import 'package:reminders/features/reminders/domain/repositories/reminder_repository.dart';

@LazySingleton(as: ReminderRepository)
class ReminderRepositoryImpl implements ReminderRepository {
  final ReminderLocalDatasource _datasource;

  ReminderRepositoryImpl(this._datasource);

  @override
  Future<List<ReminderEntity>> getAllReminders() async {
    final dataList = await _datasource.getAllReminders();
    return dataList.map(ReminderMapper.fromData).toList();
  }

  @override
  Future<ReminderEntity?> getReminderById(int id) async {
    final data = await _datasource.getReminderById(id);
    return data != null ? ReminderMapper.fromData(data) : null;
  }

  @override
  Future<int> createReminder(ReminderEntity reminder) {
    final companion = ReminderMapper.toInsertCompanion(reminder);
    return _datasource.createReminder(companion);
  }

  @override
  Future<void> updateReminder(ReminderEntity reminder) {
    final companion = ReminderMapper.toCompanion(reminder);
    return _datasource.updateReminder(companion);
  }

  @override
  Future<void> deleteReminder(int id) {
    return _datasource.deleteReminder(id);
  }

  @override
  Future<void> toggleReminder(int id, bool isEnabled) {
    return _datasource.toggleReminder(id, isEnabled);
  }
}
