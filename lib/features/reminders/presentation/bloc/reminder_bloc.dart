import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:reminders/core/services/monitoring_coordinator.dart';
import 'package:reminders/features/reminders/domain/usecases/create_reminder_usecase.dart';
import 'package:reminders/features/reminders/domain/usecases/delete_reminder_usecase.dart';
import 'package:reminders/features/reminders/domain/usecases/get_all_reminders_usecase.dart';
import 'package:reminders/features/reminders/domain/usecases/update_reminder_usecase.dart';
import 'reminder_event.dart';
import 'reminder_state.dart';

@injectable
class ReminderBloc extends Bloc<ReminderEvent, ReminderState> {
  final GetAllRemindersUseCase _getAllReminders;
  final CreateReminderUseCase _createReminder;
  final UpdateReminderUseCase _updateReminder;
  final DeleteReminderUseCase _deleteReminder;
  final MonitoringCoordinator _monitoringCoordinator;

  ReminderBloc(
    this._getAllReminders,
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
  }

  Future<void> _onLoadReminders(
    LoadReminders event,
    Emitter<ReminderState> emit,
  ) async {
    emit(const ReminderState.loading());
    try {
      final reminders = await _getAllReminders();
      if (reminders.isEmpty) {
        emit(const ReminderState.empty());
      } else {
        emit(ReminderState.loaded(reminders: reminders));
      }
    } catch (e) {
      emit(ReminderState.error(message: 'Failed to load reminders: $e'));
    }
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

      // Persist toggle via repository (datasource handles updatedAt)
      final reminder = (currentState is ReminderLoaded
              ? currentState.reminders.firstWhere((r) => r.id == event.id)
              : null)
          ?.copyWith(isEnabled: event.isEnabled, updatedAt: DateTime.now());
      if (reminder == null) throw Exception('Reminder not found');

      await _updateReminder(reminder);
      await _monitoringCoordinator.evaluateMonitoringState();
    } catch (e) {
      emit(ReminderState.error(message: 'Failed to toggle reminder: $e'));
      // Reload to get consistent state
      add(const ReminderEvent.loadReminders());
    }
  }
}
