import 'package:injectable/injectable.dart';
import 'package:reminders/features/reminders/domain/repositories/reminder_repository.dart';

@injectable
class DeleteReminderUseCase {
  final ReminderRepository _repository;

  DeleteReminderUseCase(this._repository);

  Future<void> call(int id) {
    return _repository.deleteReminder(id);
  }
}
