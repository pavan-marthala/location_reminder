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
                    Text(
                      reminder.locationName ?? 'Selected Location',
                      style: typography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                        color: reminder.isEnabled
                            ? colors.textPrimary
                            : colors.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (reminder.locationAddress != null && reminder.locationAddress!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        reminder.locationAddress!,
                        style: typography.bodySmall.copyWith(
                          color: colors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'Radius: ${_formatRadius(reminder.radiusMeters)}',
                      style: typography.bodySmall.copyWith(
                        color: colors.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildStatusBadge(context, reminder.status, reminder.isEnabled),
                        if (reminder.lastTriggeredAt != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            'Last: ${_formatTime(reminder.lastTriggeredAt!)}',
                            style: typography.bodySmall.copyWith(
                              color: colors.textTertiary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
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

  String _formatRadius(double meters) {
    if (meters >= 1000) {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)}km';
    }
    return '${meters.toInt()}m';
  }

  Widget _buildStatusBadge(BuildContext context, String status, bool isEnabled) {
    final colors = context.appColors;

    Color badgeColor;
    Color textColor;
    String label;

    if (!isEnabled) {
      if (status == 'completed') {
        badgeColor = colors.success.withValues(alpha: 0.15);
        textColor = colors.success;
        label = 'Completed';
      } else {
        badgeColor = colors.textTertiary.withValues(alpha: 0.15);
        textColor = colors.textTertiary;
        label = 'Disabled';
      }
    } else {
      switch (status) {
        case 'triggered':
          badgeColor = colors.error.withValues(alpha: 0.15);
          textColor = colors.error;
          label = 'Triggered';
          break;
        case 'snoozed':
          badgeColor = Colors.orange.withValues(alpha: 0.15);
          textColor = Colors.orange;
          label = 'Snoozed';
          break;
        case 'active':
        default:
          badgeColor = colors.primary.withValues(alpha: 0.12);
          textColor = colors.primary;
          label = 'Monitoring';
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final sec = dt.second.toString().padLeft(2, '0');
    return '$hour:$min:$sec';
  }
}
