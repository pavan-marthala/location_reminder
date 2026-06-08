import 'dart:async';
import 'dart:developer';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:audioplayers/audioplayers.dart';
import 'package:reminders/core/database/app_database.dart';

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
        initialNotificationTitle: 'Location Monitor Starting...',
        initialNotificationContent: 'Initializing service components...',
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
    _backgroundUpdatesController.add({
      'status': 'starting',
      'readinessState': 'Starting',
      'time': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
    _backgroundUpdatesController.add({
      'status': 'stopped',
      'readinessState': 'Stopped',
      'activeCount': 0,
      'time': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<bool> isRunning() {
    return FlutterBackgroundService().isRunning();
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // Helper to notify main isolate and update foreground notification info
  void updateState(String state, {String? details}) async {
    final nowStr = DateTime.now().toIso8601String();
    log(
      ' STATE_CHANGE: $state | Details: $details ',
      name: 'GEOPROCESSOR',
      time: DateTime.now(),
    );
    service.invoke('update', {
      'status': 'state_change',
      'readinessState': state,
      'details': details,
      'time': nowStr,
    });

    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        String title = 'Location Monitor';
        String content = '';
        switch (state) {
          case 'Starting':
            title = 'Location Monitor Starting...';
            content = 'Initializing service components...';
            break;
          case 'WaitingForPermissions':
            title = 'Location Monitor Paused';
            content = 'Please grant location permissions';
            break;
          case 'LoadingReminders':
            title = 'Location Monitor Starting...';
            content = 'Loading reminders from database...';
            break;
          case 'WaitingForLocation':
            title = 'Location Monitor Starting...';
            content = 'Waiting for initial GPS coordinates...';
            break;
          case 'MonitoringActive':
            title = 'Location Monitor Active';
            content = details ?? 'Monitoring reminders';
            break;
          case 'Error':
            title = 'Location Monitor Error';
            content = details ?? 'An error occurred';
            break;
        }
        service.setForegroundNotificationInfo(title: title, content: content);
      }
    }
  }

  // Step 1: SERVICE_STARTED
  updateState('Starting');
  debugPrint(
    '[GEOPROCESSOR] SERVICE_STARTED at ${DateTime.now().toIso8601String()}',
  );

  // Initialize notifications inside background isolate
  final localNotifications = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  await localNotifications.initialize(settings: initSettings);

  // Initialize SQLite Drift DB directly
  final dbFolder = await getApplicationDocumentsDirectory();
  final file = File(p.join(dbFolder.path, 'app_database.db'));
  final database = AppDatabase(NativeDatabase(file));

  // Initialize audio player
  final audioPlayer = AudioPlayer();
  await audioPlayer.setAudioContext(
    AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: true,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.alarm,
        audioFocus: AndroidAudioFocus.gainTransient,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: const {},
      ),
    ),
  );

  StreamSubscription<geo.Position>? positionSubscription;

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) async {
    await positionSubscription?.cancel();
    await audioPlayer.stop();
    await audioPlayer.dispose();
    await database.close();
    service.stopSelf();
  });

  service.on('stopAlarm').listen((event) async {
    await audioPlayer.stop();
  });

  // Verify Location Services & Permissions
  final serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    updateState('Error', details: 'Location services are disabled');
    return;
  }

  final permission = await geo.Geolocator.checkPermission();
  if (permission == geo.LocationPermission.denied ||
      permission == geo.LocationPermission.deniedForever) {
    updateState('WaitingForPermissions');
    return;
  }

  // Step 2: LoadingReminders & REMINDERS_LOADED
  updateState('LoadingReminders');
  final enabledReminders = await (database.select(
    database.reminders,
  )..where((t) => t.isEnabled.equals(true))).get();
  debugPrint(
    '[GEOPROCESSOR] REMINDERS_LOADED: Loaded ${enabledReminders.length} enabled reminders at ${DateTime.now().toIso8601String()}',
  );

  // Step 3: WaitingForLocation & FIRST_LOCATION_RECEIVED
  updateState('WaitingForLocation');
  geo.Position? firstPosition;
  try {
    firstPosition = await geo.Geolocator.getCurrentPosition(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        timeLimit: Duration(seconds: 8),
      ),
    );
    debugPrint(
      '[GEOPROCESSOR] FIRST_LOCATION_RECEIVED: Lat: ${firstPosition.latitude}, Lng: ${firstPosition.longitude} at ${DateTime.now().toIso8601String()}',
    );
  } catch (e) {
    debugPrint(
      '[GEOPROCESSOR] getCurrentPosition timed out or failed: $e. Falling back to last known position.',
    );
    firstPosition = await geo.Geolocator.getLastKnownPosition();
  }

  // Common position evaluation function
  Future<void> evaluatePosition(
    geo.Position position, {
    required bool isInitial,
  }) async {
    final timestamp = DateTime.now().toIso8601String();
    if (isInitial) {
      debugPrint(
        '[GEOPROCESSOR] FIRST_GEOFENCE_EVALUATION starting at $timestamp',
      );
    } else {
      debugPrint('[GEOPROCESSOR] Location update received at $timestamp');
      debugPrint(
        '[GEOPROCESSOR] Coordinates: Lat: ${position.latitude}, Lng: ${position.longitude}',
      );
    }

    try {
      final currentEnabled = await (database.select(
        database.reminders,
      )..where((t) => t.isEnabled.equals(true))).get();

      final evalTime = DateTime.now();
      final currentActive = currentEnabled.where((r) {
        if (r.isTriggered) return false;
        if (r.status == 'disabled' || r.status == 'completed') return false;
        if (r.status == 'snoozed' &&
            r.snoozedUntil != null &&
            r.snoozedUntil!.isAfter(evalTime)) {
          return false;
        }
        return true;
      }).toList();

      if (currentActive.isEmpty) {
        debugPrint(
          '[GEOPROCESSOR] No active (enabled, unsnoozed & untriggered) reminders found.',
        );
        updateState('MonitoringActive', details: 'No active reminders');
        service.invoke('update', {
          'time': DateTime.now().toIso8601String(),
          'status': 'check',
          'readinessState': 'MonitoringActive',
          'activeCount': 0,
        });
        return;
      }

      double? nearestDistance;
      String? nearestReminderTitle;

      for (final reminder in currentActive) {
        final distance = geo.Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          reminder.latitude,
          reminder.longitude,
        );

        debugPrint(
          '[GEOPROCESSOR] Evaluating Reminder: "${reminder.title}" | Distance: ${distance.toStringAsFixed(2)}m (Radius: ${reminder.radius}m)',
        );

        if (nearestDistance == null || distance < nearestDistance) {
          nearestDistance = distance;
          nearestReminderTitle = reminder.title;
        }

        if (distance <= reminder.radius) {
          // Trigger entry!
          await (database.update(
            database.reminders,
          )..where((t) => t.id.equals(reminder.id))).write(
            RemindersCompanion(
              isTriggered: const Value(true),
              status: const Value('triggered'),
              triggeredAt: Value(DateTime.now()),
              lastTriggeredAt: Value(DateTime.now()),
              updatedAt: Value(DateTime.now()),
            ),
          );

          const androidDetails = AndroidNotificationDetails(
            'alarm_channel',
            'Alarms & Reminders',
            channelDescription:
                'Channel for location-based reminders and alarm triggers',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          );
          const iosDetails = DarwinNotificationDetails();
          final details = NotificationDetails(
            android: androidDetails,
            iOS: iosDetails,
          );

          await localNotifications.show(
            id: reminder.id,
            title: 'Reminder Triggered!',
            body: 'You entered the geofence for: ${reminder.title}',
            notificationDetails: details,
          );

          final tonePath = reminder.alarmTone;
          final cleanTonePath = tonePath.startsWith('assets/')
              ? tonePath.substring(7)
              : tonePath;
          await audioPlayer.setReleaseMode(ReleaseMode.loop);
          await audioPlayer.play(AssetSource(cleanTonePath));

          service.invoke('update', {
            'time': DateTime.now().toIso8601String(),
            'status': 'triggered',
            'reminderId': reminder.id,
            'reminderTitle': reminder.title,
            'readinessState': 'MonitoringActive',
          });
        }
      }

      final activeCount = currentActive.length;
      String infoText = 'Monitoring $activeCount active reminders';
      if (nearestReminderTitle != null && nearestDistance != null) {
        infoText =
            '$nearestReminderTitle: ${nearestDistance.toStringAsFixed(0)}m away';
      }

      updateState('MonitoringActive', details: infoText);

      service.invoke('update', {
        'time': DateTime.now().toIso8601String(),
        'status': 'running',
        'latitude': position.latitude,
        'longitude': position.longitude,
        'nearestReminder': nearestReminderTitle,
        'nearestDistance': nearestDistance,
        'activeCount': activeCount,
        'readinessState': 'MonitoringActive',
      });
    } catch (e) {
      service.invoke('update', {
        'time': DateTime.now().toIso8601String(),
        'status': 'error',
        'error': e.toString(),
        'readinessState': 'Error',
      });
    }
  }

  // Initial geofence evaluation (Step 4: FIRST_GEOFENCE_EVALUATION)
  if (firstPosition != null) {
    await evaluatePosition(firstPosition, isInitial: true);
  }

  // Subscribe to position stream (Step 5: POSITION_STREAM_SUBSCRIBED)
  const locationSettings = geo.LocationSettings(
    accuracy: geo.LocationAccuracy.high,
    distanceFilter: 10,
  );

  positionSubscription =
      geo.Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (geo.Position position) async {
          await evaluatePosition(position, isInitial: false);
        },
        onError: (e) {
          service.invoke('update', {
            'time': DateTime.now().toIso8601String(),
            'status': 'error',
            'error': e.toString(),
          });
        },
      );

  debugPrint(
    '[GEOPROCESSOR] POSITION_STREAM_SUBSCRIBED at ${DateTime.now().toIso8601String()}',
  );
}

@pragma('vm:entry-point')
bool onIosBackground(ServiceInstance service) {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}
