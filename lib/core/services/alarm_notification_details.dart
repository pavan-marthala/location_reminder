import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Shared notification configuration for every alarm surface.
///
/// The sound is played by Android from a bundled raw resource, so an alarm can
/// still be heard when the Flutter process (and its audio player) is dead.
abstract final class AlarmNotificationDetails {
  static const String channelId = 'alarm_channel';
  static const String channelName = 'Alarms & Reminders';
  static const String channelDescription =
      'Channel for location-based reminders and alarm triggers';

  static AndroidNotificationDetails android({required bool vibrate}) {
    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('daybreak'),
      enableVibration: vibrate,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );
  }

  static NotificationDetails platform({required bool vibrate}) {
    return NotificationDetails(
      android: android(vibrate: vibrate),
      iOS: const DarwinNotificationDetails(),
    );
  }
}
