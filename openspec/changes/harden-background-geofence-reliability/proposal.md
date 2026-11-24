# Proposal

## Why

Field testing shows that the Flutter-only foreground service is killed by the OS/OEM after roughly 20–40 minutes on a long trip, so a reminder for a destination ~100 m away never fires when the user actually arrives. After adding Play Services geofences, the alarm did fire at the destination while the app UI was cold started, confirming that the system geofence survives process death but the app's own state, trigger hand-off, and alarm presentation were not designed around that reality. The current hybrid implementation works intermittently and needs explicit lifecycle, idempotency, and readiness guarantees rather than relying on timing.

## What Changes

- Treat Play Services geofences as the **surviving arrival detector** and the Flutter foreground service as the **live tracking/alarm presenter**, with an explicit contract for hand-off between them.
- Make geofence reconciliation deterministic: re-register target and approach fences whenever reminders are created, updated, deleted, toggled, triggered, snoozed, or completed, on every app cold start, on app resume, and after reboot/package replacement; verify the registered set matches the active reminder set.
- Fix the pending-trigger hand-off so a geofence arrival is consumed exactly once, is cleared by both the native receiver path and the live evaluator, and can never fire a stale alarm on a later service restart.
- Make the alarm audible and visible even when the app process/UI is not alive: deliver a full-screen high-priority notification on trigger, and do not depend on `AlarmPage` being open for audio to start.
- After a cold start caused by an alarm, surface the pending alarm to the user and resume monitoring without losing reminders or duplicating triggers.
- Make notification permission a hard readiness gate alongside "always" location and battery-optimization exemption, with clear diagnostics when a prerequisite is missing.
- Align the selectable radius range with the radius actually registered natively, so the fired fence matches the user's selection.
- Add end-to-end diagnostics (fence sync state, last geofence event/error, trigger id, isolate heartbeat, readiness state) so field failures are attributable without guesswork.
- Add automated coverage for the reconciliation, hand-off, and alarm-state transitions.

## Capabilities

### New Capabilities

- `background-geofence-monitoring`: Owns the full lifecycle of background arrival detection — Play Services target/approach fences, the foreground location service, their reconciliation across process death, reboot, app cold start/resume, and live distance evaluation.
- `alarm-delivery-reliability`: Owns the trigger-to-alarm contract — exactly-once trigger consumption, audible/visible alarm independent of the UI process, snooze/resume behavior, and surfacing an alarm after a cold start.
- `background-execution-readiness`: Owns the prerequisite checks (always-allow location, notification permission, battery exemption, OEM constraints) and the diagnostics/diagnosability that determine whether monitoring may run.

### Modified Capabilities

- None (no existing specs in the project).

## Impact

- `lib/core/services/geofence_service.dart`, `lib/core/services/background_service.dart`, `lib/core/services/monitoring_coordinator.dart`, `lib/core/services/notification_service.dart`, `lib/core/services/alarm_service.dart`, `lib/core/services/alarm_scheduler_service.dart`, `lib/core/services/permission_validation_service.dart`.
- `lib/main.dart` (cold-start alarm routing and monitoring recovery), `lib/core/routes/app_routes.dart`.
- `lib/features/reminders/presentation/pages/location_picker_page.dart` (radius range), `lib/features/reminders/presentation/pages/alarm_page.dart`, `lib/features/infrastructure_validation/**` and `lib/features/settings/presentation/pages/developer_tools_page.dart` (readiness/diagnostics).
- Native Android: `MainActivity.kt` (geofence MethodChannel), `android/app/src/main/kotlin/com/example/reminders/geofence/**`, `AndroidManifest.xml`.
- Data: Drift `AppDatabase` (schema version 5) may gain trigger-dedupe/hand-off state; migration required if columns are added.
- No new external dependencies are required; Play Services geofencing, `flutter_background_service`, `flutter_local_notifications`, and Drift are already present.
