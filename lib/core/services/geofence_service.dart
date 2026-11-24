import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:reminders/features/reminders/domain/entities/reminder_entity.dart';

class GeofenceStatus {
  final int syncedCount;
  final int expectedCount;
  final String? lastSyncAt;
  final int? pendingId;
  final int? pendingAgeSeconds;
  final String? lastEventAt;
  final String? lastEvent;
  final String? lastError;
  final bool hasBackgroundLocation;

  const GeofenceStatus({
    required this.syncedCount,
    this.expectedCount = 0,
    this.lastSyncAt,
    this.pendingId,
    this.pendingAgeSeconds,
    required this.lastEventAt,
    required this.lastEvent,
    required this.lastError,
    required this.hasBackgroundLocation,
  });

  factory GeofenceStatus.fromMap(Map<dynamic, dynamic>? map) {
    final rawCount = map?['syncedCount'];
    final count = rawCount is num
        ? rawCount.toInt()
        : int.tryParse('${rawCount ?? ''}') ?? 0;
    final rawBg = map?['hasBackgroundLocation'];
    final hasBg = rawBg is bool
        ? rawBg
        : '$rawBg'.toLowerCase() == 'true';
    final rawExpected = map?['expectedCount'];
    final rawPendingId = map?['pendingId'];
    final rawPendingAge = map?['pendingAgeSeconds'];
    return GeofenceStatus(
      syncedCount: count,
      expectedCount: rawExpected is num
          ? rawExpected.toInt()
          : int.tryParse('${rawExpected ?? ''}') ?? count,
      lastSyncAt: map?['lastSyncAt']?.toString(),
      pendingId: rawPendingId is num
          ? rawPendingId.toInt()
          : int.tryParse('${rawPendingId ?? ''}'),
      pendingAgeSeconds: rawPendingAge is num
          ? rawPendingAge.toInt()
          : int.tryParse('${rawPendingAge ?? ''}'),
      lastEventAt: map?['lastEventAt']?.toString(),
      lastEvent: map?['lastEvent']?.toString(),
      lastError: map?['lastError']?.toString(),
      hasBackgroundLocation: hasBg,
    );
  }
}

/// Registers reminders with the Google Play Services Geofencing API so that
/// arrivals are detected by the system even if this app's process was killed.
///
/// This is a no-op on platforms other than Android.
abstract class GeofenceService {
  /// Returns true only when the native side confirmed registration, so the
  /// coordinator can remember the last successfully synced fingerprint.
  Future<bool> syncGeofences(List<ReminderEntity> reminders);
  Future<void> clearAll();
  Future<GeofenceStatus> getStatus();
}

class GeofenceServiceImpl implements GeofenceService {
  static const MethodChannel _channel =
      MethodChannel('com.example.reminders/geofence');

  /// The Geofencing API allows at most 100 geofences per app. Keeping the cap
  /// here lets the native side register a single fence per reminder when the
  /// list is very large.
  static const int maxMonitoredReminders = 100;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<bool> syncGeofences(List<ReminderEntity> reminders) async {
    if (!_isAndroid) return false;

    final candidates = reminders
        .where(
          (r) =>
              r.id != null &&
              r.isEnabled &&
              !r.isTriggered &&
              r.status != 'snoozed' &&
              r.status != 'completed' &&
              r.status != 'disabled',
        )
        .toList();

    if (candidates.length > maxMonitoredReminders) {
      debugPrint(
        '[GEOFENCE] ${candidates.length} active reminders; only the first '
        '$maxMonitoredReminders will be monitored by Play Services.',
      );
    }
    final active = candidates.take(maxMonitoredReminders).toList();

    try {
      await _channel.invokeMethod<int>('sync', {
        'geofences': active
            .map(
              (r) => {
                'id': r.id,
                'title': r.title,
                'latitude': r.latitude,
                'longitude': r.longitude,
                'radiusMeters': r.radiusMeters,
              },
            )
            .toList(),
      });
      debugPrint('[GEOFENCE] Synced ${active.length} reminder geofences');
      return true;
    } catch (e) {
      debugPrint('[GEOFENCE] Failed to sync geofences: $e');
      return false;
    }
  }

  @override
  Future<void> clearAll() async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod<bool>('clear');
      debugPrint('[GEOFENCE] Cleared all reminder geofences');
    } catch (e) {
      debugPrint('[GEOFENCE] Failed to clear geofences: $e');
    }
  }

  @override
  Future<GeofenceStatus> getStatus() async {
    if (!_isAndroid) {
      return const GeofenceStatus(
        syncedCount: 0,
        lastEventAt: null,
        lastEvent: null,
        lastError: null,
        hasBackgroundLocation: false,
      );
    }
    try {
      final result =
          await _channel.invokeMapMethod<String, dynamic>('status');
      return GeofenceStatus.fromMap(result);
    } catch (e) {
      debugPrint('[GEOFENCE] Failed to read status: $e');
      return const GeofenceStatus(
        syncedCount: 0,
        lastEventAt: null,
        lastEvent: null,
        lastError: null,
        hasBackgroundLocation: false,
      );
    }
  }
}
