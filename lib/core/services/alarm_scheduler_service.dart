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
  Future<void> scheduleSnooze(int reminderId, int minutes, {bool? forceExact});
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
  Future<void> scheduleSnooze(int reminderId, int minutes, {bool? forceExact}) async {
    final reminder = await _reminderRepository.getReminderById(reminderId);
    if (reminder == null) return;

    final now = DateTime.now();
    final snoozeTime = now.add(Duration(minutes: minutes));

    // Persist snooze state
    final updated = reminder.copyWith(
      status: 'snoozed',
      isTriggered: false,
      snoozedUntil: snoozeTime,
      updatedAt: now,
    );
    await _reminderRepository.updateReminder(updated);

    // Schedule notification relative to UTC time
    final scheduledDate = tz.TZDateTime.now(tz.UTC).add(Duration(minutes: minutes));

    debugPrint('[SNOOZE] Scheduling notification');
    debugPrint('[SNOOZE] Current Time: $now');
    debugPrint('[SNOOZE] Scheduled Time: ${now.add(Duration(minutes: minutes))} (UTC: $scheduledDate)');

    bool useExact = true;
    if (forceExact != null) {
      useExact = forceExact;
    } else if (Platform.isAndroid) {
      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      useExact = await androidPlugin?.canScheduleExactNotifications() ?? false;
    }

    final androidDetails = const AndroidNotificationDetails(
      'alarm_channel',
      'Alarms & Reminders',
      channelDescription: 'Channel for location-based reminders and alarm triggers',
      importance: Importance.max,
      priority: Priority.high,
      playSound: false, // Audio played by AlarmPage
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'dismiss',
          'Dismiss',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'snooze_5',
          'Snooze 5 min',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    final scheduleMode = useExact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle;

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
      debugPrint('[SNOOZE] Notification ID: $reminderId (Mode: ${scheduleMode.name})');
    } catch (e) {
      debugPrint('[SNOOZE] Scheduling failed');
      debugPrint('[SNOOZE] Exception: $e');
    }

    // Evaluate monitoring state (will stop location service if no other active monitoring reminders remain)
    await getIt<MonitoringCoordinator>().evaluateMonitoringState();
  }

  @override
  Future<void> cancelSnooze(int reminderId) async {
    await _localNotifications.cancel(id: reminderId);
  }
}
