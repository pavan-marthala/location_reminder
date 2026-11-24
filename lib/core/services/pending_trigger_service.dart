import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A geofence arrival recorded by the native receiver for the Flutter isolate.
class PendingTriggerEnvelope {
  final int reminderId;
  final DateTime writtenAt;

  const PendingTriggerEnvelope({
    required this.reminderId,
    required this.writtenAt,
  });
}

/// Reads and clears the hand-off written by the native geofence receiver.
///
/// The native side uses the same `FlutterSharedPreferences` store as the
/// `shared_preferences` plugin, so no extra MethodChannel is needed.
class PendingTriggerService {
  static const String keyId = 'pending_geofence_trigger_id';
  static const String keyAt = 'pending_geofence_trigger_at';
  static const Duration maxAge = Duration(minutes: 10);

  final SharedPreferences _prefs;

  PendingTriggerService(this._prefs);

  /// Returns the pending arrival, or null when none is recorded or the
  /// arrival is too old to be worth ringing (for example a late fence replay
  /// after a reboot).
  Future<PendingTriggerEnvelope?> readFresh({DateTime? now}) async {
    final id = _prefs.getInt(keyId);
    if (id == null || id <= 0) return null;

    final nowValue = now ?? DateTime.now();
    final rawAt = _prefs.getString(keyAt);
    final writtenAt = rawAt == null ? null : DateTime.tryParse(rawAt);
    if (writtenAt != null && nowValue.difference(writtenAt) > maxAge) {
      debugPrint('[GEOFENCE] Discarding stale pending trigger $id');
      await clear();
      return null;
    }

    return PendingTriggerEnvelope(
      reminderId: id,
      writtenAt: writtenAt ?? nowValue,
    );
  }

  Future<void> clear() async {
    await _prefs.remove(keyId);
    await _prefs.remove(keyAt);
  }

  /// Clears only a specific id, used when the live evaluator wins the race.
  Future<void> clearId(int reminderId) async {
    if (_prefs.getInt(keyId) != reminderId) return;
    await clear();
  }
}
