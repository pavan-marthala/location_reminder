import 'package:injectable/injectable.dart';
import 'package:reminders/features/reminders/domain/entities/reminder_entity.dart';
import 'package:reminders/features/reminders/domain/repositories/reminder_repository.dart';

@injectable
class WatchAllRemindersUseCase {
  final ReminderRepository _repository;

  WatchAllRemindersUseCase(this._repository);

  Stream<List<ReminderEntity>> call() {
    return _repository.watchAllReminders();
  }
}
