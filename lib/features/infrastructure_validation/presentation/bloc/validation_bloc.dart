import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';
import 'package:reminders/core/services/alarm_service.dart';
import 'package:reminders/core/services/background_service.dart';
import 'package:reminders/core/services/location_service.dart';
import 'package:reminders/core/services/notification_service.dart';
import 'validation_event.dart';
import 'validation_state.dart';

@injectable
class ValidationBloc extends Bloc<ValidationEvent, ValidationState> {
  final NotificationService _notificationService;
  final AlarmService _alarmService;
  final LocationService _locationService;
  final BackgroundService _backgroundService;

  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<Map<String, dynamic>?>? _backgroundSubscription;

  ValidationBloc(
    this._notificationService,
    this._alarmService,
    this._locationService,
    this._backgroundService,
  ) : super(const ValidationState()) {
    on<Initialize>(_onInitialize);
    on<RequestNotificationPermission>(_onRequestNotificationPermission);
    on<TriggerTestNotification>(_onTriggerTestNotification);
    on<RequestLocationPermission>(_onRequestLocationPermission);
    on<FetchCurrentLocation>(_onFetchCurrentLocation);
    on<ToggleLocationStream>(_onToggleLocationStream);
    on<StartAlarm>(_onStartAlarm);
    on<StopAlarm>(_onStopAlarm);
    on<ToggleBackgroundService>(_onToggleBackgroundService);
    on<UpdateBackgroundTick>(_onUpdateBackgroundTick);
  }

  Future<void> _onInitialize(
    Initialize event,
    Emitter<ValidationState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      await _notificationService.init();
      await _alarmService.init();
      await _backgroundService.init();

      final bgRunning = await _backgroundService.isRunning();

      // Listen to background service events
      await _backgroundSubscription?.cancel();
      _backgroundSubscription = _backgroundService.backgroundUpdates.listen(
        (data) {
          if (data != null) {
            add(ValidationEvent.updateBackgroundTick(data: data));
          }
        },
      );

      emit(
        state.copyWith(
          isInitialized: true,
          isBackgroundServiceRunning: bgRunning,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Failed to initialize services: $e',
          isLoading: false,
        ),
      );
    }
  }

  Future<void> _onRequestNotificationPermission(
    RequestNotificationPermission event,
    Emitter<ValidationState> emit,
  ) async {
    emit(state.copyWith(errorMessage: null));
    try {
      final granted = await _notificationService.requestPermissions();
      emit(state.copyWith(
        isNotificationPermissionGranted: granted,
        errorMessage: granted ? null : 'Notification permission denied',
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Notification permission error: $e'));
    }
  }

  Future<void> _onTriggerTestNotification(
    TriggerTestNotification event,
    Emitter<ValidationState> emit,
  ) async {
    emit(state.copyWith(errorMessage: null));
    try {
      await _notificationService.showTestNotification(
        title: 'Validation Notification',
        body: 'Local notifications are working perfectly!',
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Notification trigger error: $e'));
    }
  }

  Future<void> _onRequestLocationPermission(
    RequestLocationPermission event,
    Emitter<ValidationState> emit,
  ) async {
    emit(state.copyWith(errorMessage: null));
    try {
      final status = await _locationService.requestPermission();
      final granted = status == LocationPermission.always || status == LocationPermission.whileInUse;
      emit(state.copyWith(
        isLocationPermissionGranted: granted,
        errorMessage: granted ? null : 'Location permission denied',
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Location permission request error: $e'));
    }
  }

  Future<void> _onFetchCurrentLocation(
    FetchCurrentLocation event,
    Emitter<ValidationState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final isEnabled = await _locationService.isLocationServiceEnabled();
      if (!isEnabled) {
        emit(
          state.copyWith(
            errorMessage: 'Location services are disabled on device',
            isLoading: false,
          ),
        );
        return;
      }

      final perm = await _locationService.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        emit(
          state.copyWith(
            errorMessage: 'Location permission is not granted',
            isLoading: false,
          ),
        );
        return;
      }

      final position = await _locationService.getCurrentLocation();
      emit(
        state.copyWith(
          currentCoordinates:
              'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}',
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Failed to fetch location: $e',
          isLoading: false,
        ),
      );
    }
  }

  Future<void> _onToggleLocationStream(
    ToggleLocationStream event,
    Emitter<ValidationState> emit,
  ) async {
    emit(state.copyWith(errorMessage: null));
    if (state.isLocationStreamActive) {
      await _locationSubscription?.cancel();
      _locationSubscription = null;
      emit(state.copyWith(isLocationStreamActive: false));
    } else {
      try {
        final isEnabled = await _locationService.isLocationServiceEnabled();
        if (!isEnabled) {
          emit(state.copyWith(errorMessage: 'Location services are disabled'));
          return;
        }

        emit(state.copyWith(isLocationStreamActive: true));
        await _locationSubscription?.cancel();
    _locationSubscription = _locationService.getLocationStream().listen(
      (position) {
        if (!emit.isDone) {
          emit(
            state.copyWith(
              currentCoordinates:
                  'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}',
            ),
          );
        }
      },
      onError: (e) {
        if (!emit.isDone) {
          emit(
            state.copyWith(
              errorMessage: 'Location stream error: $e',
              isLocationStreamActive: false,
            ),
          );
        }
      },
    );
      } catch (e) {
        emit(
          state.copyWith(
            errorMessage: 'Failed to start location stream: $e',
            isLocationStreamActive: false,
          ),
        );
      }
    }
  }

  Future<void> _onStartAlarm(
    StartAlarm event,
    Emitter<ValidationState> emit,
  ) async {
    emit(state.copyWith(errorMessage: null));
    try {
      await _alarmService.playAlarm();
      emit(state.copyWith(isAlarmPlaying: _alarmService.isPlaying));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to play alarm: $e'));
    }
  }

  Future<void> _onStopAlarm(
    StopAlarm event,
    Emitter<ValidationState> emit,
  ) async {
    emit(state.copyWith(errorMessage: null));
    try {
      await _alarmService.stopAlarm();
      emit(state.copyWith(isAlarmPlaying: _alarmService.isPlaying));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to stop alarm: $e'));
    }
  }

  Future<void> _onToggleBackgroundService(
    ToggleBackgroundService event,
    Emitter<ValidationState> emit,
  ) async {
    emit(state.copyWith(errorMessage: null));
    try {
      final running = await _backgroundService.isRunning();
      if (running) {
        await _backgroundService.stopService();
        emit(state.copyWith(isBackgroundServiceRunning: false));
      } else {
        await _backgroundService.startService();
        emit(state.copyWith(isBackgroundServiceRunning: true));
      }
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Background service toggle error: $e',
        ),
      );
    }
  }

  void _onUpdateBackgroundTick(
    UpdateBackgroundTick event,
    Emitter<ValidationState> emit,
  ) {
    final timeStr = event.data['time'] as String?;
    if (timeStr != null) {
      final parsed = DateTime.tryParse(timeStr);
      if (parsed != null) {
        final formattedTime =
            '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}:${parsed.second.toString().padLeft(2, '0')}';
        emit(
          state.copyWith(
            latestBackgroundTick: 'Check received at $formattedTime',
            isBackgroundServiceRunning: true,
          ),
        );
        return;
      }
    }
    emit(state.copyWith(isBackgroundServiceRunning: true));
  }

  @override
  Future<void> close() async {
    await _locationSubscription?.cancel();
    await _backgroundSubscription?.cancel();
    await _alarmService.stopAlarm();
    return super.close();
  }
}
