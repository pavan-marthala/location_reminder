import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:reminders/core/services/background_service.dart';
import 'package:reminders/core/services/settings_service.dart';
import 'package:reminders/features/reminders/domain/repositories/reminder_repository.dart';

abstract class MonitoringCoordinator {
  Future<void> evaluateMonitoringState();
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
           event['action'] == 'triggered' ||
           event['status'] == 'check')) {
        evaluateMonitoringState();
      }
    });
  }

  @override
  Future<void> evaluateMonitoringState() async {
    debugPrint("======================================");
    debugPrint("[COORDINATOR] evaluateMonitoringState()");
    final explicitlyEnabled = _settingsService.isMonitoringEnabled();
    final reminders = await _reminderRepository.getAllReminders();
    debugPrint("[COORDINATOR] Total reminders: ${reminders.length}");

    for (final r in reminders) {
      debugPrint(
          "[COORDINATOR] "
          "ID=${r.id} "
          "Title=${r.title} "
          "Enabled=${r.isEnabled} "
          "Triggered=${r.isTriggered} "
          "Status=${r.status}");
    }

    final hasActiveReminder = reminders.any((r) => r.isEnabled && !r.isTriggered && r.status != 'snoozed');

    final shouldBeRunning = explicitlyEnabled && hasActiveReminder;
    debugPrint("[COORDINATOR] explicitlyEnabled=$explicitlyEnabled");
    debugPrint("[COORDINATOR] hasActiveReminder=$hasActiveReminder");
    debugPrint("[COORDINATOR] shouldBeRunning=$shouldBeRunning");

    debugPrint("[COORDINATOR] Checking service state...");
    final isRunning = await _backgroundService.isRunning();
    debugPrint("[COORDINATOR] isRunning=$isRunning");

    if (shouldBeRunning) {
      if (!isRunning) {
        debugPrint("[COORDINATOR] Calling startService()");
        await _backgroundService.startService();
      } else {
        debugPrint("======================================\n[COORDINATOR]\nRequesting refreshMonitoring()\n======================================");
        await _backgroundService.refreshMonitoring();
        debugPrint("[COORDINATOR]\nrefreshMonitoring() completed");
      }
    } else {
      if (isRunning) {
        debugPrint("[COORDINATOR] Calling stopService()");
        await _backgroundService.stopService();
      }
    }
    debugPrint("[COORDINATOR] Evaluation finished");
    debugPrint("======================================");
  }

  @override
  Future<void> setMonitoringEnabled(bool enabled) async {
    await _settingsService.saveMonitoringEnabled(enabled);
    await evaluateMonitoringState();
  }

  @override
  bool isMonitoringEnabled() {
    return _settingsService.isMonitoringEnabled();
  }
}
