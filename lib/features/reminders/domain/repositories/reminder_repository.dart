import 'package:reminders/features/reminders/domain/entities/reminder_entity.dart';

abstract class ReminderRepository {
  Future<List<ReminderEntity>> getAllReminders();
  Stream<List<ReminderEntity>> watchAllReminders();
  Future<ReminderEntity?> getReminderById(int id);
  Future<int> createReminder(ReminderEntity reminder);
  Future<void> updateReminder(ReminderEntity reminder);
  Future<void> deleteReminder(int id);
  Future<void> toggleReminder(int id, bool isEnabled);
}
