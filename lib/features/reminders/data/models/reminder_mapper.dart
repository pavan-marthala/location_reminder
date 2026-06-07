import 'package:drift/drift.dart';
import 'package:reminders/core/database/app_database.dart';
import 'package:reminders/features/reminders/domain/entities/reminder_entity.dart';

class ReminderMapper {
  ReminderMapper._();

  static ReminderEntity fromData(ReminderData data) {
    return ReminderEntity(
      id: data.id,
      title: data.title,
      description: data.description,
      latitude: data.latitude,
      longitude: data.longitude,
      radiusMeters: data.radius,
      alarmTone: data.alarmTone,
      isEnabled: data.isEnabled,
      isTriggered: data.isTriggered,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }

  static RemindersCompanion toCompanion(ReminderEntity entity) {
    return RemindersCompanion(
      id: entity.id != null ? Value(entity.id!) : const Value.absent(),
      title: Value(entity.title),
      description: Value(entity.description),
      latitude: Value(entity.latitude),
      longitude: Value(entity.longitude),
      radius: Value(entity.radiusMeters),
      alarmTone: Value(entity.alarmTone),
      isEnabled: Value(entity.isEnabled),
      isTriggered: Value(entity.isTriggered),
      createdAt: Value(entity.createdAt),
      updatedAt: Value(entity.updatedAt),
    );
  }

  static RemindersCompanion toInsertCompanion(ReminderEntity entity) {
    return RemindersCompanion.insert(
      title: entity.title,
      description: Value(entity.description),
      latitude: entity.latitude,
      longitude: entity.longitude,
      radius: entity.radiusMeters,
      alarmTone: Value(entity.alarmTone),
      isEnabled: Value(entity.isEnabled),
      createdAt: entity.createdAt,
    );
  }
}
