import 'package:freezed_annotation/freezed_annotation.dart';

part 'validation_event.freezed.dart';

@freezed
class ValidationEvent with _$ValidationEvent {
  const factory ValidationEvent.initialize() = Initialize;
  const factory ValidationEvent.requestNotificationPermission() =
      RequestNotificationPermission;
  const factory ValidationEvent.triggerTestNotification() =
      TriggerTestNotification;
  const factory ValidationEvent.requestLocationPermission() =
      RequestLocationPermission;
  const factory ValidationEvent.fetchCurrentLocation() = FetchCurrentLocation;
  const factory ValidationEvent.toggleLocationStream() = ToggleLocationStream;
  const factory ValidationEvent.startAlarm() = StartAlarm;
  const factory ValidationEvent.stopAlarm() = StopAlarm;
  const factory ValidationEvent.toggleBackgroundService() =
      ToggleBackgroundService;
  const factory ValidationEvent.updateBackgroundTick({
    required Map<String, dynamic> data,
  }) = UpdateBackgroundTick;
  const factory ValidationEvent.changeAlarmTone({
    required String path,
  }) = ChangeAlarmTone;
  const factory ValidationEvent.toggleMonitoring({
    required bool enabled,
  }) = ToggleMonitoring;
  const factory ValidationEvent.openAppSettings() = OpenAppSettings;
}
