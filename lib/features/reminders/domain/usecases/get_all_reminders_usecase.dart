import 'package:injectable/injectable.dart';
import 'package:reminders/features/reminders/domain/entities/reminder_entity.dart';
import 'package:reminders/features/reminders/domain/repositories/reminder_repository.dart';

@injectable
class GetAllRemindersUseCase {
  final ReminderRepository _repository;

  GetAllRemindersUseCase(this._repository);

  Future<List<ReminderEntity>> call() {
    return _repository.getAllReminders();
  }
}
