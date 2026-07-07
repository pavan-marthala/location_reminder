import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:reminders/core/di/injection.dart';
import 'package:reminders/core/services/alarm_scheduler_service.dart';
import 'package:reminders/core/services/monitoring_coordinator.dart';
import 'package:reminders/core/services/settings_service.dart';
import 'package:reminders/core/services/location_service.dart';
import 'package:reminders/features/reminders/domain/entities/reminder_entity.dart';
import 'package:reminders/features/reminders/domain/entities/reminder_enums.dart';
import 'package:reminders/features/reminders/domain/services/reminder_query_service.dart';
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
  final ReminderQueryService _reminderQueryService;
  final SettingsService _settingsService;
  final LocationService _locationService;

  StreamSubscription<List<ReminderEntity>>? _remindersSubscription;
  Position? _lastKnownPos;

  ReminderBloc(
    this._watchAllReminders,
    this._createReminder,
    this._updateReminder,
    this._deleteReminder,
    this._monitoringCoordinator,
    this._reminderQueryService,
    this._settingsService,
    this._locationService,
  ) : super(const ReminderState.initial()) {
    on<LoadReminders>(_onLoadReminders);
    on<CreateReminder>(_onCreateReminder);
    on<UpdateReminder>(_onUpdateReminder);
    on<DeleteReminder>(_onDeleteReminder);
    on<ToggleReminder>(_onToggleReminder);
    on<RemindersUpdated>(_onRemindersUpdated);
    on<RemindersError>(_onRemindersError);
    on<ChangeSearchQuery>(_onChangeSearchQuery);
    on<ChangeSortOption>(_onChangeSortOption);
  }

  Future<void> _onLoadReminders(
    LoadReminders event,
    Emitter<ReminderState> emit,
  ) async {
    emit(const ReminderState.loading());
    
    // Fetch location asynchronously so we don't block
    _locationService.getCurrentLocation().then((pos) {
      _lastKnownPos = pos;
      if (state is ReminderLoaded) {
        add(ReminderEvent.changeSortOption(option: (state as ReminderLoaded).sortBy));
      }
    }).catchError((_) {});

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
      debugPrint("[BLOC] Creating reminder...");
      await _createReminder(event.reminder);
      debugPrint("[BLOC] Reminder inserted successfully.");
      debugPrint("[BLOC] Calling evaluateMonitoringState()");
      await _monitoringCoordinator.evaluateMonitoringState(
        source: 'ReminderBloc',
        reason: 'createReminder',
      );
      debugPrint("[BLOC] evaluateMonitoringState() finished");
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
      await _monitoringCoordinator.evaluateMonitoringState(
        source: 'ReminderBloc',
        reason: 'updateReminder',
      );
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
      await _monitoringCoordinator.evaluateMonitoringState(
        source: 'ReminderBloc',
        reason: 'deleteReminder',
      );
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
      final currentState = state;
      if (currentState is ReminderLoaded) {
        final updatedReminders = currentState.reminders.map((r) {
          if (r.id == event.id) {
            return r.copyWith(isEnabled: event.isEnabled);
          }
          return r;
        }).toList();
        
        final filtered = _reminderQueryService.query(
          reminders: updatedReminders,
          searchQuery: currentState.searchQuery,
          sortBy: currentState.sortBy,
          currentPosition: _lastKnownPos,
        );

        emit(ReminderState.loaded(
          reminders: updatedReminders,
          filteredReminders: filtered,
          searchQuery: currentState.searchQuery,
          sortBy: currentState.sortBy,
        ));
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
      await _monitoringCoordinator.evaluateMonitoringState(
        source: 'ReminderBloc',
        reason: 'toggleReminder',
      );
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
      final currentState = state;
      String query = '';
      SortOption sortBy = _settingsService.getSortOption();
      
      if (currentState is ReminderLoaded) {
        query = currentState.searchQuery;
        sortBy = currentState.sortBy;
      }

      final filtered = _reminderQueryService.query(
        reminders: event.reminders,
        searchQuery: query,
        sortBy: sortBy,
        currentPosition: _lastKnownPos,
      );

      emit(ReminderState.loaded(
        reminders: event.reminders,
        filteredReminders: filtered,
        searchQuery: query,
        sortBy: sortBy,
      ));
    }
  }

  void _onRemindersError(
    RemindersError event,
    Emitter<ReminderState> emit,
  ) {
    emit(ReminderState.error(message: event.message));
  }

  void _onChangeSearchQuery(
    ChangeSearchQuery event,
    Emitter<ReminderState> emit,
  ) {
    final currentState = state;
    if (currentState is ReminderLoaded) {
      final filtered = _reminderQueryService.query(
        reminders: currentState.reminders,
        searchQuery: event.query,
        sortBy: currentState.sortBy,
        currentPosition: _lastKnownPos,
      );
      emit(currentState.copyWith(
        searchQuery: event.query,
        filteredReminders: filtered,
      ));
    }
  }

  Future<void> _onChangeSortOption(
    ChangeSortOption event,
    Emitter<ReminderState> emit,
  ) async {
    final currentState = state;
    if (currentState is ReminderLoaded) {
      await _settingsService.saveSortOption(event.option);
      if (event.option == SortOption.distanceNearest || event.option == SortOption.distanceFarthest) {
        try {
          _lastKnownPos = await _locationService.getCurrentLocation();
        } catch (_) {}
      }
      final filtered = _reminderQueryService.query(
        reminders: currentState.reminders,
        searchQuery: currentState.searchQuery,
        sortBy: event.option,
        currentPosition: _lastKnownPos,
      );
      emit(currentState.copyWith(
        sortBy: event.option,
        filteredReminders: filtered,
      ));
    }
  }

  @override
  Future<void> close() {
    _remindersSubscription?.cancel();
    return super.close();
  }
}
