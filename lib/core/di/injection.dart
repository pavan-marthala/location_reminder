import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:reminders/core/services/alarm_scheduler_service.dart';
import 'injection.config.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async {
  await getIt.init();
  getIt.registerLazySingleton<AlarmSchedulerService>(
    () => AlarmSchedulerServiceImpl(getIt(), getIt()),
  );
}

