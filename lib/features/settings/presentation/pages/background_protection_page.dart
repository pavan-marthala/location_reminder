import 'package:flutter/material.dart';
import 'package:reminders/core/di/injection.dart';
import 'package:reminders/core/services/background_protection_service.dart';
import 'package:reminders/core/theme/app_theme.dart';
import 'package:reminders/core/utils/app_button.dart';
import 'package:reminders/core/utils/app_toast.dart';

class BackgroundProtectionPage extends StatefulWidget {
  const BackgroundProtectionPage({super.key});

  @override
  State<BackgroundProtectionPage> createState() =>
      _BackgroundProtectionPageState();
}

class _BackgroundProtectionPageState extends State<BackgroundProtectionPage>
    with WidgetsBindingObserver {
  late final BackgroundProtectionService _protectionService;

  bool _isLoading = true;
  ProtectionStatus? _status;
  DeviceInfo? _deviceInfo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _protectionService = getIt<BackgroundProtectionService>();
    _loadStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadStatus();
    }
  }

  Future<void> _loadStatus() async {
    setState(() => _isLoading = true);
    try {
      final status = await _protectionService.getProtectionStatus();
      final deviceInfo = await _protectionService.getDeviceInfo();
      if (mounted) {
        setState(() {
          _status = status;
          _deviceInfo = deviceInfo;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showErrorToast(message: 'Failed to load protection status: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Background Protection'),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colors.primary))
          : RefreshIndicator(
              onRefresh: _loadStatus,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Overall Status Banner
                    _buildOverallStatusBanner(context),
                    const SizedBox(height: 16),

                    // Educational Disclaimer Banner
                    _buildDisclaimerCard(context),
                    const SizedBox(height: 20),

                    // Checklist Section
                    _buildSectionHeader(context, 'Protection Checklist'),
                    _buildChecklistCard(context),
                    const SizedBox(height: 20),

                    // Actions Section
                    _buildSectionHeader(context, 'Recommended Actions'),
                    _buildActionsCard(context),
                    const SizedBox(height: 20),

                    // Device Info Diagnostics Section
                    _buildSectionHeader(context, 'Device Diagnostics'),
                    _buildDeviceInfoCard(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverallStatusBanner(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    if (_status == null) return const SizedBox.shrink();

    Color bgColor;
    Color iconColor;
    IconData iconData;
    String statusTitle;
    String statusSubtitle;

    switch (_status!.overallState) {
      case ProtectionOverallState.protected:
        bgColor = colors.success.withValues(alpha: 0.15);
        iconColor = colors.success;
        iconData = Icons.verified_user_rounded;
        statusTitle = 'Protected';
        statusSubtitle =
            'Standard Android background protections are fully enabled.';
        break;
      case ProtectionOverallState.partiallyProtected:
        bgColor = colors.warning.withValues(alpha: 0.15);
        iconColor = colors.warning;
        iconData = Icons.gpp_maybe_rounded;
        statusTitle = 'Partially Protected';
        statusSubtitle = _status!.isOppoOrColorOS
            ? 'Oppo/ColorOS detected. Review OEM auto-launch settings for maximum survival.'
            : 'Battery optimization exemption recommended for long background monitoring.';
        break;
      case ProtectionOverallState.needsAttention:
        bgColor = colors.error.withValues(alpha: 0.15);
        iconColor = colors.error;
        iconData = Icons.gpp_bad_rounded;
        statusTitle = 'Action Required';
        statusSubtitle =
            'Critical location or notification permissions are missing.';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: iconColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(iconData, color: iconColor, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: typography.titleLarge.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusSubtitle,
                  style: typography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerCard(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, color: colors.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'These settings help Android and device manufacturers allow Location Reminder to continue running while your phone is locked. Some devices may still apply additional background restrictions.',
                style: typography.bodySmall.copyWith(
                  color: colors.textSecondary,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistCard(BuildContext context) {
    final status = _status;
    if (status == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Column(
          children: [
            _buildChecklistItem(
              context,
              title: 'Location Permission',
              subtitle: status.isLocationAlwaysGranted
                  ? 'Always Allow (Optimal background tracking)'
                  : 'While In Use or Denied',
              isSuccess: status.isLocationAlwaysGranted,
              isWarning: !status.isLocationAlwaysGranted,
            ),
            const Divider(height: 1),
            _buildChecklistItem(
              context,
              title: 'Notification Permission',
              subtitle: status.isNotificationGranted
                  ? 'Granted (Alerts active)'
                  : 'Denied',
              isSuccess: status.isNotificationGranted,
              isWarning: !status.isNotificationGranted,
            ),
            const Divider(height: 1),
            _buildChecklistItem(
              context,
              title: 'Foreground Location Service',
              subtitle: status.isForegroundServiceRunning
                  ? 'Active notification running'
                  : 'Service inactive',
              isSuccess: status.isForegroundServiceRunning,
              isWarning: !status.isForegroundServiceRunning,
            ),
            const Divider(height: 1),
            _buildChecklistItem(
              context,
              title: 'Android Battery Optimization',
              subtitle: status.isBatteryOptimizationExempt
                  ? 'Exempt / Unrestricted'
                  : 'Optimized (May be restricted when locked)',
              isSuccess: status.isBatteryOptimizationExempt,
              isWarning: !status.isBatteryOptimizationExempt,
            ),
            if (status.isOppoOrColorOS) ...[
              const Divider(height: 1),
              _buildChecklistItem(
                context,
                title: 'Oppo / ColorOS Background Settings',
                subtitle:
                    'Needs Review (Ensure "Allow auto-launch" and "Allow background activity" are enabled)',
                isSuccess: false,
                isWarning: true,
                badgeText: 'Needs Review',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool isSuccess,
    required bool isWarning,
    String? badgeText,
  }) {
    final colors = context.appColors;
    final typography = context.appTypography;

    IconData icon;
    Color iconColor;

    if (badgeText != null) {
      icon = Icons.error_outline_rounded;
      iconColor = colors.warning;
    } else if (isSuccess) {
      icon = Icons.check_circle_rounded;
      iconColor = colors.success;
    } else if (isWarning) {
      icon = Icons.warning_amber_rounded;
      iconColor = colors.warning;
    } else {
      icon = Icons.cancel_rounded;
      iconColor = colors.error;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: typography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (badgeText != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.warning.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: typography.bodySmall.copyWith(
                            color: colors.warning,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: typography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context) {
    final colors = context.appColors;
    final status = _status;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (status != null && !status.isBatteryOptimizationExempt) ...[
              AppButton(
                width: double.infinity,
                text: 'Allow Unrestricted Battery Usage',
                color: colors.primary,
                onPressed: () async {
                  final requested = await _protectionService
                      .requestBatteryOptimizationExemption();
                  if (!requested && mounted) {
                    await _protectionService.openBatteryOptimizationSettings();
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
            if (status != null && status.isOppoOrColorOS) ...[
              AppButton(
                width: double.infinity,
                text: 'Review Oppo Auto-Launch & Background Settings',
                color: colors.primary,
                onPressed: () async {
                  showSuccessToast(
                    message:
                        'Please enable "Allow auto-launch" and "Allow background activity".',
                  );
                  await _protectionService.openOppoAutoLaunchSettings();
                },
              ),
              const SizedBox(height: 12),
              AppButton(
                width: double.infinity,
                text: 'Open Oppo App Battery Options',
                color: colors.card,
                textStyle: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                onPressed: () async {
                  await _protectionService.openOppoAppBatterySettings();
                },
              ),
              const SizedBox(height: 12),
            ],
            AppButton(
              width: double.infinity,
              text: 'Open Android System App Details',
              color: colors.card,
              textStyle: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              onPressed: () async {
                await _protectionService.openApplicationDetails();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfoCard(BuildContext context) {
    final dev = _deviceInfo;

    if (dev == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDiagnosticRow(context, 'Manufacturer', dev.manufacturer),
            const Divider(height: 1),
            _buildDiagnosticRow(context, 'Brand', dev.brand),
            const Divider(height: 1),
            _buildDiagnosticRow(context, 'Model', dev.model),
            const Divider(height: 1),
            _buildDiagnosticRow(context, 'Android SDK', 'API ${dev.sdkInt}'),
            const Divider(height: 1),
            _buildDiagnosticRow(
              context,
              'OEM Category',
              dev.isOppoOrColorOS ? 'Oppo / ColorOS (Athena)' : 'Generic Android',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticRow(
      BuildContext context, String label, String value) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: typography.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
          Text(
            value,
            style: typography.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
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
}
