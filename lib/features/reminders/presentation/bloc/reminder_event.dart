import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:reminders/features/reminders/domain/entities/reminder_entity.dart';

part 'reminder_event.freezed.dart';

@freezed
class ReminderEvent with _$ReminderEvent {
  const factory ReminderEvent.loadReminders() = LoadReminders;
  const factory ReminderEvent.createReminder({
    required ReminderEntity reminder,
  }) = CreateReminder;
  const factory ReminderEvent.updateReminder({
    required ReminderEntity reminder,
  }) = UpdateReminder;
  const factory ReminderEvent.deleteReminder({required int id}) =
      DeleteReminder;
  const factory ReminderEvent.toggleReminder({
    required int id,
    required bool isEnabled,
  }) = ToggleReminder;
  const factory ReminderEvent.remindersUpdated({
    required List<ReminderEntity> reminders,
  }) = RemindersUpdated;
  const factory ReminderEvent.remindersError({
    required String message,
  }) = RemindersError;
}
