import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:reminders/core/routes/app_routes.dart';
import 'package:reminders/core/theme/app_theme.dart';
import 'package:reminders/features/splash/presentation/pages/splash_page.dart';
import 'package:reminders/features/infrastructure_validation/presentation/pages/validation_page.dart';
import 'package:reminders/features/reminders/presentation/pages/reminder_list_page.dart';
import 'package:reminders/features/reminders/presentation/pages/create_reminder_page.dart';
import 'package:reminders/features/reminders/presentation/pages/location_picker_page.dart';
import 'package:reminders/features/reminders/domain/entities/reminder_entity.dart';
import 'package:reminders/features/settings/presentation/pages/settings_page.dart';
import 'package:reminders/core/services/notification_service.dart';
import 'package:reminders/core/services/mapbox_service.dart';
import 'package:reminders/core/services/background_service.dart';
import 'package:reminders/core/services/app_routing_notifier.dart';
import 'package:reminders/core/services/monitoring_coordinator.dart';
import 'package:reminders/features/reminders/presentation/pages/alarm_page.dart';
import 'package:reminders/features/settings/presentation/pages/developer_tools_page.dart';
import 'package:reminders/features/settings/presentation/pages/background_protection_page.dart';
import 'package:reminders/core/database/app_database.dart';
import 'core/di/injection.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await configureDependencies();

  // Initialize Core Services during bootstrap to register channels and prevent crashes
  await getIt<NotificationService>().init();
  await getIt<BackgroundService>().init();
  await getIt<MonitoringCoordinator>().evaluateMonitoringState(
    source: 'main',
    reason: 'app_start',
  );
  await getIt<MapboxService>().init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final GoRouter _goRouter;
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    final routingNotifier = getIt<AppRoutingNotifier>();
    _goRouter = GoRouter(
      initialLocation: AppRoutes.splash,
      navigatorKey: rootNavigatorKey,
      refreshListenable: routingNotifier,
      redirect: (context, state) {
        final isSplash = state.matchedLocation == AppRoutes.splash;
        final isValidation = state.matchedLocation == AppRoutes.validation;
        final isAlarm = state.matchedLocation == AppRoutes.alarm;

        // Bypass for alarm route so full screen intents or routing test navigations are allowed immediately
        if (isAlarm) {
          return null;
        }

        // If not bootstrapped yet, always stay on splash
        if (!routingNotifier.isBootstrapped) {
          return AppRoutes.splash;
        }

        // If bootstrapped but permissions are invalid, redirect to validation
        if (!routingNotifier.isValidationValid) {
          if (!isValidation) {
            return AppRoutes.validation;
          }
          return null;
        }

        // If permissions are valid but we are on splash or validation, redirect to home
        if (isSplash || isValidation) {
          return AppRoutes.home;
        }

        // No redirect needed for other pages
        return null;
      },
      debugLogDiagnostics: true,
      routes: routes(),
    );

    // Listen to background service updates to launch Alarm Screen
    getIt<BackgroundService>().backgroundUpdates.listen((event) {
      if (event != null) {
        debugPrint("[MAIN] Event received");

        debugPrint(event.toString());
        // Trigger DB reactive watchers on any background isolate state changes
        try {
          final db = getIt<AppDatabase>();
          db.markTablesUpdated([db.reminders]);
        } catch (_) {}

        if (event['status'] == 'triggered') {
          final id = event['reminderId'] as int?;
          final title = event['reminderTitle'] as String?;
          if (id != null) {
            final routeState = _goRouter.routerDelegate.currentConfiguration;
            final isAlreadyAlarm = routeState.routes.any(
              (route) => route is GoRoute && route.path == AppRoutes.alarm,
            );
            if (isAlreadyAlarm) {
              debugPrint("[MAIN] Already on AlarmPage, skipping push");
            } else {
              debugPrint("[MAIN] Opening AlarmPage");
              _goRouter.push(
                AppRoutes.alarm,
                extra: {'id': id, 'title': title ?? 'Reminder'},
              );
            }
          }
        }
      }
    });

    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _openPendingAlarmFromNotification(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    // The OEM/Doze may have killed the monitor while the screen was locked.
    // Re-evaluate as soon as the user comes back to the app so monitoring is
    // restored immediately instead of on the next cold start.
    getIt<MonitoringCoordinator>()
        .evaluateMonitoringState(
          source: 'app_lifecycle',
          reason: 'resumed',
        )
        .catchError((Object e) {
      debugPrint('[MAIN] Resume monitoring recovery failed: $e');
    });

    _openPendingAlarmFromNotification();
  }

  /// A full-screen alarm notification may have launched the app from a killed
  /// state. Open the alarm screen once the router is ready.
  void _openPendingAlarmFromNotification() {
    if (!mounted) return;
    final reminderId =
        getIt<NotificationService>().takePendingLaunchReminderId();
    if (reminderId == null || reminderId <= 0) return;
    try {
      _goRouter.push(
        AppRoutes.alarm,
        extra: {'id': reminderId, 'title': 'Reminder'},
      );
    } catch (e) {
      debugPrint('[MAIN] Could not open alarm from notification: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _goRouter,
      title: 'Location Reminder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      builder: (context, child) {
        return child ?? Text('child');
      },
    );
  }
}

List<RouteBase> routes() {
  return [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const ReminderListPage(),
    ),
    GoRoute(
      path: AppRoutes.validation,
      builder: (context, state) => const ValidationPage(),
    ),
    GoRoute(
      path: AppRoutes.reminders,
      builder: (context, state) => const ReminderListPage(),
    ),
    GoRoute(
      path: AppRoutes.createReminder,
      builder: (context, state) => const CreateReminderPage(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: AppRoutes.locationPicker,
      builder: (context, state) {
        final params = state.extra as Map<String, dynamic>? ?? {};
        return LocationPickerPage(
          initialLatitude: params['latitude'] as double?,
          initialLongitude: params['longitude'] as double?,
          initialRadiusMeters: params['radiusMeters'] as double?,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.editReminder,
      builder: (context, state) {
        final reminder = state.extra as ReminderEntity?;
        return CreateReminderPage(reminderToEdit: reminder);
      },
    ),
    GoRoute(
      path: AppRoutes.alarm,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return AlarmPage(
          reminderId: extra['id'] as int? ?? 0,
          reminderTitle: extra['title'] as String? ?? 'Reminder',
        );
      },
    ),
    GoRoute(
      path: AppRoutes.developerTools,
      builder: (context, state) => const DeveloperToolsPage(),
    ),
    GoRoute(
      path: AppRoutes.backgroundProtection,
      builder: (context, state) => const BackgroundProtectionPage(),
    ),
  ];
}
