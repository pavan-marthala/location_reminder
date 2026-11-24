# Technical Stack

This document outlines the core technical stack, libraries, and frameworks utilized in the Location Reminder app.

## Core Platform & Runtime

- **Framework**: [Flutter](https://flutter.dev) (configured with Material 3 design spec: `useMaterial3: true`).
- **Language**: [Dart](https://dart.dev) (SDK version constraint: `^3.10.4`).
- **Target Platforms**: iOS, Android, and macOS.

## Core Packages & Dependencies

Below is the list of key packages used in the project, as declared in `pubspec.yaml`:

### State Management
- **`bloc`** (version `^9.2.0`): The base library for implementing the Business Logic Component (BLoC) pattern.
- **`flutter_bloc`** (version `^9.1.1`): Flutter widgets that integrate seamlessly with `bloc` and handle rebuilds and state listener events.

### Dependency Injection (DI)
- **`get_it`** (version `^9.2.1`): A fast service locator for Dart and Flutter. Used to register and resolve singletons and factories.
- **`injectable`** (version `^2.4.0`): Used alongside `get_it` to generate dependency injection configuration via annotations.
- **`injectable_generator`** (dev dependency, version `^2.4.2`): Code generator for `injectable`.
- **`build_runner`** (dev dependency, version `2.4.0`): The Dart tool used to execute code generation tasks (e.g. for `injectable` and `freezed`).

### Database & Storage
- **`drift`** (version `2.14.1`): Type-safe SQLite ORM. Stores reminders, geofence coordinates/radius and alarm state in `app_database.db` (schema version 6); both the UI and background isolates open the same file.
- **`sqlite3_flutter_libs`** (version `^0.5.24`): Native SQLite binaries for target mobile platforms.
- **`drift_dev`** (dev dependency, version `2.14.1`): Code generator for Drift tables and queries (`app_database.g.dart`).
- **`path_provider`** (version `^2.1.5`): Locates the Application Documents Directory where the database file is created.
- **`flutter_secure_storage`** (version `^10.0.0`): Secure key-value storage for sensitive data (API keys, user credentials, etc.).
- **`shared_preferences`** (no specific version constraint, maps to latest available): Used for storing simple configuration settings and flags.

### Geolocation & Maps
- **`geolocator`** (version `^14.0.2`): Queries the device's location, monitors location updates, handles permission checks, and calculates distances between coordinates.
- **`mapbox_maps_flutter`** (version `^2.24.3`): Map rendering, camera controls, draggable geofence-radius handle and place annotations. Geocoding is done through Mapbox HTTP APIs via `dio`; the access token is loaded from `.env`.
- **Play Services Geofencing** (`play-services-location:21.3.0` in `android/app/build.gradle.kts`): System-owned arrival detection that survives process death; wired to Dart through a MethodChannel.

### Background Execution & Alerts
- **`flutter_background_service`** (version `^5.1.0`): Manages running Dart code in the background (as a foreground/background service). Essential for location monitoring when the app is suspended or terminated.
- **`flutter_local_notifications`** (version `^22.0.0`): Dispatches local notifications when the user triggers a geofence.
- **`audioplayers`** (version `^6.7.1`): Plays alert audio tracks synchronously when the location geofence condition is met.

### Network & Utilities
- **`dio`** (version `^5.9.2`): A powerful HTTP client for Dart, featuring interceptors, global configuration, and request cancellation.
- **`http`** (no specific version constraint): Standard HTTP client, utilized as fallback or interface adaptation.
- **`flutter_dotenv`** (version `^6.0.0`): Environment variable loader (from a `.env` file), keeping credentials like API keys out of code repositories.

### Model Generation & Serialization
- **`freezed_annotation`** (version `^2.4.4`) / **`freezed`** (dev dependency, version `^2.4.7`): Code generation package for defining immutable union types, pattern matching, and clone operations (`copyWith`).
- **`json_annotation`** (version `^4.9.0`) / **`json_serializable`** (dev dependency, version `any`): Automatically generates JSON serialization/deserialization code.

### UI & Presentation Components
- **`go_router`** (version `^17.1.0`): Declarative routing package for Flutter, facilitating URL-based navigation and deep linking.
- **`flutter_svg`** (version `^2.2.3`): Renders SVG icons.
- **`delightful_toast`** (version `^1.1.0`): Renders toast overlays and notifications in-app.
- **`skeletonizer`** (version `^2.1.3`): Automatically generates skeleton loading screens from actual widget layouts.
- **`animated_flip_counter`** (version `^0.3.4`): Animates transition changes for numbers.
- **`flutter_staggered_grid_view`** (version `^0.7.0`): Dynamic grid layout support.
- **`intl`** (version `^0.20.2`): Standard date, message, and number formatting.

### Security
- **`no_screenshot`** (version `^1.0.0`): Prevents screen recording and screenshot capture of sensitive app screens.

---

> [!NOTE]
> Dependency overrides are specified in `pubspec.yaml` to ensure build tool compatibility:
> - `analyzer: 5.12.0`
> - `dart_style: 2.3.2`
> - `build_resolvers: 2.2.0`
