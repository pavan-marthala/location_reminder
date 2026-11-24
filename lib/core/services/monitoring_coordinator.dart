import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:reminders/core/di/injection.dart';
import 'package:reminders/core/services/background_service.dart';
import 'package:reminders/core/services/geofence_fingerprint.dart';
import 'package:reminders/core/services/geofence_service.dart';
import 'package:reminders/core/services/settings_service.dart';
import 'package:reminders/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:reminders/features/reminders/domain/entities/reminder_entity.dart';

int _monitoringCycleCounter = 0;

abstract class MonitoringCoordinator {
  Future<void> evaluateMonitoringState({
    String source = 'unknown',
    String reason = 'unknown',
    bool forceGeofenceResync = false,
  });
  Future<void> setMonitoringEnabled(bool enabled);
  bool isMonitoringEnabled();
}

@LazySingleton(as: MonitoringCoordinator)
class MonitoringCoordinatorImpl implements MonitoringCoordinator {
  static const Duration _reminderDebounce = Duration(milliseconds: 300);
  static const int _maxConsecutiveEvaluations = 5;

  final SettingsService _settingsService;
  final BackgroundService _backgroundService;
  final ReminderRepository _reminderRepository;

  Timer? _reminderDebounceTimer;
  bool _isEvaluating = false;
  bool _pendingEvaluation = false;
  String? _lastSyncedFingerprint;

  MonitoringCoordinatorImpl(
    this._settingsService,
    this._backgroundService,
    this._reminderRepository,
  ) {
    // Triggered events from the isolate still require an immediate service
    // lifecycle decision (the isolate may need to be stopped).
    _backgroundService.backgroundUpdates.listen((event) {
      if (event != null &&
          (event['status'] == 'triggered' || event['action'] == 'triggered')) {
        evaluateMonitoringState(
          source: 'backgroundUpdatesListener',
          reason: 'status_triggered',
        );
      }
    });

    // Any persisted reminder change (create, update, delete, toggle, trigger,
    // snooze expiry) flows through this stream. This is the single place that
    // decides whether fences and the foreground service need to change.
    _reminderRepository.watchAllReminders().listen(
      (_) {
        _reminderDebounceTimer?.cancel();
        _reminderDebounceTimer = Timer(_reminderDebounce, () {
          evaluateMonitoringState(
            source: 'reminderStream',
            reason: 'reminders_changed',
          );
        });
      },
      onError: (Object error) {
        debugPrint('[COORDINATOR] Reminder watch failed: $error');
      },
    );
  }

  @override
  Future<void> evaluateMonitoringState({
    String source = 'unknown',
    String reason = 'unknown',
    bool forceGeofenceResync = false,
  }) async {
    if (_isEvaluating) {
      _pendingEvaluation = true;
      return;
    }

    _isEvaluating = true;
    var iterations = 0;
    try {
      do {
        _pendingEvaluation = false;
        await _evaluateOnce(
          source: source,
          reason: reason,
          forceGeofenceResync: forceGeofenceResync,
        );
        iterations++;
      } while (_pendingEvaluation && iterations < _maxConsecutiveEvaluations);
    } finally {
      _isEvaluating = false;
    }
  }

  Future<void> _evaluateOnce({
    required String source,
    required String reason,
    required bool forceGeofenceResync,
  }) async {
    final cycleId = ++_monitoringCycleCounter;
    final timeStr = DateTime.now().toIso8601String();
    debugPrint(
      '[TRACE]\n'
      'evaluateMonitoringState()\n'
      'id=$cycleId\n'
      'source=$source\n'
      'reason=$reason\n'
      'time=$timeStr'
    );

    await _reactivateExpiredSnoozes();

    final explicitlyEnabled = _settingsService.isMonitoringEnabled();
    final reminders = await _reminderRepository.getAllReminders();
    debugPrint('[COORDINATOR] Total reminders: ${reminders.length}');
    _logReminders(reminders);

    final shouldBeRunning = _calculateMonitoringState(
      reminders,
      explicitlyEnabled,
    );

    await _syncGeofences(
      reminders,
      explicitlyEnabled,
      force: forceGeofenceResync,
    );

    final isRunning = await _backgroundService.isRunning();
    await _applyServiceLifecycle(
      shouldBeRunning: shouldBeRunning,
      isRunning: isRunning,
      cycleId: cycleId,
      source: source,
      reason: reason,
    );

    debugPrint('[COORDINATOR] Evaluation finished id=$cycleId');
  }

  Future<void> _reactivateExpiredSnoozes() async {
    final reactivatedCount =
        await _reminderRepository.reactivateExpiredSnoozes();
    if (reactivatedCount > 0) {
      debugPrint('[SNOOZE] Reactivated $reactivatedCount expired snoozed reminders.');
    }
  }

  Future<void> _syncGeofences(
    List<ReminderEntity> reminders,
    bool explicitlyEnabled, {
    bool force = false,
  }) async {
    try {
      final geofenceService = getIt<GeofenceService>();
      if (!explicitlyEnabled) {
        await geofenceService.clearAll();
        _lastSyncedFingerprint = null;
        return;
      }

      final active =
          reminders.where(GeofenceFingerprint.isMonitorable).toList();
      final fingerprint = GeofenceFingerprint.compute(active);

      if (!force && fingerprint == _lastSyncedFingerprint) {
        debugPrint('[COORDINATOR] Geofence fingerprint unchanged, skipping sync');
        return;
      }

      if (active.isEmpty) {
        await geofenceService.clearAll();
        _lastSyncedFingerprint = '';
        return;
      }

      final synced = await geofenceService.syncGeofences(active);
      if (synced) {
        _lastSyncedFingerprint = fingerprint;
      } else {
        // Leave the cached fingerprint empty so the next evaluation retries.
        _lastSyncedFingerprint = null;
      }
    } catch (e) {
      // Geofences are a reliability improvement, never a reason to stop the
      // foreground monitor.
      debugPrint('[COORDINATOR] Geofence sync failed: $e');
      _lastSyncedFingerprint = null;
    }
  }

  void _logReminders(List<ReminderEntity> reminders) {
    for (final r in reminders) {
      debugPrint(
        '[COORDINATOR] ID=${r.id} Title=${r.title} '
        'Enabled=${r.isEnabled} Triggered=${r.isTriggered} Status=${r.status}',
      );
    }
  }

  bool _calculateMonitoringState(
    List<ReminderEntity> reminders,
    bool explicitlyEnabled,
  ) {
    final hasActiveReminder =
        reminders.any(GeofenceFingerprint.isMonitorable);
    final hasPendingSnooze = reminders.any(
      (r) =>
          r.isEnabled &&
          r.status == 'snoozed' &&
          r.snoozedUntil != null &&
          r.snoozedUntil!.isAfter(DateTime.now()),
    );

    final shouldBeRunning =
        explicitlyEnabled && (hasActiveReminder || hasPendingSnooze);
    debugPrint('[COORDINATOR] explicitlyEnabled=$explicitlyEnabled');
    debugPrint('[COORDINATOR] hasActiveReminder=$hasActiveReminder');
    debugPrint('[COORDINATOR] hasPendingSnooze=$hasPendingSnooze');
    debugPrint('[COORDINATOR] shouldBeRunning=$shouldBeRunning');
    return shouldBeRunning;
  }

  Future<void> _applyServiceLifecycle({
    required bool shouldBeRunning,
    required bool isRunning,
    required int cycleId,
    required String source,
    required String reason,
  }) async {
    if (shouldBeRunning) {
      if (!isRunning) {
        debugPrint('[COORDINATOR] Calling startService()');
        await _backgroundService.startService();
      } else {
        await _backgroundService.refreshMonitoring(
          cycleId: cycleId,
          source: source,
          reason: reason,
        );
      }
    } else if (isRunning) {
      debugPrint('[COORDINATOR] Calling stopService()');
      await _backgroundService.stopService();
    }
  }

  @override
  Future<void> setMonitoringEnabled(bool enabled) async {
    await _settingsService.saveMonitoringEnabled(enabled);
    await evaluateMonitoringState(
      source: 'setMonitoringEnabled',
      reason: enabled ? 'enabled' : 'disabled',
      forceGeofenceResync: true,
    );
  }

  @override
  bool isMonitoringEnabled() {
    return _settingsService.isMonitoringEnabled();
  }
}
