import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:injectable/injectable.dart';

abstract class BackgroundService {
  Future<void> init();
  Future<void> startService();
  Future<void> stopService();
  Future<bool> isRunning();
  Stream<Map<String, dynamic>?> get backgroundUpdates;
}

@LazySingleton(as: BackgroundService)
class BackgroundServiceImpl implements BackgroundService {
  final _backgroundUpdatesController = StreamController<Map<String, dynamic>?>.broadcast();

  @override
  Stream<Map<String, dynamic>?> get backgroundUpdates =>
      _backgroundUpdatesController.stream;

  @override
  Future<void> init() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'alarm_channel',
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

  // Periodic task in background isolate
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: 'Location Monitor Active',
          content: 'Active check: ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}',
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
