import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:reminders/core/theme/app_theme.dart';
import 'package:reminders/core/utils/app_button.dart';
import 'package:reminders/core/utils/app_toast.dart';
import 'package:reminders/core/di/injection.dart';
import 'package:reminders/generated/assets.dart';
import '../../../infrastructure_validation/presentation/bloc/validation_bloc.dart';
import '../../../infrastructure_validation/presentation/bloc/validation_event.dart';
import '../../../infrastructure_validation/presentation/bloc/validation_state.dart';
import 'package:go_router/go_router.dart';
import 'package:reminders/core/routes/app_routes.dart';
import 'package:reminders/features/reminders/domain/entities/reminder_enums.dart';

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
    if (path.contains('SlowMorning') || path.contains('Slow_Morning')) {
      return 'Slow Morning';
    }
    if (path.contains('Earth_Day') || path.contains('EarthDay')) {
      return 'Earth Day';
    }
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
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: BlocConsumer<ValidationBloc, ValidationState>(
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

          // Expose monitoring status
          String monitoringStatus = 'Disabled';
          IconData statusIcon = Icons.remove_circle_outline_rounded;
          Color statusColor = colors.textTertiary;

          if (!state.isMonitoringEnabled) {
            monitoringStatus = 'Disabled';
            statusIcon = Icons.remove_circle_outline_rounded;
            statusColor = colors.textTertiary;
          } else if (!state.isBackgroundServiceRunning) {
            monitoringStatus = 'Stopped';
            statusIcon = Icons.pause_circle_filled_rounded;
            statusColor = colors.textTertiary;
          } else {
            if (state.backgroundReadinessState == 'WaitingForLocation') {
              monitoringStatus = 'Waiting for GPS';
              statusIcon = Icons.gps_not_fixed_rounded;
              statusColor = colors.warning;
            } else {
              monitoringStatus = 'Running';
              statusIcon = Icons.play_circle_fill_rounded;
              statusColor = colors.success;
            }
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

                // 2. Notifications Section
                _buildSectionHeader(context, 'Notifications'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alarm Tone',
                          style: typography.bodyMedium.copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value:
                              state.selectedAlarmTone != null &&
                                  availableTones.any(
                                    (element) =>
                                        element['path'] ==
                                        state.selectedAlarmTone,
                                  )
                              ? state.selectedAlarmTone
                              : Assets.audioDaybreak,
                          dropdownColor: colors.card,
                          borderRadius: BorderRadius.circular(16),
                          enableFeedback: true,
                          items: availableTones.map((tone) {
                            return DropdownMenuItem<String>(
                              value: tone['path'],
                              child: Text(tone['name']!),
                            );
                          }).toList(),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            filled: false,
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
                              showSuccessToast(
                                message:
                                    'Alarm tone updated to ${_getAlarmToneName(newValue)}',
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Vibration',
                            style: typography.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Vibrate when alarms trigger',
                            style: typography.bodySmall.copyWith(
                              color: colors.textTertiary,
                            ),
                          ),
                          value: state.isVibrationEnabled,
                          activeThumbColor: colors.primary,
                          onChanged: (val) {
                            context.read<ValidationBloc>().add(
                              ValidationEvent.toggleVibration(enabled: val),
                            );
                          },
                        ),
                        if (state.isVibrationEnabled) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Vibration Pattern',
                            style: typography.bodyMedium.copyWith(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<VibrationPattern>(
                            value: state.selectedVibrationPattern,
                            dropdownColor: colors.card,
                            borderRadius: BorderRadius.circular(16),
                            items: VibrationPattern.values.map((pat) {
                              return DropdownMenuItem<VibrationPattern>(
                                value: pat,
                                child: Text(pat.displayName),
                              );
                            }).toList(),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: colors.border),
                              ),
                            ),
                            onChanged: (newPattern) {
                              if (newPattern != null) {
                                context.read<ValidationBloc>().add(
                                  ValidationEvent.changeVibrationPattern(
                                    pattern: newPattern,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                text: state.isAlarmPlaying
                                    ? 'Stop Test Alarm'
                                    : 'Play Test Alarm',
                                color: state.isAlarmPlaying
                                    ? colors.error
                                    : colors.success,
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
                _buildSectionHeader(context, 'Monitoring'),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: Text(
                          'Enable Monitoring',
                          style: typography.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Allow background checking for active reminders',
                          style: typography.bodySmall.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
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
                            Icon(statusIcon, color: statusColor, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Status',
                                    style: typography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    monitoringStatus,
                                    style: typography.bodySmall.copyWith(
                                      color: colors.textTertiary,
                                    ),
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

                // 4. About Section
                _buildSectionHeader(context, 'About'),
                Card(
                  child: FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      final version = snapshot.data?.version ?? '1.0.0';
                      final buildNumber = snapshot.data?.buildNumber ?? '1';

                      return Column(
                        children: [
                          ListTile(
                            title: Text(
                              'App Version',
                              style: typography.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: Text(
                              version,
                              style: typography.bodyMedium.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            title: Text(
                              'Build Number',
                              style: typography.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: Text(
                              buildNumber,
                              style: typography.bodyMedium.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            title: Text(
                              'Privacy Policy',
                              style: typography.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () {
                              showSuccessToast(
                                message: 'Privacy Policy placeholder tapped.',
                              );
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            title: Text(
                              'Open Source Licenses',
                              style: typography.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () {
                              showLicensePage(context: context);
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Developer Tools (kDebugMode only)
                if (kDebugMode) ...[
                  _buildSectionHeader(context, 'Developer Tools'),
                  Card(
                    child: ListTile(
                      title: Text(
                        'Developer Tools',
                        style: typography.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Expose coordinates, distance, geofences, and evaluation logs',
                        style: typography.bodySmall.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        context.push(AppRoutes.developerTools);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          );
        },
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
              style: typography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!isGranted)
            TextButton(
              onPressed: onAction,
              child: Text(
                'Request',
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Text(
              'Granted',
              style: typography.bodySmall.copyWith(
                color: colors.success,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}
