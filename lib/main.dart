import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:reminders/core/routes/app_routes.dart';
import 'package:reminders/core/theme/app_theme.dart';
import 'package:reminders/features/splash/presentation/pages/splash_page.dart';
import 'package:reminders/features/infrastructure_validation/presentation/pages/validation_page.dart';
import 'package:reminders/features/reminders/presentation/pages/reminder_list_page.dart';
import 'package:reminders/features/reminders/presentation/pages/create_reminder_page.dart';
import 'package:reminders/features/settings/presentation/pages/settings_page.dart';
import 'package:reminders/core/services/notification_service.dart';
import 'package:reminders/core/services/mapbox_service.dart';
import 'package:reminders/core/services/background_service.dart';
import 'package:reminders/core/services/app_routing_notifier.dart';
import 'package:reminders/core/services/monitoring_coordinator.dart';
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
  ];
}
