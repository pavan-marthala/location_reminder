import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reminders/core/theme/app_theme.dart';
import 'package:reminders/core/utils/app_button.dart';
import 'package:reminders/core/utils/app_toast.dart';
import 'package:reminders/core/di/injection.dart';
import 'package:reminders/generated/assets.dart';
import '../../../infrastructure_validation/presentation/bloc/validation_bloc.dart';
import '../../../infrastructure_validation/presentation/bloc/validation_event.dart';
import '../../../infrastructure_validation/presentation/bloc/validation_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<ValidationBloc>()..add(const ValidationEvent.initialize()),
      child: const _SettingsPageView(),
    );
  }
}

class _SettingsPageView extends StatelessWidget {
  const _SettingsPageView();

  String _getAlarmToneName(String? path) {
    if (path == null) return 'Daybreak';
    if (path.contains('Daybreak')) return 'Daybreak';
    if (path.contains('SlowMorning') || path.contains('Slow_Morning')) return 'Slow Morning';
    if (path.contains('Earth_Day') || path.contains('EarthDay')) return 'Earth Day';
    return path.split('/').last;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final gradients = context.appGradients;

    final List<Map<String, String>> availableTones = [
      {'path': Assets.audioDaybreak, 'name': 'Daybreak'},
      {'path': Assets.audioSlowmorning, 'name': 'Slow Morning'},
      {'path': Assets.audioTheWakeUpEarthDay, 'name': 'Earth Day'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: context.isDark ? gradients.backgroundDark : gradients.backgroundLight,
        ),
        child: BlocConsumer<ValidationBloc, ValidationState>(
          listener: (context, state) {
            if (state.errorMessage != null) {
              log(state.errorMessage ?? "");
              showErrorToast(message: state.errorMessage!);
            }
          },
          builder: (context, state) {
            if (state.isLoading && !state.isInitialized) {
              return Center(
                child: CircularProgressIndicator(color: colors.primary),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Permissions Section
                  _buildSectionHeader(context, 'Permissions'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildPermissionRow(
                            context,
                            'Notification Permission',
                            state.isNotificationPermissionGranted,
                            onAction: () => context.read<ValidationBloc>().add(
                              const ValidationEvent.requestNotificationPermission(),
                            ),
                          ),
                          const Divider(),
                          _buildPermissionRow(
                            context,
                            'Location Permission',
                            state.isLocationPermissionGranted,
                            onAction: () => context.read<ValidationBloc>().add(
                              const ValidationEvent.requestLocationPermission(),
                            ),
                          ),
                          const Divider(),
                          _buildPermissionRow(
                            context,
                            'Background Location',
                            state.isBackgroundLocationPermissionGranted,
                            onAction: () => context.read<ValidationBloc>().add(
                              const ValidationEvent.requestLocationPermission(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          AppButton(
                            width: double.infinity,
                            text: 'Open System Settings',
                            color: colors.primary,
                            onPressed: () {
                              context.read<ValidationBloc>().add(
                                const ValidationEvent.openAppSettings(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Alarm Settings
                  _buildSectionHeader(context, 'Alarm Settings'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected Alarm Tone',
                            style: typography.bodyMedium.copyWith(color: colors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: state.selectedAlarmTone != null &&
                                    availableTones.any((element) =>
                                        element['path'] == state.selectedAlarmTone)
                                ? state.selectedAlarmTone
                                : Assets.audioDaybreak,
                            items: availableTones.map((tone) {
                              return DropdownMenuItem<String>(
                                value: tone['path'],
                                child: Text(tone['name']!),
                              );
                            }).toList(),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: colors.border),
                              ),
                            ),
                            onChanged: (newValue) {
                              if (newValue != null) {
                                context.read<ValidationBloc>().add(
                                  ValidationEvent.changeAlarmTone(path: newValue),
                                );
                                showSuccessToast(message: 'Alarm tone updated to ${_getAlarmToneName(newValue)}');
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  text: state.isAlarmPlaying ? 'Stop Test Alarm' : 'Play Test Alarm',
                                  color: state.isAlarmPlaying ? colors.error : colors.success,
                                  onPressed: () {
                                    context.read<ValidationBloc>().add(
                                      state.isAlarmPlaying
                                          ? const ValidationEvent.stopAlarm()
                                          : const ValidationEvent.startAlarm(),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. Monitoring Settings
                  _buildSectionHeader(context, 'Monitoring Settings'),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: Text('Enable Monitoring', style: typography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                          subtitle: Text('Allow background checking for active reminders', style: typography.bodySmall.copyWith(color: colors.textTertiary)),
                          value: state.isMonitoringEnabled,
                          activeThumbColor: colors.primary,
                          onChanged: (val) {
                            context.read<ValidationBloc>().add(
                              ValidationEvent.toggleMonitoring(enabled: val),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(
                                state.isBackgroundServiceRunning
                                    ? Icons.play_circle_fill_rounded
                                    : Icons.pause_circle_filled_rounded,
                                color: state.isBackgroundServiceRunning
                                    ? colors.success
                                    : colors.textTertiary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Background Service Status',
                                      style: typography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      state.isBackgroundServiceRunning
                                          ? 'Running and ready'
                                          : 'Stopped',
                                      style: typography.bodySmall.copyWith(color: colors.textTertiary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4. Diagnostics Section
                  _buildSectionHeader(context, 'Developer Diagnostics'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppButton(
                            text: 'Test Notification',
                            color: colors.primary,
                            onPressed: () {
                              context.read<ValidationBloc>().add(
                                const ValidationEvent.triggerTestNotification(),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),
                          Text(
                            'Location Status Diagnostics',
                            style: typography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
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
                                child: AppButton(
                                  text: 'Get Current Location',
                                  color: colors.secondary,
                                  onPressed: () {
                                    context.read<ValidationBloc>().add(
                                      const ValidationEvent.fetchCurrentLocation(),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          AppButton(
                            width: double.infinity,
                            text: state.isLocationStreamActive
                                ? 'Stop Location Streaming'
                                : 'Start Location Streaming',
                            color: state.isLocationStreamActive ? colors.error : colors.accent2,
                            onPressed: () {
                              context.read<ValidationBloc>().add(
                                const ValidationEvent.toggleLocationStream(),
                              );
                            },
                          ),
                        ],
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

  Widget _buildPermissionRow(
    BuildContext context,
    String label,
    bool isGranted, {
    required VoidCallback onAction,
  }) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            isGranted ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isGranted ? colors.success : colors.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: typography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          if (!isGranted)
            TextButton(
              onPressed: onAction,
              child: Text(
                'Request',
                style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
              ),
            )
          else
            Text(
              'Granted',
              style: typography.bodySmall.copyWith(color: colors.success, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}
