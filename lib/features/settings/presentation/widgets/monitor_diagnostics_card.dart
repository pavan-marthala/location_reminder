import 'package:flutter/material.dart';
import 'package:reminders/core/services/geofence_service.dart';

/// Inputs for [MonitorDiagnosticsCard], kept public so it can be unit tested
/// with a fake geofence status.
class MonitorDiagnostics {
  final GeofenceStatus? geofence;
  final String? heartbeatAt;
  final String? backgroundState;
  final bool monitoringEnabled;
  final bool foregroundServiceRunning;
  final bool notificationGranted;
  final bool backgroundLocationGranted;

  const MonitorDiagnostics({
    this.geofence,
    this.heartbeatAt,
    this.backgroundState,
    this.monitoringEnabled = true,
    this.foregroundServiceRunning = false,
    this.notificationGranted = true,
    this.backgroundLocationGranted = true,
  });

  bool get isReady =>
      monitoringEnabled &&
      foregroundServiceRunning &&
      notificationGranted &&
      backgroundLocationGranted;

  bool get isHeartbeatStale {
    final expected = geofence?.expectedCount ?? 0;
    if (expected <= 0 || heartbeatAt == null || heartbeatAt!.isEmpty) {
      return false;
    }
    final parsed = DateTime.tryParse(heartbeatAt!);
    if (parsed == null) return true;
    return DateTime.now().difference(parsed) > const Duration(minutes: 10);
  }
}

/// User-visible health of background arrival detection.
class MonitorDiagnosticsCard extends StatelessWidget {
  final MonitorDiagnostics diagnostics;
  final VoidCallback? onRefresh;

  const MonitorDiagnosticsCard({
    super.key,
    required this.diagnostics,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final geofence = diagnostics.geofence;

    String age(String? raw) {
      if (raw == null || raw.isEmpty) return 'Never';
      final parsed = DateTime.tryParse(raw);
      if (parsed == null) return raw;
      final diff = DateTime.now().difference(parsed);
      if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    }

    String flag(bool value) => value ? 'Granted' : 'Missing';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _row('Readiness', diagnostics.isReady ? 'Ready' : 'Blocked',
                valueColor: diagnostics.isReady ? colors.primary : colors.error),
            const Divider(),
            _row('Monitoring Enabled', flag(diagnostics.monitoringEnabled)),
            const Divider(),
            _row('Foreground Service',
                diagnostics.foregroundServiceRunning ? 'Running' : 'Stopped'),
            const Divider(),
            _row('Notification Permission',
                flag(diagnostics.notificationGranted),
                valueColor: diagnostics.notificationGranted
                    ? null
                    : colors.error),
            const Divider(),
            _row('Background Location',
                flag(diagnostics.backgroundLocationGranted),
                valueColor: diagnostics.backgroundLocationGranted
                    ? null
                    : colors.error),
            const Divider(),
            _row('Last Heartbeat', age(diagnostics.heartbeatAt),
                valueColor: diagnostics.isHeartbeatStale
                    ? colors.error
                    : colors.primary),
            const Divider(),
            _row('Background State',
                (diagnostics.backgroundState ?? 'Unknown').toUpperCase()),
            const Divider(),
            _row('Geofences Registered', '${geofence?.syncedCount ?? 0}'),
            const Divider(),
            _row('Geofences Expected', '${geofence?.expectedCount ?? 0}'),
            const Divider(),
            _row('Last Geofence Sync', age(geofence?.lastSyncAt)),
            const Divider(),
            _row(
              'Pending Arrival',
              geofence?.pendingId == null
                  ? 'None'
                  : '#${geofence!.pendingId} (${geofence.pendingAgeSeconds ?? 0}s ago)',
            ),
            const Divider(),
            _row('Last Geofence Event', geofence?.lastEvent ?? 'None'),
            if ((geofence?.lastEventAt ?? '').isNotEmpty) ...[
              const Divider(),
              _row('Last Event At', age(geofence?.lastEventAt)),
            ],
            if ((geofence?.lastError ?? '').isNotEmpty) ...[
              const Divider(),
              _row('Geofence Error', geofence!.lastError!,
                  valueColor: colors.error),
            ],
            if (diagnostics.isHeartbeatStale) ...[
              const SizedBox(height: 12),
              const Text(
                'Live monitor heartbeat is stale. System geofences may still '
                'detect arrival; reopen the app to restore live monitoring.',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ],
            if (onRefresh != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh Diagnostics'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(fontWeight: FontWeight.bold, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}
