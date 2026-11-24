import 'package:reminders/features/reminders/domain/entities/reminder_entity.dart';

/// Pure helpers for deciding which reminders need a geofence and for detecting
/// whether that set (or its geometry) has changed.
abstract final class GeofenceFingerprint {
  /// A reminder is monitorable when it has an id, is enabled, has not already
  /// triggered, and is in neither a snoozed nor a completed/disabled state.
  static bool isMonitorable(ReminderEntity reminder) {
    if (reminder.id == null || !reminder.isEnabled || reminder.isTriggered) {
      return false;
    }
    return reminder.status != 'snoozed' &&
        reminder.status != 'completed' &&
        reminder.status != 'disabled';
  }

  /// Stable signature of the monitorable reminders and their fence geometry.
  /// Independent of input order so unrelated database emissions do not churn
  /// the registered fences.
  static String compute(Iterable<ReminderEntity> reminders) {
    final parts = reminders.where(isMonitorable).map((reminder) {
      return '${reminder.id}'
          ':${reminder.latitude.toStringAsFixed(7)}'
          ':${reminder.longitude.toStringAsFixed(7)}'
          ':${reminder.radiusMeters.toStringAsFixed(2)}';
    }).toList()..sort();
    return parts.join('|');
  }

  /// Whether [lastSynced] still describes the current monitorable set.
  static bool matches(String? lastSynced, Iterable<ReminderEntity> reminders) {
    return lastSynced == compute(reminders);
  }
}
