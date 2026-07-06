import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:reminders/features/reminders/domain/entities/reminder_enums.dart';

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
    @Default(true) bool isVibrationEnabled,
    @Default(VibrationPattern.defaultPattern) VibrationPattern selectedVibrationPattern,
    String? selectedAlarmTone,
    String? currentCoordinates,
    String? latestBackgroundTick,
    String? backgroundReadinessState,
    String? errorMessage,
    @Default(false) bool isLoading,
  }) = _ValidationState;
}
