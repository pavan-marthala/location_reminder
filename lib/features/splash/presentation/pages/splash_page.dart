import 'package:flutter/material.dart';
import 'package:reminders/core/di/injection.dart';
import 'package:reminders/core/theme/app_theme.dart';
import 'package:reminders/core/services/app_routing_notifier.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final stopwatch = Stopwatch()..start();

    // Enforce a minimum display time of 1.5 seconds for branding and smooth transition
    final elapsed = stopwatch.elapsedMilliseconds;
    const minDuration = 1500;
    if (elapsed < minDuration) {
      await Future.delayed(Duration(milliseconds: minDuration - elapsed));
    }

    // Trigger routing notifier initialization which checks permissions and redirects automatically
    await getIt<AppRoutingNotifier>().initialize();
  }

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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Icon placeholder using a themed circle and icon
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: gradients.purpleRose,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_location_alt_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              // App Title
              Text(
                'Location Reminder',
                style: typography.headlineLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              // Subtitle
              Text(
                'Always alert, right on time',
                style: typography.bodyMedium.copyWith(
                  color: colors.textTertiary,
                ),
              ),
              const SizedBox(height: 48),
              // Loader
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: colors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
