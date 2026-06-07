import 'package:injectable/injectable.dart';
import 'package:reminders/features/reminders/domain/entities/reminder_entity.dart';
import 'package:reminders/features/reminders/domain/repositories/reminder_repository.dart';

@injectable
class UpdateReminderUseCase {
  final ReminderRepository _repository;

  UpdateReminderUseCase(this._repository);

  Future<void> call(ReminderEntity reminder) {
    return _repository.updateReminder(reminder);
  }
}
