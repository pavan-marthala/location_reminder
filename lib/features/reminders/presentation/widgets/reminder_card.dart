import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    final isDark = context.isDark;

    return Dismissible(
      key: ValueKey(reminder.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: colors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.error.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.delete_outline_rounded, color: colors.error, size: 28),
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: reminder.isEnabled
                  ? colors.primary.withValues(alpha: 0.4)
                  : colors.border,
              width: reminder.isEnabled ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.black.withValues(
                  alpha: isDark ? 0.3 : 0.06,
                ),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              if (reminder.isEnabled)
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // TOP SECTION: Location Icon, Title, Location details, and Toggle
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stylized Location Icon Container
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: reminder.isEnabled ? context.appGradients.primary : null,
                      color: reminder.isEnabled ? null : colors.surfaceDark.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: reminder.isEnabled
                          ? [
                              BoxShadow(
                                color: colors.primary.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : null,
                    ),
                    child: Icon(
                      Icons.pin_drop_rounded,
                      color: reminder.isEnabled ? colors.white : colors.textTertiary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Title & Location Description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.title,
                          style: typography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: reminder.isEnabled ? colors.textPrimary : colors.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          reminder.locationName ?? 'Selected Location',
                          style: typography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: reminder.isEnabled ? colors.textSecondary : colors.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (reminder.locationAddress != null && reminder.locationAddress!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            reminder.locationAddress!,
                            style: typography.bodySmall.copyWith(
                              color: colors.textTertiary,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Switch Toggle
                  Switch.adaptive(
                    value: reminder.isEnabled,
                    onChanged: onToggle,
                    activeTrackColor: colors.primary,
                    activeThumbColor: colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // MIDDLE SECTION: Radius & Status Badges
              Row(
                children: [
                  _buildRadiusChip(context, reminder.radiusMeters, reminder.isEnabled),
                  const SizedBox(width: 10),
                  _buildStatusBadge(context, reminder.status, reminder.isEnabled),
                ],
              ),
              const SizedBox(height: 14),
              // Divider
              Container(
                height: 1,
                color: colors.border.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              // BOTTOM SECTION: Created Date & Last Triggered
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 12, color: colors.textTertiary),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(reminder.createdAt),
                        style: typography.bodySmall.copyWith(
                          color: colors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  if (reminder.lastTriggeredAt != null)
                    Row(
                      children: [
                        Icon(Icons.notifications_active_rounded, size: 12, color: colors.textTertiary),
                        const SizedBox(width: 6),
                        Text(
                          'Last: ${_formatTime(reminder.lastTriggeredAt!)}',
                          style: typography.bodySmall.copyWith(
                            color: colors.textTertiary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
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
      return '${km.toStringAsFixed(1)} km';
    }
    return '${meters.toInt()} m';
  }

  String _formatDate(DateTime dt) {
    try {
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  String _formatTime(DateTime dt) {
    try {
      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      final hour = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$hour:$min';
    }
  }

  Widget _buildRadiusChip(BuildContext context, double radiusMeters, bool isEnabled) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isEnabled
            ? colors.primary.withValues(alpha: 0.1)
            : colors.surfaceDark.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled
              ? colors.primary.withValues(alpha: 0.15)
              : colors.border.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.adjust_rounded,
            size: 13,
            color: isEnabled ? colors.primary : colors.textTertiary,
          ),
          const SizedBox(width: 6),
          Text(
            _formatRadius(radiusMeters),
            style: typography.labelMedium.copyWith(
              color: isEnabled ? colors.primary : colors.textTertiary,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status, bool isEnabled) {
    final colors = context.appColors;
    final typography = context.appTypography;

    Color badgeColor;
    Color textColor;
    IconData icon;
    String label;

    if (!isEnabled) {
      if (status == 'completed') {
        badgeColor = colors.success.withValues(alpha: 0.12);
        textColor = colors.success;
        icon = Icons.check_circle_outline_rounded;
        label = 'Completed';
      } else {
        badgeColor = colors.surfaceDark.withValues(alpha: 0.5);
        textColor = colors.textTertiary;
        icon = Icons.remove_circle_outline_rounded;
        label = 'Disabled';
      }
    } else {
      switch (status) {
        case 'triggered':
          badgeColor = colors.error.withValues(alpha: 0.12);
          textColor = colors.error;
          icon = Icons.alarm_on_rounded;
          label = 'Triggered';
          break;
        case 'snoozed':
          badgeColor = Colors.orange.withValues(alpha: 0.12);
          textColor = Colors.orange;
          icon = Icons.snooze_rounded;
          label = 'Snoozed';
          break;
        case 'active':
        default:
          badgeColor = colors.primary.withValues(alpha: 0.12);
          textColor = colors.primary;
          icon = Icons.radar_rounded;
          label = 'Monitoring';
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: typography.labelMedium.copyWith(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
