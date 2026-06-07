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

- **Isolate Architecture**: A separate Dart execution thread (isolate) is spun up by `flutter_background_service` when initialized.
- **Location Updates**: The background isolate initiates location listening using `Geolocator.getPositionStream`.
- **Geofence Calculation**: Each location update calculates the distance between the user's current coordinates and all active geofenced reminders saved in Isar.
- **Database Thread-Safety**: Since the background service runs in a separate isolate, it initializes its own instance of `Isar` to read active reminders, adhering to thread-safety guidelines.

---

## 3. Local Notifications Integration

Local notifications are managed using the `flutter_local_notifications` package.

- **Notification Channels (Android)**: Defined with high importance and audio alerts. Custom channels must be configured on app initialization.
- **Payload & Routing**: Selecting a notification routes the user to the specific reminder detail page using `go_router` via payload data.
- **Background Wakeup**: Tapping notifications launches or brings the app into foreground.

---

## 4. Google Maps API Integration

Visualizing geofences and reminder coordinates on the UI utilizes `google_maps_flutter`.

- **API Keys**:
  - **Android**: Set in `android/app/src/main/AndroidManifest.xml` within the `<meta-data>` block under `com.google.android.geo.API_KEY`.
  - **iOS**: Configured programmatically inside `ios/Runner/AppDelegate.swift` using `GMSServices.provideAPIKey()`.
- **Map Components**: Rendered with custom styles, active geofence circles, and interactive markers.

---

## 5. Audioplayers Integration

Alert sound triggers are handled by the `audioplayers` package.

- **Assets**: Audio files are located in `assets/audio/` and declared in `pubspec.yaml`.
- **Lifecycle**: The `AudioPlayer` is registered as a lazy singleton via `get_it` and disposed of correctly on app closure.
- **Background Audio**: Alert playing works in the background isolate to sound alerts immediately upon entering a geofenced area.

---

## 6. Environment Configurations

All private API keys and endpoints are stored in environment variables.

- **Dotenv**: Managed with `flutter_dotenv`.
- **Configuration**: An `.env` file at the project root is loaded inside `main.dart` before `runApp()` is called.
