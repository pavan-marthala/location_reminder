import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:reminders/core/di/injection.dart';
import 'package:reminders/core/routes/app_routes.dart';
import 'package:reminders/core/theme/app_theme.dart';
import 'package:reminders/core/utils/app_toast.dart';
import 'package:reminders/core/services/background_service.dart';
import '../bloc/reminder_bloc.dart';
import '../bloc/reminder_event.dart';
import '../bloc/reminder_state.dart';
import '../widgets/reminder_card.dart';

class ReminderListPage extends StatelessWidget {
  const ReminderListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<ReminderBloc>()..add(const ReminderEvent.loadReminders()),
      child: const _ReminderListView(),
    );
  }
}

class _ReminderListView extends StatelessWidget {
  const _ReminderListView();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final gradients = context.appGradients;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: context.isDark
              ? gradients.backgroundDark
              : gradients.backgroundLight,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Reminders',
                      style: typography.titleLarge.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.settings_rounded),
                          tooltip: 'Settings',
                          color: colors.textTertiary,
                          onPressed: () =>
                              context.push(AppRoutes.settings),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: BlocConsumer<ReminderBloc, ReminderState>(
                  listener: (context, state) {
                    if (state is ReminderError) {
                      showErrorToast(message: state.message);
                    }
                  },
                  builder: (context, state) {
                    return state.when(
                      initial: () => const SizedBox.shrink(),
                      loading: () => Center(
                        child: CircularProgressIndicator(
                          color: colors.primary,
                        ),
                      ),
                      loaded: (reminders) => RefreshIndicator(
                        onRefresh: () async {
                          context
                              .read<ReminderBloc>()
                              .add(const ReminderEvent.loadReminders());
                        },
                        color: colors.primary,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                          itemCount: reminders.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final reminder = reminders[index];
                            return ReminderCard(
                              reminder: reminder,
                              onToggle: (enabled) {
                                context.read<ReminderBloc>().add(
                                      ReminderEvent.toggleReminder(
                                        id: reminder.id!,
                                        isEnabled: enabled,
                                      ),
                                    );
                              },
                              onDelete: () {
                                context.read<ReminderBloc>().add(
                                      ReminderEvent.deleteReminder(
                                        id: reminder.id!,
                                      ),
                                    );
                                showSuccessToast(
                                  message: '${reminder.title} deleted',
                                );
                              },
                              onTap: () async {
                                final result = await context.push<bool>(
                                  AppRoutes.editReminder,
                                  extra: reminder,
                                );
                                if (result == true && context.mounted) {
                                  context.read<ReminderBloc>().add(
                                        const ReminderEvent.loadReminders(),
                                      );
                                }
                              },
                            );
                          },
                        ),
                      ),
                      empty: () => _buildEmptyState(context),
                      error: (message) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline_rounded,
                                  size: 48, color: colors.error),
                              const SizedBox(height: 16),
                              Text(
                                message,
                                style: typography.bodyMedium.copyWith(
                                  color: colors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.push<bool>(AppRoutes.createReminder);
          if (result == true && context.mounted) {
            context
                .read<ReminderBloc>()
                .add(const ReminderEvent.loadReminders());
          }
        },
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text(
          'New Reminder',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_location_alt_rounded,
                size: 40,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Reminders Yet',
              style: typography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to create\nyour first location reminder.',
              textAlign: TextAlign.center,
              style: typography.bodyMedium.copyWith(
                color: colors.textTertiary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
