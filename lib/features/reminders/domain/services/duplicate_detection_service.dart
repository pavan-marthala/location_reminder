import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';
import 'package:reminders/core/utils/app_constants.dart';
import 'package:reminders/features/reminders/domain/entities/reminder_entity.dart';

class DuplicateReminder {
  final ReminderEntity reminder;
  final double distanceMeters;

  const DuplicateReminder({
    required this.reminder,
    required this.distanceMeters,
  });
}

@lazySingleton
class DuplicateDetectionService {
  List<DuplicateReminder> checkForDuplicates({
    required double latitude,
    required double longitude,
    required List<ReminderEntity> allReminders,
    int? excludeId,
    double thresholdMeters = AppConstants.duplicateThresholdMeters,
  }) {
    final List<DuplicateReminder> duplicates = [];

    for (final reminder in allReminders) {
      if (excludeId != null && reminder.id == excludeId) {
        continue;
      }

      final distance = Geolocator.distanceBetween(
        latitude,
        longitude,
        reminder.latitude,
        reminder.longitude,
      );

      final isDuplicate = distance <= thresholdMeters;
      print('''
Reminder: <${reminder.title}>
Latitude: ${reminder.latitude}
Longitude: ${reminder.longitude}
Calculated distance: ${distance.toStringAsFixed(1)} m
Threshold: $thresholdMeters m
Duplicate: ${isDuplicate ? 'YES' : 'NO'}
''');

      if (isDuplicate) {
        duplicates.add(DuplicateReminder(
          reminder: reminder,
          distanceMeters: distance,
        ));
      }
    }

    duplicates.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return duplicates;
  }
}
