import 'package:freezed_annotation/freezed_annotation.dart';

part 'validation_state.freezed.dart';

@freezed
class ValidationState with _$ValidationState {
  const factory ValidationState({
    @Default(false) bool isInitialized,
    @Default(false) bool isAlarmPlaying,
    @Default(false) bool isBackgroundServiceRunning,
    @Default(false) bool isLocationStreamActive,
    @Default(false) bool isNotificationPermissionGranted,
    @Default(false) bool isLocationPermissionGranted,
    @Default(false) bool isBackgroundLocationPermissionGranted,
    @Default(true) bool isMonitoringEnabled,
    String? selectedAlarmTone,
    String? currentCoordinates,
    String? latestBackgroundTick,
    String? errorMessage,
    @Default(false) bool isLoading,
  }) = _ValidationState;
}
