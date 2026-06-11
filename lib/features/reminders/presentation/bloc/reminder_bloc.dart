import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:reminders/core/di/injection.dart';
import 'package:reminders/core/services/alarm_scheduler_service.dart';
import 'package:reminders/core/services/monitoring_coordinator.dart';
import 'package:reminders/features/reminders/domain/entities/reminder_entity.dart';
import 'package:reminders/features/reminders/domain/usecases/create_reminder_usecase.dart';
import 'package:reminders/features/reminders/domain/usecases/delete_reminder_usecase.dart';
import 'package:reminders/features/reminders/domain/usecases/update_reminder_usecase.dart';
import 'package:reminders/features/reminders/domain/usecases/watch_all_reminders_usecase.dart';
import 'reminder_event.dart';
import 'reminder_state.dart';

@injectable
class ReminderBloc extends Bloc<ReminderEvent, ReminderState> {
  final WatchAllRemindersUseCase _watchAllReminders;
  final CreateReminderUseCase _createReminder;
  final UpdateReminderUseCase _updateReminder;
  final DeleteReminderUseCase _deleteReminder;
  final MonitoringCoordinator _monitoringCoordinator;

  StreamSubscription<List<ReminderEntity>>? _remindersSubscription;

  ReminderBloc(
    this._watchAllReminders,
    this._createReminder,
    this._updateReminder,
    this._deleteReminder,
    this._monitoringCoordinator,
  ) : super(const ReminderState.initial()) {
    on<LoadReminders>(_onLoadReminders);
    on<CreateReminder>(_onCreateReminder);
    on<UpdateReminder>(_onUpdateReminder);
    on<DeleteReminder>(_onDeleteReminder);
    on<ToggleReminder>(_onToggleReminder);
    on<RemindersUpdated>(_onRemindersUpdated);
    on<RemindersError>(_onRemindersError);
  }

  Future<void> _onLoadReminders(
    LoadReminders event,
    Emitter<ReminderState> emit,
  ) async {
    emit(const ReminderState.loading());
    await _remindersSubscription?.cancel();
    _remindersSubscription = _watchAllReminders().listen(
      (reminders) {
        add(ReminderEvent.remindersUpdated(reminders: reminders));
      },
      onError: (e) {
        add(ReminderEvent.remindersError(message: e.toString()));
      },
    );
  }

  Future<void> _onCreateReminder(
    CreateReminder event,
    Emitter<ReminderState> emit,
  ) async {
    try {
      await _createReminder(event.reminder);
      await _monitoringCoordinator.evaluateMonitoringState();
      // Reload the list after creating
      add(const ReminderEvent.loadReminders());
    } catch (e) {
      emit(ReminderState.error(message: 'Failed to create reminder: $e'));
    }
  }

  Future<void> _onUpdateReminder(
    UpdateReminder event,
    Emitter<ReminderState> emit,
  ) async {
    try {
      await _updateReminder(event.reminder);
      await _monitoringCoordinator.evaluateMonitoringState();
      add(const ReminderEvent.loadReminders());
    } catch (e) {
      emit(ReminderState.error(message: 'Failed to update reminder: $e'));
    }
  }

  Future<void> _onDeleteReminder(
    DeleteReminder event,
    Emitter<ReminderState> emit,
  ) async {
    try {
      await _deleteReminder(event.id);
      try {
        await getIt<AlarmSchedulerService>().cancelSnooze(event.id);
      } catch (_) {}
      await _monitoringCoordinator.evaluateMonitoringState();
      add(const ReminderEvent.loadReminders());
    } catch (e) {
      emit(ReminderState.error(message: 'Failed to delete reminder: $e'));
    }
  }

  Future<void> _onToggleReminder(
    ToggleReminder event,
    Emitter<ReminderState> emit,
  ) async {
    try {
      // Optimistic update: update the local list immediately
      final currentState = state;
      if (currentState is ReminderLoaded) {
        final updatedReminders = currentState.reminders.map((r) {
          if (r.id == event.id) {
            return r.copyWith(isEnabled: event.isEnabled);
          }
          return r;
        }).toList();
        emit(ReminderState.loaded(reminders: updatedReminders));
      }

      final currentReminder = (currentState is ReminderLoaded
              ? currentState.reminders.firstWhere((r) => r.id == event.id)
              : null);
      if (currentReminder == null) throw Exception('Reminder not found');

      final reminder = currentReminder.copyWith(
        isEnabled: event.isEnabled,
        isTriggered: event.isEnabled ? false : currentReminder.isTriggered,
        status: event.isEnabled ? 'active' : 'disabled',
        updatedAt: DateTime.now(),
      );

      await _updateReminder(reminder);
      if (!event.isEnabled) {
        try {
          await getIt<AlarmSchedulerService>().cancelSnooze(event.id);
        } catch (_) {}
      }
      await _monitoringCoordinator.evaluateMonitoringState();
    } catch (e) {
      emit(ReminderState.error(message: 'Failed to toggle reminder: $e'));
      // Reload to get consistent state
      add(const ReminderEvent.loadReminders());
    }
  }

  void _onRemindersUpdated(
    RemindersUpdated event,
    Emitter<ReminderState> emit,
  ) {
    if (event.reminders.isEmpty) {
      emit(const ReminderState.empty());
    } else {
      emit(ReminderState.loaded(reminders: event.reminders));
    }
  }

  void _onRemindersError(
    RemindersError event,
    Emitter<ReminderState> emit,
  ) {
    emit(ReminderState.error(message: event.message));
  }

  @override
  Future<void> close() {
    _remindersSubscription?.cancel();
    return super.close();
  }
}
