import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:reminders/core/di/injection.dart';
import 'package:reminders/core/services/app_routing_notifier.dart';
import 'package:reminders/core/services/settings_service.dart';
import 'package:reminders/core/theme/app_theme.dart';
import 'package:reminders/core/utils/app_button.dart';
import 'package:reminders/core/utils/app_toast.dart';
import 'package:reminders/core/utils/sized_context.dart';
import '../bloc/validation_bloc.dart';
import '../bloc/validation_event.dart';
import '../bloc/validation_state.dart';

class ValidationPage extends StatelessWidget {
  const ValidationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<ValidationBloc>()..add(const ValidationEvent.initialize()),
      child: const _ValidationPageView(),
    );
  }
}

class _ValidationPageView extends StatefulWidget {
  const _ValidationPageView();

  @override
  State<_ValidationPageView> createState() => _ValidationPageViewState();
}

class _ValidationPageViewState extends State<_ValidationPageView> {
  late final PageController _pageController;
  int _currentStep = 0;
  LocationPermission? _locationPermissionStatus;

  @override
  void initState() {
    super.initState();
    final settings = getIt<SettingsService>();
    final blocState = context.read<ValidationBloc>().state;

    // Smart Return: if user already completed onboarding but location permission
    // was revoked, directly start at Location Permission (Step 2, index 1).
    if (settings.isOnboardingCompleted() &&
        !blocState.isLocationPermissionGranted) {
      _currentStep = 1;
    } else {
      _currentStep = 0;
    }

    _pageController = PageController(initialPage: _currentStep);
    _checkLocationPermissionStatus();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermissionStatus() async {
    try {
      final status = await Geolocator.checkPermission();
      if (mounted) {
        setState(() {
          _locationPermissionStatus = status;
        });
      }
    } catch (_) {}
  }

  void _goToPage(int page) {
    if (page >= 0 && page < 4) {
      setState(() {
        _currentStep = page;
      });
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: BlocListener<ValidationBloc, ValidationState>(
        listenWhen: (previous, current) =>
            previous.isLocationPermissionGranted !=
                current.isLocationPermissionGranted ||
            previous.isNotificationPermissionGranted !=
                current.isNotificationPermissionGranted ||
            previous.errorMessage != current.errorMessage,
        listener: (context, state) async {
          await _checkLocationPermissionStatus();

          if (state.errorMessage != null) {
            showErrorToast(message: state.errorMessage!);
          }

          // Automatically advance if permissions are granted
          if (state.isLocationPermissionGranted && _currentStep == 1) {
            _goToPage(2);
          } else if (state.isNotificationPermissionGranted &&
              _currentStep == 2) {
            _goToPage(3);
          }
        },
        child: Stack(
          children: [
            // Page Content (Edge-to-edge PageView)
            PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
              children: [
                _buildWelcomeStep(),
                _buildLocationStep(),
                _buildNotificationStep(),
                _buildCompletionStep(),
              ],
            ),
            // Top Progress Indicators Overlay
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 20,
              right: 20,
              child: Row(
                children: List.generate(
                  4,
                  (index) => _buildProgressIndicator(index),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(int index) {
    final colors = context.appColors;
    final isCompleted = index < _currentStep;
    final isActive = index == _currentStep;

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        height: 5,
        decoration: BoxDecoration(
          color: isCompleted
              ? colors.primary
              : isActive
              ? colors.primary.withValues(alpha: 0.5)
              : colors.white.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  // ── STEP 1: WELCOME SCREEN ───────────────────────────────────
  Widget _buildWelcomeStep() {
    final colors = context.appColors;

    return _OnboardingPageTemplate(
      key: const ValueKey('step_welcome'),
      imagePath: 'assets/illustration_welcome.png',
      headline: 'Never Miss Your Stop Again',
      description:
          'Set a destination and get alerted automatically when you are near your stop, station, office, or any location.',
      ctaButton: AppButton(
        text: 'Continue',
        color: colors.primary,
        onPressed: () => _goToPage(1),
      ),
    );
  }

  // ── STEP 2: LOCATION PERMISSION SCREEN ────────────────────────
  Widget _buildLocationStep() {
    final colors = context.appColors;
    final typography = context.appTypography;
    final isDenied = _locationPermissionStatus == LocationPermission.denied;
    final isPermanentlyDenied =
        _locationPermissionStatus == LocationPermission.deniedForever;

    Widget? errorWidget;
    if (isDenied || isPermanentlyDenied) {
      errorWidget = Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.error.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: colors.error, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Location permission is required for destination alarms to work.',
                style: typography.bodySmall.copyWith(
                  color: colors.error,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _OnboardingPageTemplate(
      key: const ValueKey('step_location'),
      imagePath: 'assets/illustration_location.png',
      headline: 'Location Access Required',
      description:
          'We monitor your location to detect when you are approaching your selected destination.',
      perks: const [
        'Detect arrival near destination',
        'Trigger geofence alarms',
        'Wake you at the right time',
      ],
      errorWidget: errorWidget,
      ctaButton: isPermanentlyDenied
          ? AppButton(
              text: 'Open Settings',
              color: colors.primary,
              onPressed: () {
                context.read<ValidationBloc>().add(
                  const ValidationEvent.openAppSettings(),
                );
              },
            )
          : AppButton(
              text: isDenied ? 'Try Again' : 'Allow Location Access',
              color: colors.primary,
              onPressed: () {
                context.read<ValidationBloc>().add(
                  const ValidationEvent.requestLocationPermission(),
                );
              },
            ),
    );
  }

  // ── STEP 3: NOTIFICATION PERMISSION SCREEN ────────────────────
  Widget _buildNotificationStep() {
    final colors = context.appColors;
    final typography = context.appTypography;

    return _OnboardingPageTemplate(
      key: const ValueKey('step_notification'),
      imagePath: 'assets/illustration_notification.png',
      headline: 'Stay Updated',
      description:
          'Notifications help us alert you when alarms trigger and provide important updates.',
      perks: const [
        'Alarm notifications',
        'Reminder updates',
        'Monitoring status',
      ],
      ctaButton: AppButton(
        text: 'Allow Notifications',
        color: colors.primary,
        onPressed: () {
          context.read<ValidationBloc>().add(
            const ValidationEvent.requestNotificationPermission(),
          );
        },
      ),
      secondaryButton: TextButton(
        onPressed: () => _goToPage(3),
        child: Text(
          'Skip For Now',
          style: typography.button.copyWith(
            color: colors.textTertiary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ── STEP 4: COMPLETION SCREEN ────────────────────────────────
  Widget _buildCompletionStep() {
    final colors = context.appColors;

    return _OnboardingPageTemplate(
      key: const ValueKey('step_completion'),
      imagePath: 'assets/illustration_completion.png',
      headline: 'You’re Ready To Go',
      description:
          'Create your first destination reminder and never miss your stop again.',
      ctaButton: AppButton(
        text: 'Start Using App',
        color: colors.primary,
        onPressed: () async {
          // Mark onboarding as completed
          await getIt<SettingsService>().setOnboardingCompleted(true);
          // Notify app routing system to trigger GoRouter redirect to /home
          await getIt<AppRoutingNotifier>().notifyPermissionChanged();
        },
      ),
    );
  }
}

// ── IMMERSIVE STORY PAGE TEMPLATE ──────────────────────────────
class _OnboardingPageTemplate extends StatelessWidget {
  final String imagePath;
  final String headline;
  final String description;
  final List<String>? perks;
  final Widget? errorWidget;
  final Widget ctaButton;
  final Widget? secondaryButton;

  const _OnboardingPageTemplate({
    super.key,
    required this.imagePath,
    required this.headline,
    required this.description,
    this.perks,
    this.errorWidget,
    required this.ctaButton,
    this.secondaryButton,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Immersive Full Screen / Top Hero Illustration
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: context.heightPx,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            builder: (context, opacityValue, child) {
              return Opacity(opacity: opacityValue, child: child);
            },
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
        ),
        // 2. Translucent Gradient Overlay for premium text contrast
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  colors.background.withValues(alpha: 0.15),
                  colors.background,
                ],
                stops: const [0.0, 0.40, 1.0],
              ),
            ),
          ),
        ),
        // 3. Layered Text, Perks & Buttons at the Bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, animValue, child) {
              return Opacity(
                opacity: animValue,
                child: Transform.translate(
                  offset: Offset(0, 30 * (1 - animValue)),
                  child: child,
                ),
              );
            },
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      headline,
                      textAlign: TextAlign.center,
                      style: typography.headlineLarge.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                        color: colors.textPrimary,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: typography.bodyMedium.copyWith(
                        color: colors.textSecondary,
                        height: 1.5,
                        fontSize: 15,
                      ),
                    ),
                    if (perks != null && perks!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Column(
                        children: perks!
                            .map((p) => _buildPerkItem(context, p))
                            .toList(),
                      ),
                    ],
                    if (errorWidget != null) ...[
                      const SizedBox(height: 16),
                      errorWidget!,
                    ],
                    const SizedBox(height: 28),
                    ctaButton,
                    if (secondaryButton != null) ...[
                      const SizedBox(height: 8),
                      secondaryButton!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerkItem(BuildContext context, String text) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: colors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, color: colors.success, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: typography.bodyMedium.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
