import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:reminders/core/di/injection.dart';
import 'package:reminders/core/theme/app_theme.dart';
import 'package:reminders/core/services/alarm_service.dart';
import 'package:reminders/core/services/monitoring_coordinator.dart';
import 'package:reminders/features/reminders/domain/entities/reminder_entity.dart';
import 'package:reminders/features/reminders/domain/repositories/reminder_repository.dart';

class AlarmPage extends StatefulWidget {
  final int reminderId;
  final String reminderTitle;

  const AlarmPage({
    super.key,
    required this.reminderId,
    required this.reminderTitle,
  });

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  ReminderEntity? _reminder;
  bool _isLoading = true;
  Timer? _clockTimer;
  String _timeString = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _timeString = _formatCurrentTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _timeString = _formatCurrentTime();
        });
      }
    });

    _loadReminder();
  }

  String _formatCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }

  Future<void> _loadReminder() async {
    try {
      final repo = getIt<ReminderRepository>();
      final reminder = await repo.getReminderById(widget.reminderId);
      if (mounted) {
        setState(() {
          _reminder = reminder;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _onDismiss() async {
    if (_reminder == null) {
      context.pop();
      return;
    }

    final updated = _reminder!.copyWith(
      status: 'completed',
      isEnabled: false,
      isTriggered: false,
      completedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await getIt<ReminderRepository>().updateReminder(updated);
    await getIt<AlarmService>().stopAlarm();
    await getIt<MonitoringCoordinator>().evaluateMonitoringState();

    if (mounted) {
      context.pop(true);
    }
  }

  Future<void> _onSnooze(int minutes) async {
    if (_reminder == null) {
      context.pop();
      return;
    }

    final updated = _reminder!.copyWith(
      status: 'snoozed',
      isTriggered: false,
      snoozedUntil: DateTime.now().add(Duration(minutes: minutes)),
      updatedAt: DateTime.now(),
    );

    await getIt<ReminderRepository>().updateReminder(updated);
    await getIt<AlarmService>().stopAlarm();
    await getIt<MonitoringCoordinator>().evaluateMonitoringState();

    if (mounted) {
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: context.isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                // Digital Clock Display
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: context.isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _timeString,
                      style: typography.displayMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                        color: colors.textPrimary,
                        fontSize: 48,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Pulsing Travel Icon
                Center(
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.95, end: 1.05).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: Curves.easeInOut,
                      ),
                    ),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.primary.withValues(alpha: 0.4),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.15),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.near_me_rounded,
                        size: 44,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Header Label
                Text(
                  'Destination Reached'.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: typography.labelLarge.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3.0,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                // Location Details Card
                Card(
                  elevation: 0,
                  color: context.isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: colors.border.withValues(alpha: 0.5)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Text(
                          _reminder?.title ?? widget.reminderTitle,
                          textAlign: TextAlign.center,
                          style: typography.headlineMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        if (_reminder?.locationName != null || _reminder?.locationAddress != null) ...[
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          if (_reminder?.locationName != null) ...[
                            Text(
                              _reminder!.locationName!,
                              textAlign: TextAlign.center,
                              style: typography.bodyLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          if (_reminder?.locationAddress != null)
                            Text(
                              _reminder!.locationAddress!,
                              textAlign: TextAlign.center,
                              style: typography.bodyMedium.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                        ],
                        if (_reminder?.description != null && _reminder!.description!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            _reminder!.description!,
                            textAlign: TextAlign.center,
                            style: typography.bodySmall.copyWith(
                              color: colors.textTertiary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // Actions Area
                if (_isLoading)
                  Center(
                    child: CircularProgressIndicator(color: colors.primary),
                  )
                else ...[
                  // Dismiss Button
                  ElevatedButton(
                    onPressed: _onDismiss,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'ARRIVED & DISMISS',
                      style: typography.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Snooze Dropdown/Menu Button
                  OutlinedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: colors.card,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        builder: (context) {
                          return SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Snooze Alarm',
                                    style: typography.titleLarge.copyWith(
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  ListTile(
                                    leading: Icon(Icons.snooze_rounded, color: colors.primary),
                                    title: Text('Snooze for 2 Minutes', style: TextStyle(color: colors.textPrimary)),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _onSnooze(2);
                                    },
                                  ),
                                  const Divider(),
                                  ListTile(
                                    leading: Icon(Icons.snooze_rounded, color: colors.primary),
                                    title: Text('Snooze for 5 Minutes', style: TextStyle(color: colors.textPrimary)),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _onSnooze(5);
                                    },
                                  ),
                                  const Divider(),
                                  ListTile(
                                    leading: Icon(Icons.snooze_rounded, color: colors.primary),
                                    title: Text('Snooze for 10 Minutes', style: TextStyle(color: colors.textPrimary)),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _onSnooze(10);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.primary,
                      side: BorderSide(color: colors.primary.withValues(alpha: 0.5), width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'SNOOZE FOR LATER',
                      style: typography.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
