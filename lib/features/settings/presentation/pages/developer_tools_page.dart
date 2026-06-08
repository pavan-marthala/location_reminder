import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reminders/core/di/injection.dart';
import 'package:reminders/core/theme/app_theme.dart';
import 'package:reminders/core/services/background_service.dart';
import 'package:reminders/features/infrastructure_validation/presentation/bloc/validation_bloc.dart';
import 'package:reminders/features/infrastructure_validation/presentation/bloc/validation_event.dart';
import 'package:reminders/features/infrastructure_validation/presentation/bloc/validation_state.dart';

class DeveloperToolsPage extends StatelessWidget {
  const DeveloperToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<ValidationBloc>()..add(const ValidationEvent.initialize()),
      child: const _DeveloperToolsPageView(),
    );
  }
}

class _DeveloperToolsPageView extends StatefulWidget {
  const _DeveloperToolsPageView();

  @override
  State<_DeveloperToolsPageView> createState() => _DeveloperToolsPageViewState();
}

class _DeveloperToolsPageViewState extends State<_DeveloperToolsPageView> {
  final List<String> _localLogs = [];
  Map<String, dynamic>? _latestUpdates;
  StreamSubscription? _updatesSubscription;

  @override
  void initState() {
    super.initState();
    // Check initial running status
    getIt<BackgroundService>().isRunning().then((running) {
      if (mounted) {
        setState(() {
          if (!running) {
            _latestUpdates = {
              'status': 'stopped',
              'readinessState': 'Stopped',
              'activeCount': 0,
            };
          } else {
            _latestUpdates = {
              'status': 'running',
              'readinessState': 'MonitoringActive',
            };
          }
        });
      }
    });

    // Subscribe to logs stream to collect them dynamically for display
    _updatesSubscription = getIt<BackgroundService>().backgroundUpdates.listen((event) {
      if (event != null && mounted) {
        final time = event['time'] as String? ?? DateTime.now().toIso8601String();
        final timeParsed = DateTime.tryParse(time) ?? DateTime.now();
        final timeStr = '${timeParsed.hour.toString().padLeft(2, '0')}:${timeParsed.minute.toString().padLeft(2, '0')}:${timeParsed.second.toString().padLeft(2, '0')}';
        
        setState(() {
          _latestUpdates = event;
          if (event['status'] == 'state_change') {
            _localLogs.add('[$timeStr] STATE: ${event['readinessState']} (${event['details'] ?? 'no details'})');
          } else if (event['status'] == 'triggered') {
            _localLogs.add('[$timeStr] TRIGGER: Entered geofence for reminder ID ${event['reminderId']}');
          } else if (event['status'] == 'running') {
            _localLogs.add('[$timeStr] EVAL: Coordinates ${event['latitude']?.toStringAsFixed(5)}, ${event['longitude']?.toStringAsFixed(5)} | Nearest: ${event['nearestReminder'] ?? 'none'} (${event['nearestDistance']?.toStringAsFixed(1) ?? '0'}m away)');
          } else if (event['status'] == 'error') {
            _localLogs.add('[$timeStr] ERROR: ${event['error']}');
          } else if (event['status'] == 'stopped') {
            _localLogs.add('[$timeStr] SERVICE: Foreground location monitor stopped');
          } else if (event['status'] == 'starting') {
            _localLogs.add('[$timeStr] SERVICE: Foreground location monitor starting');
          }
          // Limit to last 50 logs
          if (_localLogs.length > 50) {
            _localLogs.removeAt(0);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _updatesSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final gradients = context.appGradients;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Tools'),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: context.isDark ? gradients.backgroundDark : gradients.backgroundLight,
        ),
        child: BlocBuilder<ValidationBloc, ValidationState>(
          builder: (context, state) {
            final data = _latestUpdates;
            final isStopped = data?['readinessState'] == 'Stopped' || data?['status'] == 'stopped' || !state.isBackgroundServiceRunning;
            
            final readiness = isStopped ? 'Stopped' : (data?['readinessState'] ?? 'MonitoringActive');
            final activeCount = isStopped ? 0 : (data?['activeCount'] ?? 0);
            final nearestName = isStopped ? 'None' : (data?['nearestReminder'] ?? 'None');
            final nearestDist = isStopped ? 'N/A' : (data?['nearestDistance'] != null ? '${(data!['nearestDistance'] as double).toStringAsFixed(1)}m' : 'N/A');
            final lastLocation = isStopped ? 'N/A' : (data?['latitude'] != null ? '${data?['latitude']?.toStringAsFixed(5)}, ${data?['longitude']?.toStringAsFixed(5)}' : 'N/A');
            final lastEval = isStopped ? 'N/A' : (data?['time'] != null ? '${DateTime.tryParse(data!['time'] as String)?.toLocal().toString().split(' ').last.split('.').first}' : 'N/A');
            final reminderStatus = isStopped ? 'Inactive' : (data?['status'] ?? 'Monitoring');

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Section 1: Live Monitoring Status
                  _buildSectionHeader(context, 'Monitoring Status'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildDiagnosticRow('Monitoring State', readiness.toString().toUpperCase(), valueColor: isStopped ? colors.textTertiary : colors.primary),
                          const Divider(),
                          _buildDiagnosticRow('Active Reminder Count', '$activeCount'),
                          const Divider(),
                          _buildDiagnosticRow('Current Reminder', nearestName),
                          const Divider(),
                          _buildDiagnosticRow('Last Location Update', lastLocation),
                          const Divider(),
                          _buildDiagnosticRow('Last Geofence Evaluation', lastEval),
                          const Divider(),
                          _buildDiagnosticRow('Current Distance', nearestDist),
                          const Divider(),
                          _buildDiagnosticRow('Reminder Status', reminderStatus.toString().toUpperCase(), valueColor: reminderStatus == 'triggered' ? colors.error : colors.secondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 2: GPS Diagnostics
                  _buildSectionHeader(context, 'GPS coordinates'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.border),
                            ),
                            child: Text(
                              state.currentCoordinates ?? 'Coordinates: Not Fetched',
                              style: typography.bodyMedium.copyWith(
                                fontFamily: 'Courier',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.location_searching_rounded),
                                  label: const Text('Fetch Current Location'),
                                  onPressed: () {
                                    context.read<ValidationBloc>().add(
                                      const ValidationEvent.fetchCurrentLocation(),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: colors.primary,
                                    side: BorderSide(color: colors.primary),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 3: Monitoring & Geofence Logs Terminal
                  _buildSectionHeader(context, 'Diagnostics Logs & Evaluations'),
                  Card(
                    color: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Colors.white24),
                    ),
                    child: Container(
                      height: 260,
                      padding: const EdgeInsets.all(12.0),
                      child: _localLogs.isEmpty
                          ? Center(
                              child: Text(
                                'Waiting for geofence evaluation stream logs...',
                                style: typography.bodySmall.copyWith(color: Colors.white54, fontFamily: 'Courier'),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _localLogs.length,
                              itemBuilder: (context, index) {
                                final logLine = _localLogs[_localLogs.length - 1 - index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                                  child: Text(
                                    logLine,
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontFamily: 'Courier',
                                      fontSize: 11,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: typography.bodySmall.copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDiagnosticRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
