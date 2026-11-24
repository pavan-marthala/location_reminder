import 'package:flutter_test/flutter_test.dart';
import 'package:reminders/core/services/geofence_fingerprint.dart';
import 'package:reminders/features/reminders/domain/entities/reminder_entity.dart';

ReminderEntity reminder(
  int id, {
  double latitude = 17.38,
  double longitude = 78.48,
  double radius = 200,
  String status = 'active',
  bool isEnabled = true,
  bool isTriggered = false,
}) {
  return ReminderEntity(
    id: id,
    title: 'Reminder $id',
    latitude: latitude,
    longitude: longitude,
    radiusMeters: radius,
    alarmTone: 'assets/audio/Daybreak.mp3',
    isEnabled: isEnabled,
    isTriggered: isTriggered,
    status: status,
    createdAt: DateTime(2026),
  );
}

void main() {
  group('GeofenceFingerprint', () {
    test('adding a reminder changes the fingerprint', () {
      final before = GeofenceFingerprint.compute([reminder(1)]);
      final after = GeofenceFingerprint.compute([reminder(1), reminder(2)]);
      expect(after, isNot(before));
    });

    test('removing a reminder changes the fingerprint', () {
      final before = GeofenceFingerprint.compute([reminder(1), reminder(2)]);
      final after = GeofenceFingerprint.compute([reminder(2)]);
      expect(after, isNot(before));
    });

    test('input order does not change the fingerprint', () {
      final first = GeofenceFingerprint.compute([reminder(1), reminder(2)]);
      final second = GeofenceFingerprint.compute([reminder(2), reminder(1)]);
      expect(second, first);
    });

    test('a radius-only change changes the fingerprint', () {
      final before = GeofenceFingerprint.compute([reminder(1, radius: 200)]);
      final after = GeofenceFingerprint.compute([reminder(1, radius: 250)]);
      expect(after, isNot(before));
    });

    test('non-monitorable reminders are excluded', () {
      final active = GeofenceFingerprint.compute([reminder(1)]);
      expect(
        GeofenceFingerprint.compute([
          reminder(1),
          reminder(2, isEnabled: false),
          reminder(3, isTriggered: true),
          reminder(4, status: 'snoozed'),
          reminder(5, status: 'completed'),
          reminder(6, status: 'disabled'),
        ]),
        active,
      );
    });

    test('matches reports drift correctly', () {
      final reminders = [reminder(1)];
      final synced = GeofenceFingerprint.compute(reminders);
      expect(GeofenceFingerprint.matches(synced, reminders), isTrue);
      expect(
        GeofenceFingerprint.matches(synced, [reminder(1, radius: 300)]),
        isFalse,
      );
    });
  });
}
