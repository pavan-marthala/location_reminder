import 'package:injectable/injectable.dart';
import 'package:reminders/features/reminders/domain/entities/reminder_entity.dart';
import 'package:reminders/features/reminders/domain/repositories/reminder_repository.dart';

@injectable
class GetReminderByIdUseCase {
  final ReminderRepository _repository;

  GetReminderByIdUseCase(this._repository);

  Future<ReminderEntity?> call(int id) {
    return _repository.getReminderById(id);
  }
}
