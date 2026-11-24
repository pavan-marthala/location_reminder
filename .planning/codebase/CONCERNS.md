# Project Concerns & Risks

This document highlights critical risks, architectural limitations, platform-specific constraints, and dependency vulnerabilities identified during the codebase analysis of the **Location Reminders** application.

---

## 1. Platform-Specific Background & Permission Risks

Because this application relies on real-time background location tracking (`geolocator`, `flutter_background_service`) and user alerts (`flutter_local_notifications`), it is subject to strict OS-level background execution constraints and sandbox policies.

### A. iOS Background Location Constraints & App Store Rejections
*   **Always Allow Requirement**: For the application to check the user's location when the app is terminated or in the background, the user must grant **"Always Allow"** location access. However, iOS initially prompts only for "While In Use". The app must explicitly guide the user to upgrade permissions in System Settings, which is a friction point.
*   **App Store Review Guideline 2.5.4**: Apple heavily scrutinizes applications requesting background location permissions. If the app cannot demonstrate a clear, user-facing need for continuous background tracking, it will be rejected.
*   **Info.plist Missing Declarations**: The current `Info.plist` lacks the mandatory privacy keys. To prevent immediate app store rejection or crashes, the following keys must be added:
    *   `NSLocationAlwaysAndWhenInUseUsageDescription`
    *   `NSLocationWhenInUseUsageDescription`
    *   `UIBackgroundModes` containing `location` and `fetch`.
*   **Sudden OS Revocation**: iOS dynamically prompts users after a few days of background usage, showing a map of location points tracked and asking if they want to downgrade permission to "Only While Using". If downgraded, the background isolate will fail silently.

### B. Android Foreground Service & Permission Scrutiny
*   **Android 14 (API 34) Foreground Service Type**: Android 14 introduces mandatory declarations for foreground services. The background service must explicitly declare its type in `AndroidManifest.xml` as `location`.
    ```xml
    <service
        android:name="id.flutter.flutter_background_service.BackgroundService"
        android:foregroundServiceType="location"
        android:exported="true" />
    ```
*   **ACCESS_BACKGROUND_LOCATION Permission**: Android 10+ requires runtime request of background location. Google Play requires a dedicated privacy declaration and a prominent in-app disclosure video before approving apps with this permission. The runtime dialog can only return `whileInUse`; on Android 11+ the user must switch to **"Allow all the time"** in system settings. The onboarding flow now detects `whileInUse` and routes the user to settings instead of treating it as success.
*   **Battery Optimisation Exemption Is a Hard Gate**: On Android 12+, a location foreground service cannot be (re)started from the background unless the app is exempt from battery optimisations. `PermissionValidationService.isAppReady()` therefore requires both `LocationPermission.always` and the battery exemption; onboarding blocks the final step until the exemption is granted.
*   **OEM Battery Optimizations**: Handsets from manufacturers like Samsung, Xiaomi, and OnePlus deploy aggressive battery savers (e.g., "Put unused apps to sleep"). These will terminate the background location service within minutes unless the user manually whitelist the app from battery optimizations.

### B2. Background Reliability Architecture (implemented)
*   **Play Services Geofencing API is now the primary trigger** (`GeofenceManager` / `GeofenceBroadcastReceiver`). Two fences are registered per reminder:
    *   `rem_<id>_target` — the reminder radius (minimum 150 m), `INITIAL_TRIGGER_ENTER`, responsiveness 180 s.
    *   `rem_<id>_approach` — a 10 km "near target" fence, responsiveness 300 s.
*   Geofences are owned by Play Services, so target entry wakes the app **even when the process was killed by the OEM**. The receiver writes a pending trigger id into `FlutterSharedPreferences` and starts the existing location FGS (a documented Android 12+ background-start exemption). The isolate consumes the pending id on boot.
*   Geofences are re-registered after reboot/package update by `GeofenceBootReceiver` from a locally persisted spec list. The coordinator keeps them in sync on every `evaluateMonitoringState`.
*   **Remaining risk**: if the user force-stops the app, clears Play Services data, or disables "Location accuracy"/Google Play Services, geofences can be dropped and the live FGS is the only fallback. The Developer Tools page exposes synced-fence count, last geofence event/error, background-location state and the isolate heartbeat so this is diagnosable in the field.

### C. Battery Drain & Location Tracking Frequency
*   **Continuous GPS Exhaustion**: Keeping the GPS chip active in high-accuracy mode (`LocationAccuracy.high` or `LocationAccuracy.best`) drains a device's battery from 100% to 0% in 3–5 hours.
*   **Adaptive Tracking (implemented)**: The background isolate now selects a sampling bucket from the distance to the nearest active reminder:
    *   **Far (> 25 km)**: `LocationAccuracy.low`, 1000 m distance filter.
    *   **Mid (5–25 km)**: `LocationAccuracy.medium`, 250 m distance filter.
    *   **Near (≤ 5 km)**: `LocationAccuracy.high`, 10 m distance filter.
    The stream is restarted only when the bucket changes, and Play Services handles the 10 km wake-up even if the isolate is dead.

---

## 2. Hardware & Resource Integration Concerns

### A. Audio Playback Constraints (`audioplayers`)
*   **Silent Mode / Do Not Disturb Override**: On iOS, if the hardware silent switch is toggled, standard audio playback is muted. To ensure reminder alarms ring regardless of physical switch states, the audio session category must be set to `playback` using native configuration (or the `audio_session` package).
*   **Isolate Audio Execution**: The background service running in a separate Dart isolate must play the audio. However, native audio players sometimes fail to initialize properly from non-main isolates on iOS/Android because of window context bindings or audio session hooks.
*   **Resource Leaks**: The `AudioPlayer` registered in GetIt (`RegisterModule.audioPlayer`) is a singleton. If multiple reminders trigger concurrently, calling `.play()` on the same instance will interrupt the current alarm, or crash. There is also a risk of memory leaks if instances are created dynamically and not disposed of via `.dispose()`.

### B. Notification Delivery Reliability (`flutter_local_notifications`)
*   **Android 13+ (API 33) Runtime Permissions**: Apps can no longer show notifications without explicit runtime consent. If the user denies `POST_NOTIFICATIONS`, reminders will trigger silently in the background, rendering the app ineffective.
*   **Background Notification Channel Pinning**: The background service must be tied to a persistent notification channel. If the user disables this channel in settings, the OS will deprioritize and kill the background service.

---

## 3. Data Persistence & Concurrency Risks

The application uses **Drift (SQLite)** as its local database. Both isolates open the same `app_database.db` file.

```
UI isolate -----> Drift SQLite file <----- background isolate
                       |
                  short conditional writes (claimTrigger)
```

### A. Isolate Concurrency
*   **Separate connections**: The main isolate registers `AppDatabase` in `RegisterModule`; the background isolate opens its own `NativeDatabase` directly in `onStart`. Dart isolates do not share memory.
*   **Write contention**: Keep background writes to short conditional updates (`claimTrigger`, snooze reactivation) so UI edits are not blocked. Enable WAL in `beforeOpen` only if diagnostics show contention.
*   **Trigger hand-off**: The pending geofence envelope lives in `FlutterSharedPreferences` (shared by native and Dart); the authoritative trigger claim lives in SQLite, so a stale native envelope cannot produce a second alarm.

### B. Schema Safety & Code Generation
*   **Generator drift**: Drift and injectable output (`app_database.g.dart`, `injection.config.dart`) must be regenerated after schema or DI changes. The current toolchain has a pre-existing `build_resolvers`/analyzer mismatch that can prevent `build_runner` from precompiling; patch generated files only as a short-term workaround and fix the overrides before shipping.
*   **Migrations**: Schema version is `6`. Each migration must stay idempotent and preserve earlier steps; version 6 raises stored radii below 150 m.

---

## 4. Dependency & Build Pipeline Risks

### A. SDK Constraint
*   `pubspec.yaml` declares `sdk: ^3.10.4`; the installed toolchain is Flutter 3.50 / Dart 3.14. The declared floor and overrides should be updated together so code generation and package upgrades work reliably.

### B. Fragile Dependency Overrides
*   The `pubspec.yaml` contains severe dependency overrides:
    ```yaml
    dependency_overrides:
      analyzer: 5.12.0
      dart_style: 2.3.2
      build_resolvers: 2.2.0
    ```
    *   **Root Cause**: These overrides pin old analyzer/build_resolvers versions for older generators (`freezed`, `drift_dev`, `injectable_generator`).
    *   **Observed impact**: `dart run build_runner build` currently fails to precompile its build script with the installed Dart SDK. Regenerating code requires fixing or removing these overrides first.

### C. Platform Scope
*   Android is the target platform. iOS/macOS/desktop/web scaffolding remains in the repository, but native geofencing is Android-only (`GeofenceService` is a no-op elsewhere). Do not assume iOS background-location behavior is validated.

---

## 5. Architectural Concerns

### A. State Synchronization
*   `MonitoringCoordinator` now owns reconciliation: it debounces `ReminderRepository.watchAllReminders()`, computes a fingerprint of monitorable reminders, and re-registers fences only when that fingerprint changes.
*   The background isolate reads the database on every position evaluation and consumes the native pending-arrival envelope on a 5-second poll, so it does not rely on UI-originated IPC for reminder changes.
*   Force-stops, cleared Play Services data, or disabled location accuracy remain uncovered; diagnostics expose fence counts, sync errors and heartbeat freshness.

---

## Actionable Mitigation Checklist

| Risk Area | Specific Threat | Recommended Mitigation |
| :--- | :--- | :--- |
| **Permissions** | iOS / Android Location access denial or downgrades. | Implement a dedicated onboarding flow that explains *why* background permission is required before presenting the OS system dialog. Check permission states on app resume. |
| **Manifests** | App Store rejection or Android background service crashes. | Add `NSLocationAlwaysAndWhenInUseUsageDescription` to `Info.plist`. Add `foregroundServiceType="location"` to Android service declarations. |
| **Battery Life** | Continuous GPS activation causing fast battery drain. | Build an adaptive tracking loop that scales location query interval and accuracy based on the distance to the nearest target reminder. |
| **Audio** | Silent alarms when the UI process is dead. | The OS plays a bundled raw alarm sound via the full-screen `alarm_channel` notification; `AlarmPage` cancels that notification and takes over with looping audio. |
| **Isolate DB** | Write lock contention between isolates. | Keep background writes to short conditional updates; both isolates use the same schema version 6 file. |
| **Dependencies** | Code generator conflicts and fragile overrides. | Fix the analyzer/build_resolvers override mismatch so `build_runner` works, then upgrade dev dependencies. |
| **State Sync** | Stale reminder data in the background isolate. | Coordinator reconciles fences from a debounced Drift watch stream with fingerprint dedupe; the isolate polls the pending-arrival envelope and reads SQLite on every evaluation. |
| **Process Death** | OEM kills the FGS on long, locked sessions (50–100 km reminders). | Primary mitigation is Play Services geofences (`_target` + 10 km `_approach`). The isolate persists a heartbeat, the app recovers on resume, and diagnostics expose fence/heartbeat state. Force-stop / disabled Play Services remains a known gap. |
