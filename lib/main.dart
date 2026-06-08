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
  await getIt<MonitoringCoordinator>().evaluateMonitoringState();
  await getIt<MapboxService>().init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _goRouter;
  @override
  void initState() {
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
        // Trigger DB reactive watchers on any background isolate state changes
        try {
          final db = getIt<AppDatabase>();
          db.markTablesUpdated([db.reminders]);
        } catch (_) {}

        if (event['status'] == 'triggered') {
          final id = event['reminderId'] as int?;
          final title = event['reminderTitle'] as String?;
          if (id != null) {
            _goRouter.push(AppRoutes.alarm, extra: {
              'id': id,
              'title': title ?? 'Reminder',
            });
          }
        }
      }
    });

    super.initState();
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
  ];
}
