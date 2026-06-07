import 'package:injectable/injectable.dart';
import 'package:reminders/features/reminders/domain/entities/reminder_entity.dart';
import 'package:reminders/features/reminders/domain/repositories/reminder_repository.dart';

@injectable
class CreateReminderUseCase {
  final ReminderRepository _repository;

  CreateReminderUseCase(this._repository);

  Future<int> call(ReminderEntity reminder) {
    return _repository.createReminder(reminder);
  }
}
