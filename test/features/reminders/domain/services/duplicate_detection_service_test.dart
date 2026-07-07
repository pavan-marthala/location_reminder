import 'package:flutter_test/flutter_test.dart';
import 'package:reminders/features/reminders/domain/entities/reminder_entity.dart';
import 'package:reminders/features/reminders/domain/services/duplicate_detection_service.dart';

void main() {
  late DuplicateDetectionService service;
  late List<ReminderEntity> mockReminders;

  setUp(() {
    service = DuplicateDetectionService();
    mockReminders = [
      ReminderEntity(
        id: 1,
        title: 'Home',
        latitude: 14.6997567,
        longitude: 78.7443233,
        radiusMeters: 200,
        alarmTone: 'daybreak',
        createdAt: DateTime.now(),
      ),
      ReminderEntity(
        id: 2,
        title: 'Office',
        latitude: 14.7001,
        longitude: 78.7445,
        radiusMeters: 100,
        alarmTone: 'daybreak',
        createdAt: DateTime.now(),
      ),
      ReminderEntity(
        id: 3,
        title: 'Far Away',
        latitude: 14.8000,
        longitude: 78.9000,
        radiusMeters: 200,
        alarmTone: 'daybreak',
        createdAt: DateTime.now(),
      ),
    ];
  });

  group('DuplicateDetectionService Tests', () {
    test('Should return empty if no reminders are close to the target coordinates', () {
      final duplicates = service.checkForDuplicates(
        latitude: 14.8500,
        longitude: 78.9500,
        allReminders: mockReminders,
      );

      expect(duplicates, isEmpty);
    });

    test('Should return duplicate reminders within the threshold', () {
      // Coordinate very close to "Home" (14.6997567, 78.7443233)
      final duplicates = service.checkForDuplicates(
        latitude: 14.6997500,
        longitude: 78.7443200,
        allReminders: mockReminders,
      );

      expect(duplicates, hasLength(1));
      expect(duplicates[0].reminder.title, equals('Home'));
      expect(duplicates[0].distanceMeters, lessThan(10.0));
    });

    test('Should sort multiple duplicates by distance ascending (nearest first)', () {
      // Coordinate close to both "Home" and "Office"
      final duplicates = service.checkForDuplicates(
        latitude: 14.6998,
        longitude: 78.74435,
        allReminders: mockReminders,
        thresholdMeters: 100.0,
      );

      expect(duplicates, hasLength(2));
      expect(duplicates[0].reminder.title, equals('Home'));
      expect(duplicates[1].reminder.title, equals('Office'));
      expect(duplicates[0].distanceMeters, lessThan(duplicates[1].distanceMeters));
    });

    test('Should exclude the reminder currently being edited', () {
      // Check near "Home", but exclude "Home" (id: 1)
      final duplicates = service.checkForDuplicates(
        latitude: 14.6997567,
        longitude: 78.7443233,
        allReminders: mockReminders,
        excludeId: 1,
      );

      expect(duplicates, isEmpty);
    });
  });
}
