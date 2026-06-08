import 'package:freezed_annotation/freezed_annotation.dart';

part 'reminder_entity.freezed.dart';

@freezed
class ReminderEntity with _$ReminderEntity {
  const factory ReminderEntity({
    int? id,
    required String title,
    String? description,
    required double latitude,
    required double longitude,
    required double radiusMeters,
    required String alarmTone,
    @Default(true) bool isEnabled,
    @Default(false) bool isTriggered,
    @Default('active') String status,
    DateTime? triggeredAt,
    DateTime? lastTriggeredAt,
    DateTime? snoozedUntil,
    String? locationName,
    String? locationAddress,
    DateTime? completedAt,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _ReminderEntity;
}
