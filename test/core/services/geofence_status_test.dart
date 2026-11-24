import 'package:flutter_test/flutter_test.dart';
import 'package:reminders/core/services/geofence_service.dart';

void main() {
  test('parses native sync and pending-arrival diagnostics', () {
    final status = GeofenceStatus.fromMap({
      'syncedCount': 4,
      'expectedCount': 4,
      'lastSyncAt': '2026-11-23T12:00:00.000+0000',
      'pendingId': 42,
      'pendingAgeSeconds': 17,
      'lastEventAt': '2026-11-23T11:59:00.000+0000',
      'lastEvent': 'Target entered for reminder 42',
      'lastError': '',
      'hasBackgroundLocation': true,
    });

    expect(status.syncedCount, 4);
    expect(status.expectedCount, 4);
    expect(status.lastSyncAt, '2026-11-23T12:00:00.000+0000');
    expect(status.pendingId, 42);
    expect(status.pendingAgeSeconds, 17);
    expect(status.lastEvent, 'Target entered for reminder 42');
    expect(status.hasBackgroundLocation, isTrue);
  });

  test('defaults new fields when native payload is older', () {
    final status = GeofenceStatus.fromMap({
      'syncedCount': 1,
      'lastEventAt': null,
      'lastEvent': null,
      'lastError': null,
      'hasBackgroundLocation': false,
    });

    expect(status.expectedCount, 1);
    expect(status.pendingId, isNull);
    expect(status.pendingAgeSeconds, isNull);
    expect(status.lastSyncAt, isNull);
  });
}
