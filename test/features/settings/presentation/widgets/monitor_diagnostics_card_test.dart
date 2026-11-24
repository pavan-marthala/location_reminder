import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminders/core/services/geofence_service.dart';
import 'package:reminders/features/settings/presentation/widgets/monitor_diagnostics_card.dart';

void main() {
  Widget buildCard(MonitorDiagnostics diagnostics) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: MonitorDiagnosticsCard(diagnostics: diagnostics),
        ),
      ),
    );
  }

  testWidgets('renders fence, readiness and pending arrival fields',
      (tester) async {
    final status = GeofenceStatus(
      syncedCount: 3,
      expectedCount: 3,
      lastSyncAt: DateTime.now().toIso8601String(),
      pendingId: 42,
      pendingAgeSeconds: 12,
      lastEventAt: DateTime.now().toIso8601String(),
      lastEvent: 'Target entered for reminder 42',
      lastError: null,
      hasBackgroundLocation: true,
    );

    await tester.pumpWidget(buildCard(MonitorDiagnostics(
      geofence: status,
      heartbeatAt: DateTime.now().toIso8601String(),
      backgroundState: 'MonitoringActive',
      monitoringEnabled: true,
      foregroundServiceRunning: true,
      notificationGranted: true,
      backgroundLocationGranted: true,
    )));

    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('3'), findsNWidgets(2));
    expect(find.textContaining('#42'), findsOneWidget);
    expect(find.text('Target entered for reminder 42'), findsOneWidget);
    expect(find.textContaining('stale'), findsNothing);
  });

  testWidgets('warns when heartbeat is stale for active reminders',
      (tester) async {
    final status = GeofenceStatus(
      syncedCount: 1,
      expectedCount: 1,
      lastSyncAt: null,
      pendingId: null,
      pendingAgeSeconds: null,
      lastEventAt: null,
      lastEvent: null,
      lastError: 'addGeofences failed',
      hasBackgroundLocation: false,
    );

    await tester.pumpWidget(buildCard(MonitorDiagnostics(
      geofence: status,
      heartbeatAt: DateTime.now()
          .subtract(const Duration(minutes: 25))
          .toIso8601String(),
      backgroundState: 'Error',
      monitoringEnabled: true,
      foregroundServiceRunning: true,
      notificationGranted: false,
      backgroundLocationGranted: false,
    )));

    expect(find.text('Blocked'), findsOneWidget);
    expect(find.text('Missing'), findsNWidgets(2));
    expect(find.text('addGeofences failed'), findsOneWidget);
    expect(find.textContaining('heartbeat is stale'), findsOneWidget);
  });
}
