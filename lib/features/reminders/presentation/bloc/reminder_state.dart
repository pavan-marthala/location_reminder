import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:reminders/features/reminders/domain/entities/reminder_entity.dart';
import 'package:reminders/features/reminders/domain/entities/reminder_enums.dart';

part 'reminder_state.freezed.dart';

@freezed
class ReminderState with _$ReminderState {
  const factory ReminderState.initial() = ReminderInitial;
  const factory ReminderState.loading() = ReminderLoading;
  const factory ReminderState.loaded({
    required List<ReminderEntity> reminders,
    required List<ReminderEntity> filteredReminders,
    @Default('') String searchQuery,
    @Default(SortOption.recentlyCreated) SortOption sortBy,
  }) = ReminderLoaded;
  const factory ReminderState.empty() = ReminderEmpty;
  const factory ReminderState.error({required String message}) = ReminderError;
}
