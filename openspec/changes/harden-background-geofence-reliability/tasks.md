# Tasks

## 1. Shared radius contract and database migration

- [x] 1.1 Add `minGeofenceRadiusMeters = 150` and `maxGeofenceRadiusMeters = 10000` to `AppConstants`, use them in the location picker handle clamp and in create/update reminder validation so the displayed radius equals the fenced radius; verify with unit tests that 100 m clamps to 150 m, 10,000 m is accepted, and 10,001 m clamps to 10,000 m.
- [x] 1.2 Bump Drift `AppDatabase` to schema version 6 with an idempotent migration that raises any stored `radius < 150` to 150 while preserving versions 2–5; verify with an `app_database_test.dart` upgrade case from version 5 and a repeat run that leaves values unchanged.
- [x] 1.3 Document the one-time radius normalization and the supported radius range in the README; verify the text matches the constants defined in 1.1.

## 2. Deterministic fence reconciliation

- [x] 2.1 Add a pure fingerprint function that produces a sorted `(id, latitude, longitude, radius)` signature for reminders eligible for monitoring and an equality check against the last successfully synced signature; verify with unit tests covering add, remove, reorder, and radius-only changes.
- [x] 2.2 Make `MonitoringCoordinator.evaluateMonitoringState()` the single reconciliation path: subscribe to `ReminderRepository.watchAllReminders()` with debounce, add an `isEvaluating` re-entrancy guard, skip native sync when the fingerprint is unchanged, and remove the duplicate per-event sync calls in `ReminderBloc`; verify with a bloc/coordinator test that every reminder mutation leads to at most one sync and an unchanged list leads to none.
- [ ] 2.3 Force a full fence resync on cold start and on app resume (ignore the in-memory fingerprint at process start) and keep the boot/package-replacement re-registration path working from the native store; verify on an Android device via `adb logcat` that a cold start and a reboot each produce a successful `Registered N geofences` entry with the expected count.
- [ ] 2.4 Verify the "no eligible reminders" case clears all fences and stops the foreground service; verify with a device test that completing the last reminder leaves `syncedCount` at 0 and the monitor not running.

## 3. Exactly-once arrival hand-off

- [ ] 3.1 Extend `PendingTrigger` with a written-at timestamp alongside the id and update `GeofenceBroadcastReceiver` to write both; verify by inspecting the `FlutterSharedPreferences` entries after triggering a test geofence on device.
- [x] 3.2 Add a conditional trigger-claim operation that updates a reminder to triggered only when `id = ? AND isTriggered = 0 AND status NOT IN ('completed','snoozed')`, returning the number of affected rows; verify with a Drift test that a second claim on the same row affects zero rows.
- [x] 3.3 Consume the pending envelope on isolate start, on `refreshMonitoring`, and on a 5-second timer while monitoring; clear the envelope before claiming, discard envelopes older than 10 minutes, and produce an alarm only when the claim affects one row; verify with unit tests for fresh arrival, stale envelope, already-triggered reminder, and deleted reminder.
- [x] 3.4 Route the live distance evaluator through the same claim and clear the envelope for that id when the live path wins; verify with a test that a system arrival and a live evaluation for the same reminder produce exactly one alarm and no remaining pending id.

## 4. Alarm presentation and cold-start recovery

- [ ] 4.1 Copy the default alarm tone into `android/app/src/main/res/raw/` and configure `alarm_channel` with `playSound: true`, the bundled sound, full-screen intent, max importance, alarm category, and settings-driven vibration; verify on device that a trigger notification sounds and appears over the lock screen without `AlarmPage` being opened.
- [ ] 4.2 Cancel the trigger notification when `AlarmPage` opens before starting looping audio through `AlarmService`, and keep `stopAlarm` stopping audio, vibration, and the isolate path; verify on device that there is no doubled sound on open and that stop/complete silences the alarm immediately.
- [ ] 4.3 Use the same OS-owned sound path for snoozed alarms and confirm expired snoozes are reactivated for monitoring while the process is dead; verify with the 10-second debug snooze on device that the alarm rings once and the reminder returns to active monitoring.
- [ ] 4.4 Surface the alarm that caused a cold start via the existing pending-launch id and ensure monitoring is restored with reminders intact and no duplicate alarm; verify by forcing the app to the background with `adb shell am kill com.example.reminders`, triggering arrival, reopening the app, and checking the alarm screen plus the reminder list state.

## 5. Execution readiness and diagnostics

- [x] 5.1 Add notification permission to `PermissionValidationService.isAppReady()` while keeping the existing location and battery-exemption gates; verify with a service test that denying notifications makes readiness false and granting it makes readiness true when the other gates pass.
- [ ] 5.2 Extend native `GeofenceManager.status()` with expected fence count, last successful sync time, and pending arrival id/age; verify the MethodChannel `status` response contains the new fields on device.
- [x] 5.3 Surface fence count, last event/error, pending arrival age, readiness, foreground-service state, and heartbeat age in the developer tools page with a stale-heartbeat warning when eligible reminders exist; verify with a widget test using a fake status that each field and the warning render.
- [ ] 5.4 Keep OEM battery/auto-launch guidance in the readiness flow with the existing fallback to application details settings; verify on an OEM device (or via intent fallback test) that a missing vendor activity does not block onboarding.

## 6. End-to-end verification and documentation

- [ ] 6.1 Run the long-trip scenario on a physical Android device: create a ~100 m reminder, background the app, kill the process mid-route, travel into the zone, and confirm one alarm fires and the status shows a synced fence; verify with `adb logcat` output and a screen recording.
- [ ] 6.2 Run the alive-process scenario: trigger an arrival while the foreground service is already running, then restart the service, and confirm no stale alarm appears; verify by checking the pending envelope is cleared and only one alarm was logged.
- [ ] 6.3 Reboot the device with active reminders and confirm fences are restored without opening the app; verify with `GeofenceManager.status()` `syncedCount` matching the active reminder count.
- [x] 6.4 Refresh the stale `.planning/codebase/` documentation to match the current Drift/Mapbox/hybrid architecture and the new readiness requirements; verify that no document still claims Isar or Google Maps is in use.
