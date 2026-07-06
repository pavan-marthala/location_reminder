import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:go_router/go_router.dart';
import 'package:reminders/core/routes/app_routes.dart';
import 'package:reminders/main.dart';

abstract class NotificationService {
  Future<void> init();
  Future<bool> requestPermissions();
  Future<void> showTestNotification({
    required String title,
    required String body,
  });
  Future<void> showFullScreenTestNotification();
  Future<bool> areNotificationsEnabled();
}

@LazySingleton(as: NotificationService)
class NotificationServiceImpl implements NotificationService {
  final FlutterLocalNotificationsPlugin _localNotifications;

  NotificationServiceImpl(this._localNotifications);

  static const String _channelId = 'alarm_channel';
  static const String _channelName = 'Alarms & Reminders';
  static const String _channelDescription =
      'Channel for location-based reminders and alarm triggers';

  @override
  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationTapped,
    );

    // Create high importance Android channel
    final androidChannel = const AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  @override
  Future<bool> requestPermissions() async {
    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImplementation != null) {
      final granted = await androidImplementation
          .requestNotificationsPermission();
      return granted ?? false;
    }
    return false;
  }

  @override
  Future<void> showTestNotification({
    required String title,
    required String body,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: 999,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  @override
  Future<void> showFullScreenTestNotification() async {
    final androidDetails = const AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: 9999,
      title: 'Test Full Screen Alarm',
      body: 'This is a proof of concept notification.',
      notificationDetails: details,
      payload: '0',
    );
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImplementation != null) {
      final enabled = await androidImplementation.areNotificationsEnabled();
      return enabled ?? false;
    }

    final darwinImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (darwinImplementation != null) {
      final settings = await darwinImplementation.checkPermissions();
      return settings?.isEnabled == true;
    }

    return true;
  }
}

/// Handles all notification responses — body taps AND action button taps.
void _onNotificationResponse(NotificationResponse response) {
  debugPrint('[ANDROID] Wake-up callback received');
  debugPrint('[MONITORING] Wake received');
  debugPrint(
    'Notification response: actionId=${response.actionId}, payload=${response.payload}',
  );

  final actionId = response.actionId;
  final payload = response.payload;
  final reminderId = payload != null ? int.tryParse(payload) : null;

  if (reminderId != null) {
    debugPrint('[SNOOZE] Notification callback received');
    debugPrint('[SNOOZE] Reminder ID: $reminderId');
  }

  // Default: body tap → navigate to AlarmPage
  if (reminderId != null) {
    final context = rootNavigatorKey.currentContext;
    if (context != null) {
      try {
        final router = GoRouter.of(context);
        final routeState = router.routerDelegate.currentConfiguration;
        final isAlreadyAlarm = routeState.routes.any(
          (route) => route is GoRoute && route.path == AppRoutes.alarm,
        );
        if (isAlreadyAlarm) {
          debugPrint("[NOTIFICATION] Already on AlarmPage, skipping push");
        } else {
          context.push(
            AppRoutes.alarm,
            extra: {
              'id': reminderId,
              'title': reminderId == 0 ? 'Test Alarm Sound' : 'Reminder',
            },
          );
        }
      } catch (e) {
        debugPrint('Error routing to alarm page: $e');
      }
    }
  }
}

@pragma('vm:entry-point')
void _onBackgroundNotificationTapped(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[ANDROID] Wake-up callback received');
  debugPrint('[MONITORING] Wake received');
  debugPrint(
    'Background notification tapped: actionId=${response.actionId}, payload=${response.payload}',
  );

  final payload = response.payload;
  final reminderId = payload != null ? int.tryParse(payload) : null;

  if (reminderId != null) {
    debugPrint('[SNOOZE] Notification callback received');
    debugPrint('[SNOOZE] Reminder ID: $reminderId');
  }
}
