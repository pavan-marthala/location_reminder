import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:reminders/core/di/injection.dart';
import 'package:reminders/core/services/app_routing_notifier.dart';
import 'package:reminders/core/services/background_protection_service.dart';
import 'package:reminders/core/services/settings_service.dart';
import 'package:reminders/core/theme/app_theme.dart';
import 'package:reminders/core/utils/app_button.dart';
import 'package:reminders/core/utils/app_toast.dart';
import 'package:go_router/go_router.dart';
import 'package:reminders/core/routes/app_routes.dart';
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

class _ValidationPageViewState extends State<_ValidationPageView>
    with WidgetsBindingObserver {
  late final PageController _pageController;
  int _currentStep = 0;
  LocationPermission? _locationPermissionStatus;
  bool _hasRequestedLocation = false;
  bool _batteryExempt = false;
  bool _protectionChecked = false;
  bool _requestingExemption = false;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get _needsBackgroundLocation =>
      _locationPermissionStatus != LocationPermission.always;

  bool get _needsBatteryExemption => _isAndroid && !_batteryExempt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    _refreshReadiness();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _onResumed();
  }

  /// Users are sent to the system Settings app to grant "Allow all the time"
  /// location or the battery exemption. Re-read both whenever we come back.
  Future<void> _onResumed() async {
    await _refreshReadiness();
    if (!mounted) return;
    context.read<ValidationBloc>().add(const ValidationEvent.initialize());

    // If they came back from Settings with everything granted, continue the
    // onboarding flow automatically.
    if (_currentStep == 1 && !_needsBackgroundLocation) {
      _goToPage(2);
    }
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

  /// Re-reads the two background-reliability gates: "Allow all the time"
  /// location and, on Android, the battery optimisation exemption.
  Future<bool> _refreshReadiness() async {
    LocationPermission permission = _locationPermissionStatus ??
        LocationPermission.denied;
    bool exempt = true;
    try {
      permission = await Geolocator.checkPermission();
    } catch (_) {}

    if (_isAndroid) {
      try {
        exempt = await getIt<BackgroundProtectionService>()
            .isIgnoringBatteryOptimizations();
      } catch (_) {
        exempt = false;
      }
    }

    if (mounted) {
      setState(() {
        _locationPermissionStatus = permission;
        _batteryExempt = exempt;
        _protectionChecked = true;
      });
    }
    return permission == LocationPermission.always && exempt;
  }

  Future<void> _requestBatteryExemption() async {
    if (_requestingExemption) return;
    setState(() => _requestingExemption = true);
    try {
      await getIt<BackgroundProtectionService>()
          .requestBatteryOptimizationExemption();
      await _refreshReadiness();
      if (mounted && _needsBatteryExemption) {
        // Some OEMs ignore the system dialog; fall back to app settings.
        await getIt<BackgroundProtectionService>().openBatteryOptimizationSettings();
      }
    } finally {
      if (mounted) setState(() => _requestingExemption = false);
    }
  }

  Future<void> _openAppSettings() async {
    context.read<ValidationBloc>().add(
          const ValidationEvent.openAppSettings(),
        );
  }

  Future<void> _finishOnboarding() async {
    final ready = await _refreshReadiness();
    if (!mounted) return;

    if (!ready) {
      if (_needsBackgroundLocation) {
        showErrorToast(
          message: 'Set location access to “Allow all the time” first.',
        );
        _goToPage(1);
      } else {
        showErrorToast(
          message: 'Allow background activity so reminders keep working.',
        );
      }
      return;
    }

    // Mark onboarding as completed and let the router move to /home now that
    // every background-reliability requirement is satisfied.
    await getIt<SettingsService>().setOnboardingCompleted(true);
    await getIt<AppRoutingNotifier>().notifyPermissionChanged();
  }

  void _maybeAutoAdvance(ValidationState state) {
    if (_currentStep == 1 && state.isBackgroundLocationPermissionGranted) {
      _goToPage(2);
      // If notifications were already granted in a previous session, keep the
      // flow moving instead of leaving the user on a completed step.
      Future<void>.delayed(const Duration(milliseconds: 700), () {
        if (!mounted || _currentStep != 2) return;
        if (state.isNotificationPermissionGranted) {
          _goToPage(3);
        }
      });
      return;
    }
    if (_currentStep == 2 && state.isNotificationPermissionGranted) {
      _goToPage(3);
    }
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

          _maybeAutoAdvance(state);
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
    final status = _locationPermissionStatus;
    final isWhileInUse = status == LocationPermission.whileInUse;
    final isInitial = status == LocationPermission.denied &&
        !_hasRequestedLocation;
    final isDenied = status == LocationPermission.denied && _hasRequestedLocation;
    final isPermanentlyDenied = status == LocationPermission.deniedForever;

    Widget? errorWidget;
    if (isWhileInUse) {
      errorWidget = Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: colors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Android is set to “While using the app”. Choose “Allow all '
                'the time” so reminders still trigger when your phone is '
                'locked or the app is closed.',
                style: typography.bodySmall.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (isDenied) {
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
                'Location permission was denied.',
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
    } else if (isPermanentlyDenied) {
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
                'Location permission is permanently denied.\nPlease enable it from Settings.',
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

    final headline = isWhileInUse
        ? 'Allow All The Time'
        : (isInitial ? 'Allow Location Permission' : 'Location Access Required');
    final description = isWhileInUse
        ? 'Background location access lets us detect your destination while the app is closed or your phone is locked.'
        : 'We monitor your location to detect when you are approaching your selected destination.';
    final buttonText = isWhileInUse || isPermanentlyDenied
        ? 'Open Settings'
        : (isDenied ? 'Try Again' : 'Allow Location');

    return _OnboardingPageTemplate(
      key: const ValueKey('step_location'),
      imagePath: 'assets/illustration_location.png',
      headline: headline,
      description: description,
      perks: isWhileInUse
          ? const [
              'Works while the phone is locked',
              'Detects arrival in the background',
              'Reliable geofence alarms',
            ]
          : const [
              'Detect arrival near destination',
              'Trigger geofence alarms',
              'Wake you at the right time',
            ],
      errorWidget: errorWidget,
      ctaButton: isWhileInUse || isPermanentlyDenied
          ? AppButton(
              text: buttonText,
              color: colors.primary,
              onPressed: _openAppSettings,
            )
          : AppButton(
              text: buttonText,
              color: colors.primary,
              onPressed: () {
                setState(() {
                  _hasRequestedLocation = true;
                });
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
    final typography = context.appTypography;
    final needsLocation = _needsBackgroundLocation;
    final needsBattery = _protectionChecked && _needsBatteryExemption;
    final blocked = needsLocation || needsBattery;

    Widget? statusWidget;
    if (blocked) {
      statusWidget = Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(
              needsBattery
                  ? Icons.battery_alert_rounded
                  : Icons.location_off_rounded,
              color: colors.primary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                needsLocation
                    ? 'Location access must be set to “Allow all the time”.'
                    : 'Battery optimisation is still restricting background monitoring.',
                style: typography.bodySmall.copyWith(
                  color: colors.textPrimary,
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
      key: const ValueKey('step_completion'),
      imagePath: 'assets/illustration_completion.png',
      headline: blocked ? 'One Last Step' : 'You’re Ready To Go',
      description: blocked
          ? 'Android can only keep location monitoring alive while the phone is idle if background access and battery rules allow it.'
          : 'Create your first destination reminder and never miss your stop again.',
      perks: const [
        'Play Services geofence monitoring',
        'Works while the phone is locked',
        'Optional OEM battery protection available',
      ],
      errorWidget: statusWidget,
      ctaButton: Column(
        children: [
          if (needsLocation) ...[
            AppButton(
              width: double.infinity,
              text: 'Open Location Settings',
              color: colors.primary,
              onPressed: _openAppSettings,
            ),
            const SizedBox(height: 12),
          ],
          if (needsBattery) ...[
            AppButton(
              width: double.infinity,
              text: 'Allow Background Activity',
              color: colors.primary,
              isLoading: _requestingExemption,
              onPressed: _requestingExemption ? null : _requestBatteryExemption,
            ),
            const SizedBox(height: 12),
          ],
          AppButton(
            width: double.infinity,
            text: 'Review Background Protection',
            color: colors.card,
            textStyle: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            onPressed: () {
              context.push(AppRoutes.backgroundProtection);
            },
          ),
          const SizedBox(height: 12),
          AppButton(
            width: double.infinity,
            text: 'Start Using App',
            color: blocked ? colors.card : colors.primary,
            textStyle: blocked
                ? TextStyle(
                    color: colors.textTertiary,
                    fontWeight: FontWeight.bold,
                  )
                : null,
            onPressed: _finishOnboarding,
          ),
        ],
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
          height: MediaQuery.of(context).size.height,
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
