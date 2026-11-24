# Design

## Context

The app already has both layers implemented, but they are wired as independent optimizations rather than as one contract:

- `MonitoringCoordinator` syncs Play Services fences only from selected call sites (create/update/delete/toggle, cold start, resume, background trigger) and never verifies the result.
- The Dart side sends a fence list over `com.example.reminders/geofence`; `MainActivity.kt` delegates to `GeofenceManager`, which persists specs in `geofence_store` and registers two fences per reminder (`rem_<id>_target`, `rem_<id>_approach`). A boot receiver reloads the stored list.
- The native receiver writes `pending_geofence_trigger_id` into `FlutterSharedPreferences` and starts the foreground service. `background_service.dart` consumes that id only inside `onStart`, so an arrival seen while the isolate is already running leaves a stale id behind, and a later restart can produce a late alarm.
- The trigger notification uses `playSound: false`; sound is started only by `AlarmPage`. An OEM that suppresses the full-screen intent leaves a silent alarm.
- The picker clamps radius to 100–10,000 m while the native target fence enforces a 150 m minimum, so the fired fence can be larger than the selection.
- `PermissionValidationService.isAppReady()` checks location and battery exemption but not notification permission.

Drift (schema version 5) is the shared source of truth: both the UI isolate and the background isolate open the same `app_database.db`. Android package id is `com.example.reminders`.

## Goals / Non-Goals

**Goals:**

- Give the system fence and the Flutter monitor explicit, non-overlapping responsibilities and a single reconciliation path.
- Make a reminder arrival produce exactly one alarm, including arrivals that happen while the process is dead.
- Make the alarm audible/visible without assuming the alarm screen is open.
- Make monitoring health diagnosable after a field failure.

**Non-Goals:**

- Guarantee sub-second arrival detection; Play Services geofence responsiveness and Doze impose multi-second-to-minute latency.
- Support monitoring after the user force-stops the app or clears Play Services data.
- Restore the exact pre-kill UI screen/route stack; a sensible cold start with the alarm surfaced is sufficient.
- Change the iOS implementation beyond keeping it compilable.

## Decisions

### 1. Keep the hybrid ownership split

Play Services geofences are the **surviving arrival detector**; the Flutter foreground service is the **live approach tracker and alarm presenter**.

- Rationale: field testing showed the Dart process is killed after 20–40 minutes, while the system fence still fired at the destination. Any Dart-only design inherits that kill.
- Alternatives considered: pure Flutter foreground service (rejected: observed process death), WorkManager periodic location checks (rejected: battery cost and poor arrival latency), system fence only without a foreground service (rejected: loses approach guidance, live state, and snooze timers).

### 2. One reconciliation entry point with a fingerprint

`MonitoringCoordinator.evaluateMonitoringState()` becomes the only code path that computes fence eligibility and calls `GeofenceService.syncGeofences()`. It is triggered by:

- a debounced subscription to `ReminderRepository.watchAllReminders()` (covers create, update, delete, toggle, trigger, snooze, and background reactivation);
- app cold start and lifecycle resume (already present in `main.dart`);
- the boot/package-replacement receiver, which re-registers from the native store.

Reconciliation computes a stable fingerprint: sorted `(id, latitude, longitude, radius)` for eligible reminders. If the fingerprint equals the last successfully synced one, the native call is skipped; otherwise the full list is sent and the native side replaces all fences atomically (it already calls `removeGeofences` before `addGeofences`). An `isEvaluating` guard serializes re-entrant evaluations caused by the coordinator's own snooze reactivation write.

- Rationale: eliminates the "works sometimes" behavior caused by missed call sites and repeated native churn.
- Alternatives: per-mutation explicit calls from the BLoC (current approach; easy to miss a path) or polling the database from native (unnecessary second source of truth).

### 3. Versioned pending hand-off with TTL and conditional DB claim

The pending arrival becomes an envelope: `pending_geofence_trigger_id` plus `pending_geofence_trigger_at`, written by `PendingTrigger.set()`. Consumption rules:

1. The background isolate checks the envelope on `onStart`, on `refreshMonitoring`, and on a 5-second periodic timer while monitoring (this covers an arrival detected while the isolate is already alive).
2. Read the id and timestamp, clear the envelope first, then claim the trigger with a conditional Drift update: `WHERE id = ? AND isTriggered = 0 AND status NOT IN ('completed','snoozed')`. Only one updated row is allowed to produce an alarm.
3. Discard envelopes older than 10 minutes (late fence replay after reboot/Doze must not ring an old alarm).
4. The live distance evaluator uses the same conditional claim and clears the envelope for that id when it wins, so the two detectors cannot double-fire.

- Rationale: fixes both observed failure modes — the missed hand-off when the isolate is alive and the stale alarm on a later restart — without adding a new database table.
- Alternatives: a dedicated trigger-events table (more robust but requires schema migration and cleanup policy), or native-only state (cannot see Drift trigger status).

### 4. OS-owned alarm sound, UI-owned looping audio

The alarm notification (`alarm_channel`) is changed to `playSound: true` with an alarm-category sound from a single bundled native raw resource (`res/raw/daybreak.mp3`, copied from `assets/audio/`), `fullScreenIntent: true`, max importance, and vibration per settings. A bundled default tone is acceptable for background alarms; the user-selected or per-reminder tone continues to apply when `AlarmPage` is open. This is the sound that works even if Dart audio initialization fails.

When `AlarmPage` opens it cancels that notification and starts looping audio through `AlarmService`; `AlarmService.stopAlarm()` continues to invoke the isolate's `stopAlarm` and cancel vibration. Snooze notifications use the same OS-owned sound path.

- Rationale: notification sound is played by the OS, so it does not depend on a Dart isolate or audio session surviving process death; cancelling the notification when the UI takes over prevents double audio.
- Alternatives: start looping audio from the isolate (already possible but unreliable on OEM devices and would double with the notification), or keep sound only in the UI (current silent-alarm bug).

### 5. Align radius selection with the registered fence

Introduce `AppConstants.minGeofenceRadiusMeters = 150` and `maxGeofenceRadiusMeters = 10000`, use them in the picker handle clamp and in create/update validation, and keep the native `MIN_RADIUS_METERS = 150f` as a defensive floor. A Drift migration (schema version 6) raises any stored radius below 150 m to 150 m so existing reminders match their fence.

- Rationale: the user-visible radius and the fence that actually rings must be the same number.
- Alternative: lower the native floor to 100 m — rejected because 150 m is the safer value for reliable detection on Play Services.

### 6. Notification permission becomes a hard readiness requirement

`PermissionValidationService.isAppReady()` adds `NotificationService.areNotificationsEnabled()`. The onboarding flow already has a notification step, so this closes the gap where monitoring is "healthy" but alarms are silent. Diagnostics link to the existing background-protection page for OEM guidance.

### 7. Diagnostics as a first-class surface

Extend `GeofenceManager.status()` with expected fence count, last successful sync time, pending arrival id/age, and last event/error. Surface these alongside the isolate heartbeat and readiness state in the developer tools page; flag a stale heartbeat when eligible reminders exist.

## Risks / Trade-offs

- [System fences can still be dropped by force-stop, cleared Play Services data, or disabled location accuracy] → Diagnostics expose fence count/last error; the live foreground service remains a fallback while it is alive; document the gap in the UI.
- [Arrival latency is bounded by fence responsiveness (target 180 s, approach 300 s) and Doze] → Keep responsiveness values, state the latency in the onboarding/diagnostics copy, and avoid promising instant alerts.
- [Only 100 fences can be registered; approach fences are skipped above 50 reminders] → Keep the cap and disclose the effective behavior in diagnostics.
- [Repeated full fence replacement is expensive and can hit Play Services limits] → Fingerprint dedupe and serialized reconciliation.
- [Multi-isolate Drift writes can contend] → Keep the background claim update to a single short transaction; enable WAL in `beforeOpen` if contention is observed in diagnostics.
- [Bundling an alarm tone into `res/raw` increases APK size and duplicates a Flutter asset] → Bundle only the default tone; per-reminder tone selection applies when the alarm screen is open.
- [Raising sub-150 m stored radii changes user data once] → Migration is explicit, one-time, and documented in release notes; the fence already behaved at 150 m before this change.
- [Polling the pending envelope every 5 seconds adds wakeups] → Only poll while eligible reminders exist; stop with the service.

## Migration Plan

1. Add schema version 6 with a single `UPDATE reminders SET radius = 150 WHERE radius < 150` (guarded, idempotent) and keep all existing version 2–5 migrations intact.
2. Deploy with no API changes to the geofence MethodChannel; native and Dart changes ship in the same build.
3. On first launch after upgrade, the coordinator performs a forced fence sync (ignore cached fingerprint on cold start), replacing the previously registered set.
4. Rollback: revert the change, force a fence re-sync from the existing coordinator call sites, and keep the database at version 6 (no destructive downgrade needed).

## Open Questions

- Should target fence responsiveness be reduced below 180 s once field latency is measured? This does not change the behavior contract, only tuning.
