import 'dart:async';
import 'dart:developer';
import 'dart:ui';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'package:reminders/features/reminders/data/datasources/reminder_local_datasource.dart';

abstract class BackgroundService {
  Future<void> init();
  Future<void> startService();
  Future<void> stopService();
  Future<bool> isRunning();
  Future<void> refreshMonitoring({int? cycleId, String? source, String? reason});
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
        autoStartOnBoot: true,
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
  }

  @override
  Future<bool> isRunning() {
    return FlutterBackgroundService().isRunning();
  }

  @override
  Future<void> refreshMonitoring({int? cycleId, String? source, String? reason}) async {
    try {
      final timeStr = DateTime.now().toIso8601String();
      debugPrint(
        '[TRACE]\n'
        'refreshMonitoring()\n'
        'id=${cycleId ?? -1}\n'
        'source=${source ?? 'unknown'}\n'
        'reason=${reason ?? 'unknown'}\n'
        'time=$timeStr'
      );
      final service = FlutterBackgroundService();
      service.invoke('refreshMonitoring', {
        'cycleId': cycleId,
        'source': source,
        'reason': reason,
      });
    } catch (e, stackTrace) {
      debugPrint("[MAIN BACKGROUND SERVICE]\nERROR invoking refreshMonitoring\n$e\n$stackTrace");
    }
  }
}

class SnoozeTimerManager {
  final Map<int, Timer> _activeTimers = {};
  final Future<void> Function() _onTimerExpired;

  SnoozeTimerManager({required Future<void> Function() onTimerExpired})
      : _onTimerExpired = onTimerExpired;

  void syncTimers(List<ReminderData> enabledReminders) {
    final now = DateTime.now();
    final activeIds = <int>{};

    for (final r in enabledReminders) {
      if (r.status == 'snoozed' && r.snoozedUntil != null) {
        if (r.snoozedUntil!.isAfter(now)) {
          activeIds.add(r.id);
          if (!_activeTimers.containsKey(r.id)) {
            final duration = r.snoozedUntil!.difference(now);
            debugPrint('[SNOOZE_MANAGER] Scheduling timer for reminder ${r.id} in $duration');
            _activeTimers[r.id] = Timer(duration, () async {
              debugPrint('[SNOOZE_MANAGER] Timer expired for reminder ${r.id}');
              _activeTimers.remove(r.id);
              await _onTimerExpired();
            });
          }
        }
      }
    }

    // Cancel any timers that are no longer in 'snoozed' status in the database
    final removedIds = _activeTimers.keys.where((id) => !activeIds.contains(id)).toList();
    for (final id in removedIds) {
      debugPrint('[SNOOZE_MANAGER] Cancelling timer for reminder $id');
      _activeTimers[id]?.cancel();
      _activeTimers.remove(id);
    }
  }

  void cancelAll() {
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  final isolateStartDateTime = DateTime.now();
  final isolateStartTime = isolateStartDateTime.toIso8601String();
  final instanceId = 'iso_${isolateStartDateTime.millisecondsSinceEpoch}';

  debugPrint("======================================");
  debugPrint("[SERVICE] Background Isolate Started at $isolateStartTime (Instance: $instanceId)");
  DartPluginRegistrant.ensureInitialized();

  // Initialize SQLite Drift DB directly at start of isolate
  final dbFolder = await getApplicationDocumentsDirectory();
  final file = File(p.join(dbFolder.path, 'app_database.db'));
  final database = AppDatabase(NativeDatabase(file));
  debugPrint("[BACKGROUND] Database opened directly from SQLite");

  geo.Position? lastKnownPosition;
  late Future<void> Function() handleRefreshRef;
  final snoozeTimerManager = SnoozeTimerManager(onTimerExpired: () async {
    await handleRefreshRef();
  });

  // Helper to log event to console
  Future<void> logEvent(String tag, String event, {String? details}) async {
    final now = DateTime.now();
    final timeStr = now.toIso8601String();
    debugPrint('$tag $event ${details != null ? '| Details: $details' : ''} at $timeStr');
  }

  // Helper to update state in console and main isolate
  void updateState(String state, {String? details}) async {
    final nowStr = DateTime.now().toIso8601String();
    log(
      ' STATE_CHANGE: $state | Details: $details ',
      name: 'GEOPROCESSOR',
      time: DateTime.now(),
    );
    await logEvent('[BACKGROUND_ISOLATE]', 'STATE_CHANGE', details: '$state ($details)');

    final data = {
      'status': 'state_change',
      'readinessState': state,
      'details': details,
      'time': nowStr,
    };
    debugPrint("[BACKGROUND] Sending update to Main Isolate");
    debugPrint(data.toString());
    service.invoke('update', data);

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
  await logEvent('[ANDROID_SERVICE]', 'SERVICE_CREATED', details: 'Isolate instance: $instanceId');
  await logEvent('[ANDROID_SERVICE]', 'SERVICE_STARTED', details: 'Isolate instance: $instanceId');

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
  debugPrint("[BACKGROUND] Notifications initialized");

  // Check persisted reminders directly from SQLite to determine if monitoring work exists
  final datasource = ReminderLocalDatasourceImpl(database);
  await datasource.reactivateExpiredSnoozes();

  final allEnabled = await (database.select(
    database.reminders,
  )..where((t) => t.isEnabled.equals(true))).get();

  final now = DateTime.now();
  final activeWorkReminders = allEnabled.where((r) {
    if (r.isTriggered) return false;
    if (r.status == 'disabled' || r.status == 'completed') return false;
    if (r.status == 'snoozed') {
      return r.snoozedUntil != null && r.snoozedUntil!.isAfter(now);
    }
    return true;
  }).toList();

  final activeMonitoringCount = activeWorkReminders.where((r) => r.status != 'snoozed').length;
  final pendingSnoozesCount = activeWorkReminders.where((r) => r.status == 'snoozed').length;

  await logEvent('[BACKGROUND_ISOLATE]', 'REMINDERS_CHECK',
      details: 'Total enabled: ${allEnabled.length}, Active: $activeMonitoringCount, Snoozed: $pendingSnoozesCount');

  // Self-termination guard: If no monitoring work exists (no active reminders and no pending snoozes), stop service immediately
  if (activeWorkReminders.isEmpty) {
    await logEvent('[ANDROID_SERVICE]', 'SELF_TERMINATING', details: 'No monitoring work found in SQLite');
    updateState('MonitoringActive', details: 'No active reminders');
    await database.close();
    service.stopSelf();
    return;
  }

  await logEvent('[BACKGROUND_ISOLATE]', 'RESUMING_MONITORING', details: 'Active work count: ${activeWorkReminders.length}');

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
  bool isRestartingLocationStream = false;

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) async {
    await logEvent('[ANDROID_SERVICE]', 'SERVICE_STOP_REQUESTED', details: 'stopService event received');
    await positionSubscription?.cancel();
    positionSubscription = null;
    try {
      await audioPlayer.stop();
      await audioPlayer.dispose();
    } catch (_) {}
    await database.close();
    service.stopSelf();
  });

  service.on('stopAlarm').listen((event) async {
    try {
      await audioPlayer.stop();
    } catch (_) {}
  });

  // Verify Location Services & Permissions
  final serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    await logEvent('[GEOLOCATOR]', 'LOCATION_SERVICES_DISABLED');
    updateState('Error', details: 'Location services are disabled');
    await database.close();
    service.stopSelf();
    return;
  }

  final permission = await geo.Geolocator.checkPermission();
  if (permission == geo.LocationPermission.denied ||
      permission == geo.LocationPermission.deniedForever) {
    await logEvent('[GEOLOCATOR]', 'LOCATION_PERMISSION_DENIED', details: permission.toString());
    updateState('WaitingForPermissions');
    await database.close();
    service.stopSelf();
    return;
  }

  // Step 2: LoadingReminders & REMINDERS_LOADED
  updateState('LoadingReminders');

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
    lastKnownPosition = firstPosition;
    await logEvent('[GEOLOCATOR]', 'FIRST_LOCATION_RECEIVED',
        details: 'Lat: ${firstPosition.latitude}, Lng: ${firstPosition.longitude}');
  } catch (e) {
    await logEvent('[GEOLOCATOR]', 'FIRST_LOCATION_FAILED', details: e.toString());
    firstPosition = await geo.Geolocator.getLastKnownPosition();
    if (firstPosition != null) {
      lastKnownPosition = firstPosition;
    }
  }

  // Common position evaluation function
  Future<void> evaluatePosition(
    geo.Position position, {
    required bool isInitial,
  }) async {
    if (isInitial) {
      await logEvent('[GEOPROCESSOR]', 'FIRST_GEOFENCE_EVALUATION');
    } else {
      await logEvent('[LOCATION_NATIVE]', 'LOCATION_UPDATE',
          details: 'Lat: ${position.latitude}, Lng: ${position.longitude}');
    }

    try {
      final reactivatedCount = await datasource.reactivateExpiredSnoozes();
      if (reactivatedCount > 0) {
        await logEvent('[SNOOZE]', 'REACTIVATED_EXPIRED_SNOOZES', details: 'Count: $reactivatedCount');
      }

      final currentEnabled = await (database.select(
        database.reminders,
      )..where((t) => t.isEnabled.equals(true))).get();

      final currentActive = currentEnabled.where((r) {
        if (r.isTriggered) return false;
        if (r.status == 'disabled' || r.status == 'completed' || r.status == 'snoozed') return false;
        return true;
      }).toList();

      if (currentActive.isEmpty) {
        updateState('MonitoringActive', details: 'No active reminders');
        final data = {
          'time': DateTime.now().toIso8601String(),
          'status': 'check',
          'readinessState': 'MonitoringActive',
          'activeCount': 0,
        };
        service.invoke('update', data);
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

        if (nearestDistance == null || distance < nearestDistance) {
          nearestDistance = distance;
          nearestReminderTitle = reminder.title;
        }

        if (distance <= reminder.radius) {
          await logEvent('[GEOPROCESSOR]', 'REMINDER_TRIGGERED', details: 'ID: ${reminder.id}, Title: ${reminder.title}');
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

          final prefs = await SharedPreferences.getInstance();
          final vibrate = prefs.getBool('vibration_enabled') ?? true;

          final androidDetails = AndroidNotificationDetails(
            'alarm_channel',
            'Alarms & Reminders',
            channelDescription:
                'Channel for location-based reminders and alarm triggers',
            importance: Importance.max,
            priority: Priority.high,
            playSound: false, // UI Alarm Screen owns audio playback
            enableVibration: vibrate,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
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
            payload: reminder.id.toString(),
          );

          final data = {
            'time': DateTime.now().toIso8601String(),
            'status': 'triggered',
            'reminderId': reminder.id,
            'reminderTitle': reminder.title,
            'readinessState': 'MonitoringActive',
          };
          service.invoke('update', data);
        }
      }

      final activeCount = currentActive.length;
      String infoText = 'Monitoring $activeCount active reminders';
      if (nearestReminderTitle != null && nearestDistance != null) {
        infoText =
            '$nearestReminderTitle: ${nearestDistance.toStringAsFixed(0)}m away';
      }

      updateState('MonitoringActive', details: infoText);

      final data = {
        'time': DateTime.now().toIso8601String(),
        'status': 'running',
        'latitude': position.latitude,
        'longitude': position.longitude,
        'nearestReminder': nearestReminderTitle,
        'nearestDistance': nearestDistance,
        'activeCount': activeCount,
        'readinessState': 'MonitoringActive',
      };
      service.invoke('update', data);
    } catch (e) {
      await logEvent('[GEOPROCESSOR]', 'EVALUATE_ERROR', details: e.toString());
      final data = {
        'time': DateTime.now().toIso8601String(),
        'status': 'error',
        'error': e.toString(),
        'readinessState': 'Error',
      };
      service.invoke('update', data);
    }
  }

  bool isRefreshing = false;
  bool hasPendingRefresh = false;

  Future<void> handleRefresh() async {
    if (isRefreshing) {
      hasPendingRefresh = true;
      return;
    }
    isRefreshing = true;

    do {
      hasPendingRefresh = false;
      try {
        geo.Position? position = lastKnownPosition;
        if (position == null) {
          try {
            position = await geo.Geolocator.getCurrentPosition(
              locationSettings: const geo.LocationSettings(
                accuracy: geo.LocationAccuracy.high,
                timeLimit: Duration(seconds: 8),
              ),
            );
            lastKnownPosition = position;
          } catch (e) {
            position = await geo.Geolocator.getLastKnownPosition();
            if (position != null) {
              lastKnownPosition = position;
            }
          }
        }

        if (position != null) {
          await evaluatePosition(position, isInitial: false);
        }
      } catch (e) {
        await logEvent('[BACKGROUND_ISOLATE]', 'REFRESH_ERROR', details: e.toString());
      }
    } while (hasPendingRefresh);

    isRefreshing = false;
  }

  handleRefreshRef = handleRefresh;

  service.on('refreshMonitoring').listen((event) async {
    final currentEnabled = await (database.select(database.reminders)
      ..where((t) => t.isEnabled.equals(true))).get();
    snoozeTimerManager.syncTimers(currentEnabled);
    await handleRefresh();
  });

  // Initial geofence evaluation
  if (firstPosition != null) {
    snoozeTimerManager.syncTimers(allEnabled);
    await evaluatePosition(firstPosition, isInitial: true);
  }

  // Subscribe to position stream with restart guard and lifecycle watchdog
  const locationSettings = geo.LocationSettings(
    accuracy: geo.LocationAccuracy.high,
    distanceFilter: 10,
  );

  void startLocationSubscription() {
    if (isRestartingLocationStream) return;
    isRestartingLocationStream = true;

    logEvent('[LOCATION_NATIVE]', 'LOCATION_SUBSCRIBING');
    positionSubscription?.cancel();
    positionSubscription = geo.Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (geo.Position position) async {
        await evaluatePosition(position, isInitial: false);
      },
      onError: (e) {
        logEvent('[LOCATION_NATIVE]', 'LOCATION_STREAM_ERROR', details: e.toString());
        service.invoke('update', {
          'time': DateTime.now().toIso8601String(),
          'status': 'error',
          'error': e.toString(),
        });
        isRestartingLocationStream = false;
        startLocationSubscription();
      },
      onDone: () {
        logEvent('[LOCATION_NATIVE]', 'LOCATION_STREAM_DONE');
        isRestartingLocationStream = false;
        startLocationSubscription();
      },
    );
    isRestartingLocationStream = false;
    logEvent('[LOCATION_NATIVE]', 'LOCATION_SUBSCRIBED_SUCCESS');
    updateState('MonitoringActive', details: 'Location stream active');
  }

  startLocationSubscription();
}

@pragma('vm:entry-point')
bool onIosBackground(ServiceInstance service) {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}
