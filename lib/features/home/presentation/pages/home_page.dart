import 'package:flutter/material.dart';
import 'package:reminders/core/theme/app_theme.dart';
import 'package:reminders/core/utils/app_button.dart';
import 'package:go_router/go_router.dart';
import 'package:reminders/core/routes/app_routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final gradients = context.appGradients;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: context.isDark ? gradients.backgroundDark : gradients.backgroundLight,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Location Reminder',
                      style: typography.titleLarge.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    // Developer/Testing shortcut button
                    IconButton(
                      icon: const Icon(Icons.developer_mode_rounded),
                      tooltip: 'Developer Settings',
                      color: colors.primary,
                      onPressed: () {
                        context.push(AppRoutes.validation);
                      },
                    ),
                  ],
                ),
                const Spacer(),
                // Main Info card
                Container(
                  padding: const EdgeInsets.all(28.0),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: colors.border),
                    boxShadow: [
                      BoxShadow(
                        color: colors.black.withValues(alpha: context.isDark ? 0.2 : 0.05),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.task_alt_rounded,
                          size: 36,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Setup Validated',
                        style: typography.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Infrastructure setup completed.\nReminder functionality coming soon.',
                        textAlign: TextAlign.center,
                        style: typography.bodyMedium.copyWith(
                          color: colors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Custom AppButton back to Validation page if needed
                AppButton(
                  width: double.infinity,
                  text: 'Open Validation Tools',
                  color: colors.primary,
                  onPressed: () {
                    context.push(AppRoutes.validation);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
