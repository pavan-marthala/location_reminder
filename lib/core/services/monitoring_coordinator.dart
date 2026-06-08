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
    final explicitlyEnabled = _settingsService.isMonitoringEnabled();
    final reminders = await _reminderRepository.getAllReminders();
    final hasActiveReminder = reminders.any((r) => r.isEnabled && !r.isTriggered);

    final shouldBeRunning = explicitlyEnabled && hasActiveReminder;

    final isRunning = await _backgroundService.isRunning();

    if (shouldBeRunning) {
      if (!isRunning) {
        await _backgroundService.startService();
      }
    } else {
      if (isRunning) {
        await _backgroundService.stopService();
      }
    }
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
