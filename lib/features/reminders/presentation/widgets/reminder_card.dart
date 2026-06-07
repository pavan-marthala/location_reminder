import 'package:flutter/material.dart';
import 'package:reminders/core/theme/app_theme.dart';
import 'package:reminders/features/reminders/domain/entities/reminder_entity.dart';

class ReminderCard extends StatelessWidget {
  final ReminderEntity reminder;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const ReminderCard({
    super.key,
    required this.reminder,
    this.onToggle,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Dismissible(
      key: ValueKey(reminder.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: colors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline_rounded, color: colors.error, size: 28),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: reminder.isEnabled
                  ? colors.primary.withValues(alpha: 0.3)
                  : colors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.black.withValues(
                  alpha: context.isDark ? 0.15 : 0.04,
                ),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Left icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: reminder.isEnabled
                      ? colors.primary.withValues(alpha: 0.12)
                      : colors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: reminder.isEnabled
                      ? colors.primary
                      : colors.textTertiary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: typography.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: reminder.isEnabled
                            ? colors.textPrimary
                            : colors.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${reminder.latitude.toStringAsFixed(4)}, ${reminder.longitude.toStringAsFixed(4)} • ${reminder.radiusMeters.toInt()}m',
                      style: typography.bodySmall.copyWith(
                        color: colors.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Toggle switch
              Switch.adaptive(
                value: reminder.isEnabled,
                onChanged: onToggle,
                activeTrackColor: colors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
