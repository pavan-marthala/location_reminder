import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';

abstract class BackgroundService {
  Future<void> init();
  Future<void> startService();
  Future<void> stopService();
  Future<bool> isRunning();
  Stream<Map<String, dynamic>?> get backgroundUpdates;
}

@LazySingleton(as: BackgroundService)
class BackgroundServiceImpl implements BackgroundService {
  final FlutterLocalNotificationsPlugin _localNotifications;
  final _backgroundUpdatesController =
      StreamController<Map<String, dynamic>?>.broadcast();

  BackgroundServiceImpl(this._localNotifications);

  @override
  Stream<Map<String, dynamic>?> get backgroundUpdates =>
      _backgroundUpdatesController.stream;

  /// Dedicated channel for the persistent foreground service notification.
  /// This is separate from the alarm_channel used for user-facing notifications.
  static const String _foregroundChannelId = 'foreground_service_channel';
  static const String _foregroundChannelName = 'Background Location Monitor';
  static const String _foregroundChannelDesc =
      'Maintains the location reminder background monitoring process';

  @override
  Future<void> init() async {
    // Create the foreground notification channel on Android first
    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImplementation != null) {
      const channel = AndroidNotificationChannel(
        _foregroundChannelId,
        _foregroundChannelName,
        description: _foregroundChannelDesc,
        importance: Importance.low,
      );
      await androidImplementation.createNotificationChannel(channel);
    }

    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _foregroundChannelId,
        initialNotificationTitle: 'Location Monitor Active',
        initialNotificationContent: 'Monitoring reminders in background',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    // Listen to updates from the background isolate
    service.on('update').listen((event) {
      _backgroundUpdatesController.add(event);
    });
  }

  @override
  Future<void> startService() async {
    final service = FlutterBackgroundService();
    await service.startService();
  }

  @override
  Future<void> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }

  @override
  Future<bool> isRunning() {
    return FlutterBackgroundService().isRunning();
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Periodic task in background isolate — runs every 60 seconds.
  // Only updates the existing persistent foreground notification content;
  // does NOT create new user-visible notifications.
  Timer.periodic(const Duration(seconds: 60), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        final now = DateTime.now();
        final timeStr = DateFormat.jm().format(now);
        service.setForegroundNotificationInfo(
          title: 'Location Monitor Active',
          content: 'Last check: $timeStr',
        );
      }
    }

    // Invoke update event to notify main isolate
    service.invoke('update', {
      'time': DateTime.now().toIso8601String(),
      'status': 'running',
    });
  });
}

@pragma('vm:entry-point')
bool onIosBackground(ServiceInstance service) {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}
