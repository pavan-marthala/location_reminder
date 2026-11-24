# Integrations and Permissions

This document details the external services, native integration points, and platform permission declarations required for the Location Reminder app.

## 1. Native Platform Permissions

Since the application tracks user location in the background and sends alert notifications, specific declarations and prompts must be configured on Android and iOS.

### Android Permissions (declared in `AndroidManifest.xml`)

* **Fine & Coarse Location**:
  ```xml
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
  ```
* **Background Location**: Required to monitor location when the app is minimized or closed.
  ```xml
  <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
  ```
* **Foreground Service**: Allows the app to run background checks in a persistent background process.
  ```xml
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
  ```
* **Notifications**: Required starting from Android 13 (API level 33).
  ```xml
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
  ```

### iOS Permissions (declared in `Info.plist`)

* **Location Services**:
  - `NSLocationWhenInUseUsageDescription`: Displays when the app requests to track location in the foreground.
  - `NSLocationAlwaysAndWhenInUseUsageDescription`: Displays when the app requests permanent background location tracking.
  - `NSLocationAlwaysUsageDescription`: Legacy backup description key.
* **Background Mode Capabilities**:
  - `location`: Must be enabled under Signing & Capabilities -> Background Modes to allow background location updates.
  - `processing` / `fetch`: Enables background execution.
* **Notification Permissions**:
  - Declared via `UNUserNotificationCenter` requests in Swift and Flutter.

---

## 2. Background Location Tracking Service

The core of the application relies on coordinate monitoring while the app is in the background, utilizing `flutter_background_service` and `geolocator`.

- **Isolate Architecture**: A separate Dart isolate runs the foreground location monitor (`flutter_background_service`), with a persistent `location`-type notification.
- **System Geofences**: Play Services registers `rem_<id>_target` (user radius, 150 m floor) and `rem_<id>_approach` (10 km) fences. The native receiver survives process death, writes the pending arrival and starts the foreground service.
- **Location Updates**: The isolate uses `Geolocator.getPositionStream` with adaptive sampling (far/mid/near buckets based on distance to the nearest reminder).
- **Geofence Calculation**: Each position is compared against active reminders from Drift; arrival is claimed with a conditional update so it cannot double-fire with the system fence.
- **Database**: The isolate opens its own Drift connection to the same `app_database.db` file (schema version 6).

---

## 3. Local Notifications Integration

Local notifications are managed using the `flutter_local_notifications` package.

- **Notification Channels (Android)**: Defined with high importance and audio alerts. Custom channels must be configured on app initialization.
- **Payload & Routing**: Selecting a notification routes the user to the specific reminder detail page using `go_router` via payload data.
- **Background Wakeup**: Tapping notifications launches or brings the app into foreground.

---

## 4. Mapbox Integration

Map rendering and place search use `mapbox_maps_flutter` and the Mapbox geocoding HTTP API.

- **API Key**: `MAPBOX_ACCESS_TOKEN` in `.env`, loaded by `flutter_dotenv` and applied with `MapboxOptions.setAccessToken()` in `MapboxServiceImpl.init()`.
- **Map Components**: The location picker draws the selected geofence circle with a draggable radius handle (150 m–10 km), nearby reminder markers, and place-autocomplete results from geocoding.
- **Reverse geocoding** supplies the location name/address saved with each reminder.

---

## 5. Audioplayers Integration

Alert sound triggers are handled by the `audioplayers` package.

- **Assets**: Tone files are in `assets/audio/` and declared in `pubspec.yaml`; the default tone is also bundled as an Android raw resource for system notifications.
- **Lifecycle**: `AlarmService` owns looping audio when `AlarmPage` is open and stops audio/vibration on dismiss, complete and snooze.
- **Background Audio**: The OS plays the bundled alarm sound through the full-screen `alarm_channel` notification; when the alarm screen opens it cancels that notification and takes over with looping audio.

---

## 6. Environment Configurations

All private API keys and endpoints are stored in environment variables.

- **Dotenv**: Managed with `flutter_dotenv`.
- **Configuration**: An `.env` file at the project root is loaded inside `main.dart` before `runApp()` is called.
