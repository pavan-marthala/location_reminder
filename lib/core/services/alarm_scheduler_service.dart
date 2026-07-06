// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:reminders/core/di/injection.dart';
import 'package:reminders/core/services/monitoring_coordinator.dart';
import 'package:reminders/features/reminders/domain/repositories/reminder_repository.dart';

abstract class AlarmSchedulerService {
  Future<void> scheduleSnooze(
    int reminderId,
    Duration duration, {
    bool? forceExact,
  });
  Future<void> cancelSnooze(int reminderId);
}

class AlarmSchedulerServiceImpl implements AlarmSchedulerService {
  final FlutterLocalNotificationsPlugin _localNotifications;
  final ReminderRepository _reminderRepository;

  AlarmSchedulerServiceImpl(
    this._localNotifications,
    this._reminderRepository,
  ) {
    tz.initializeTimeZones();
  }

  @override
  Future<void> scheduleSnooze(
    int reminderId,
    Duration duration, {
    bool? forceExact,
  }) async {
    final reminder = await _reminderRepository.getReminderById(reminderId);
    if (reminder == null) return;

    final now = DateTime.now();

    // Schedule notification relative to UTC time
    final scheduledDate = tz.TZDateTime.now(tz.UTC).add(duration);
    final wakeUpTime = now.add(duration);

    bool useExact = true;
    if (forceExact != null) {
      useExact = forceExact;
    } else if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      useExact = await androidPlugin?.canScheduleExactNotifications() ?? false;
    }

    final scheduleMode = useExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    debugPrint('[SNOOZE] Scheduled for $wakeUpTime');
    debugPrint('[SNOOZE] Android mechanism: ${scheduleMode.name}');
    debugPrint('[SNOOZE] Alarm ID (Request Code): $reminderId');

    final androidDetails = const AndroidNotificationDetails(
      'alarm_channel',
      'Alarms & Reminders',
      channelDescription:
          'Channel for location-based reminders and alarm triggers',
      importance: Importance.max,
      priority: Priority.high,
      playSound: false, // Audio played by AlarmPage
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    try {
      await _localNotifications.zonedSchedule(
        id: reminderId,
        title: 'Reminder Triggered (Snoozed)!',
        body: 'You are near: ${reminder.title}',
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: scheduleMode,
        payload: reminderId.toString(),
      );
      debugPrint('[SNOOZE] Notification scheduled successfully');
      debugPrint(
        '[SNOOZE] Notification ID: $reminderId (Mode: ${scheduleMode.name})',
      );
    } catch (e) {
      debugPrint('[SNOOZE] Scheduling failed');
      debugPrint('[SNOOZE] Exception: $e');
    }

    // Evaluate monitoring state (will stop location service if no other active monitoring reminders remain)
    await getIt<MonitoringCoordinator>().evaluateMonitoringState(
      source: 'AlarmSchedulerService',
      reason: 'snooze_scheduled',
    );
  }

  @override
  Future<void> cancelSnooze(int reminderId) async {
    await _localNotifications.cancel(id: reminderId);
  }
}
