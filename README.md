# reminders

A Flutter location-reminder app. Create a reminder, pick a place and a geofence radius on the map, and the app alerts you when you arrive.

## Geofence radius

- Supported radius range: **150 m to 10 km**. The map picker constrains the radius handle to this range, and the same value is stored and registered as the Android geofence.
- Upgrading from an earlier version runs a one-time migration (database schema version 6) that raises any stored radius below 150 m to 150 m. This matches the 150 m floor the native geofence has always enforced, so the alarm now fires at the radius shown in the UI.
- Android Play Services allows at most 100 geofences per app. When more than 50 reminders are active, only the target fence per reminder is registered (the 10 km "approach" fence is skipped).

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
