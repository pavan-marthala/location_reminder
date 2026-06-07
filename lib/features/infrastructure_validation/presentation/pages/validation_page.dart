import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reminders/core/theme/app_theme.dart';
import 'package:reminders/core/utils/app_button.dart';
import 'package:reminders/core/utils/app_toast.dart';
import 'package:reminders/core/di/injection.dart';
import '../bloc/validation_bloc.dart';
import '../bloc/validation_event.dart';
import '../bloc/validation_state.dart';

class ValidationPage extends StatelessWidget {
  const ValidationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ValidationBloc>()..add(const ValidationEvent.initialize()),
      child: const _ValidationPageView(),
    );
  }
}

class _ValidationPageView extends StatelessWidget {
  const _ValidationPageView();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Infrastructure Validation'),
        centerTitle: true,
      ),
      body: BlocConsumer<ValidationBloc, ValidationState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            showErrorToast(message: state.errorMessage!);
          }
        },
        builder: (context, state) {
          if (state.isLoading && !state.isInitialized) {
            return Center(
              child: CircularProgressIndicator(
                color: colors.primary,
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, state),
                const SizedBox(height: 16),
                _buildNotificationCard(context, state),
                const SizedBox(height: 16),
                _buildLocationCard(context, state),
                const SizedBox(height: 16),
                _buildAlarmCard(context, state),
                const SizedBox(height: 16),
                _buildBackgroundServiceCard(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ValidationState state) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: context.appGradients.glassOverlay,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Validation Status',
            style: typography.titleLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                state.isInitialized ? Icons.check_circle : Icons.error,
                color: state.isInitialized ? colors.success : colors.error,
              ),
              const SizedBox(width: 8),
              Text(
                state.isInitialized
                    ? 'All Services Initialized'
                    : 'Services Uninitialized',
                style: typography.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, ValidationState state) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Local Notifications', style: typography.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Request Perms',
                    color: colors.primary,
                    onPressed: () {
                      context
                          .read<ValidationBloc>()
                          .add(const ValidationEvent.requestNotificationPermission());
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    text: 'Trigger Test',
                    color: colors.secondary,
                    onPressed: () {
                      context
                          .read<ValidationBloc>()
                          .add(const ValidationEvent.triggerTestNotification());
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context, ValidationState state) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('2. Location Services', style: typography.titleMedium),
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
                    text: 'Location Perm',
                    color: colors.primary,
                    onPressed: () {
                      context
                          .read<ValidationBloc>()
                          .add(const ValidationEvent.requestLocationPermission());
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    text: 'Get Location',
                    color: colors.secondary,
                    onPressed: () {
                      context
                          .read<ValidationBloc>()
                          .add(const ValidationEvent.fetchCurrentLocation());
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AppButton(
              width: double.infinity,
              text: state.isLocationStreamActive
                  ? 'Stop Location Stream'
                  : 'Start Location Stream',
              color: state.isLocationStreamActive ? colors.error : colors.accent2,
              onPressed: () {
                context
                    .read<ValidationBloc>()
                    .add(const ValidationEvent.toggleLocationStream());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlarmCard(BuildContext context, ValidationState state) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('3. Alarm System', style: typography.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  state.isAlarmPlaying ? Icons.volume_up : Icons.volume_off,
                  color: state.isAlarmPlaying ? colors.success : colors.textTertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  state.isAlarmPlaying ? 'Alarm Playing (Looping)' : 'Alarm Muted',
                  style: typography.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Play Alarm',
                    color: colors.success,
                    onPressed: () {
                      context
                          .read<ValidationBloc>()
                          .add(const ValidationEvent.startAlarm());
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    text: 'Stop Alarm',
                    color: colors.error,
                    onPressed: () {
                      context
                          .read<ValidationBloc>()
                          .add(const ValidationEvent.stopAlarm());
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundServiceCard(BuildContext context, ValidationState state) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('4. Background Service', style: typography.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  state.isBackgroundServiceRunning
                      ? Icons.play_circle_fill
                      : Icons.pause_circle_filled,
                  color: state.isBackgroundServiceRunning ? colors.success : colors.textTertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  state.isBackgroundServiceRunning
                      ? 'Foreground Service Running'
                      : 'Background Service Stopped',
                  style: typography.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (state.latestBackgroundTick != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  state.latestBackgroundTick!,
                  style: typography.bodyMedium.copyWith(
                    fontFamily: 'Courier',
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            AppButton(
              width: double.infinity,
              text: state.isBackgroundServiceRunning
                  ? 'Stop Foreground Service'
                  : 'Start Foreground Service',
              color: state.isBackgroundServiceRunning ? colors.error : colors.primary,
              onPressed: () {
                context
                    .read<ValidationBloc>()
                    .add(const ValidationEvent.toggleBackgroundService());
              },
            ),
          ],
        ),
      ),
    );
  }
}
