import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:reminders/core/services/background_service.dart';
import 'package:reminders/core/services/settings_service.dart';
import 'package:reminders/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:reminders/features/reminders/domain/entities/reminder_entity.dart';

int _monitoringCycleCounter = 0;

abstract class MonitoringCoordinator {
  Future<void> evaluateMonitoringState({String source = 'unknown', String reason = 'unknown'});
  Future<void> setMonitoringEnabled(bool enabled);
  bool isMonitoringEnabled();
}

@LazySingleton(as: MonitoringCoordinator)
class MonitoringCoordinatorImpl implements MonitoringCoordinator {
  final SettingsService _settingsService;
  final BackgroundService _backgroundService;
  final ReminderRepository _reminderRepository;

  MonitoringCoordinatorImpl(
    this._settingsService,
    this._backgroundService,
    this._reminderRepository,
  ) {
    // Listen to updates from background service (specifically when a reminder is triggered)
    _backgroundService.backgroundUpdates.listen((event) {
      if (event != null &&
          (event['status'] == 'triggered' ||
           event['action'] == 'triggered')) {
        evaluateMonitoringState(
          source: 'backgroundUpdatesListener',
          reason: 'status_triggered',
        );
      }
    });
  }

  @override
  Future<void> evaluateMonitoringState({String source = 'unknown', String reason = 'unknown'}) async {
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

    debugPrint("======================================");
    debugPrint("[COORDINATOR] evaluateMonitoringState()");
    final explicitlyEnabled = _settingsService.isMonitoringEnabled();
    final reminders = await _reminderRepository.getAllReminders();
    debugPrint("[COORDINATOR] Total reminders: ${reminders.length}");

    _logReminders(reminders);

    final shouldBeRunning = _calculateMonitoringState(reminders, explicitlyEnabled);

    debugPrint("[COORDINATOR] Checking service state...");
    final isRunning = await _backgroundService.isRunning();
    debugPrint("[COORDINATOR] isRunning=$isRunning");

    await _applyServiceLifecycle(
      shouldBeRunning: shouldBeRunning,
      isRunning: isRunning,
      cycleId: cycleId,
      source: source,
      reason: reason,
    );

    debugPrint("[COORDINATOR] Evaluation finished");
    debugPrint("======================================");
  }

  Future<void> _reactivateExpiredSnoozes() async {
    final reactivatedCount = await _reminderRepository.reactivateExpiredSnoozes();
    if (reactivatedCount > 0) {
      debugPrint('[SNOOZE] Reactivated $reactivatedCount expired snoozed reminders.');
    }
  }

  void _logReminders(List<ReminderEntity> reminders) {
    for (final r in reminders) {
      debugPrint(
          "[COORDINATOR] "
          "ID=${r.id} "
          "Title=${r.title} "
          "Enabled=${r.isEnabled} "
          "Triggered=${r.isTriggered} "
          "Status=${r.status}");
    }
  }

  bool _calculateMonitoringState(List<ReminderEntity> reminders, bool explicitlyEnabled) {
    final hasActiveReminder = reminders.any((r) => r.isEnabled && !r.isTriggered && r.status != 'snoozed');
    final hasPendingSnooze = reminders.any((r) => r.isEnabled && r.status == 'snoozed' && r.snoozedUntil != null && r.snoozedUntil!.isAfter(DateTime.now()));

    final shouldBeRunning = explicitlyEnabled && (hasActiveReminder || hasPendingSnooze);
    debugPrint("[COORDINATOR] explicitlyEnabled=$explicitlyEnabled");
    debugPrint("[COORDINATOR] hasActiveReminder=$hasActiveReminder");
    debugPrint("[COORDINATOR] hasPendingSnooze=$hasPendingSnooze");
    debugPrint("[COORDINATOR] shouldBeRunning=$shouldBeRunning");
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
        debugPrint("[COORDINATOR] Calling startService()");
        await _backgroundService.startService();
      } else {
        await _backgroundService.refreshMonitoring(
          cycleId: cycleId,
          source: source,
          reason: reason,
        );
      }
    } else {
      if (isRunning) {
        debugPrint("[COORDINATOR] Calling stopService()");
        await _backgroundService.stopService();
      }
    }
  }

  @override
  Future<void> setMonitoringEnabled(bool enabled) async {
    await _settingsService.saveMonitoringEnabled(enabled);
    await evaluateMonitoringState(
      source: 'setMonitoringEnabled',
      reason: enabled ? 'enabled' : 'disabled',
    );
  }

  @override
  bool isMonitoringEnabled() {
    return _settingsService.isMonitoringEnabled();
  }
}
