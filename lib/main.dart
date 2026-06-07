import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:reminders/core/routes/app_routes.dart';
import 'package:reminders/core/theme/app_theme.dart';
import 'core/di/injection.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();

  await dotenv.load(fileName: ".env");
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
    _goRouter = GoRouter(
      initialLocation: AppRoutes.splash,
      navigatorKey: rootNavigatorKey,
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
      themeMode: .system,
      builder: (context, child) {
        return child ?? Text('child');
      },
    );
  }
}

List<RouteBase> routes() {
  return [];
}
