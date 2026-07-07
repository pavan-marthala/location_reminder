// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:audioplayers/audioplayers.dart' as _i6;
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as _i5;
import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;
import 'package:shared_preferences/shared_preferences.dart' as _i3;

import '../../features/infrastructure_validation/presentation/bloc/validation_bloc.dart'
    as _i28;
import '../../features/reminders/data/datasources/reminder_local_datasource.dart'
    as _i9;
import '../../features/reminders/data/repositories/reminder_repository_impl.dart'
    as _i13;
import '../../features/reminders/domain/repositories/reminder_repository.dart'
    as _i12;
import '../../features/reminders/domain/services/duplicate_detection_service.dart'
    as _i8;
import '../../features/reminders/domain/services/reminder_query_service.dart'
    as _i7;
import '../../features/reminders/domain/usecases/create_reminder_usecase.dart'
    as _i24;
import '../../features/reminders/domain/usecases/delete_reminder_usecase.dart'
    as _i19;
import '../../features/reminders/domain/usecases/get_all_reminders_usecase.dart'
    as _i22;
import '../../features/reminders/domain/usecases/get_reminder_by_id_usecase.dart'
    as _i20;
import '../../features/reminders/domain/usecases/update_reminder_usecase.dart'
    as _i23;
import '../../features/reminders/domain/usecases/watch_all_reminders_usecase.dart'
    as _i21;
import '../../features/reminders/presentation/bloc/reminder_bloc.dart' as _i27;
import '../database/app_database.dart' as _i4;
import '../services/alarm_service.dart' as _i25;
import '../services/app_routing_notifier.dart' as _i26;
import '../services/background_service.dart' as _i10;
import '../services/location_service.dart' as _i11;
import '../services/mapbox_service.dart' as _i15;
import '../services/monitoring_coordinator.dart' as _i17;
import '../services/notification_service.dart' as _i16;
import '../services/permission_validation_service.dart' as _i18;
import '../services/settings_service.dart' as _i14;
import 'register_module.dart' as _i29;

extension GetItInjectableX on _i1.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  Future<_i1.GetIt> init({
    String? environment,
    _i2.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i2.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final registerModule = _$RegisterModule();
    await gh.factoryAsync<_i3.SharedPreferences>(
      () => registerModule.prefs,
      preResolve: true,
    );
    gh.singleton<_i4.AppDatabase>(() => registerModule.database);
    gh.lazySingleton<_i5.FlutterLocalNotificationsPlugin>(
        () => registerModule.localNotifications);
    gh.lazySingleton<_i6.AudioPlayer>(() => registerModule.audioPlayer);
    gh.lazySingleton<_i7.ReminderQueryService>(
        () => const _i7.ReminderQueryService());
    gh.lazySingleton<_i8.DuplicateDetectionService>(
        () => _i8.DuplicateDetectionService());
    gh.lazySingleton<_i9.ReminderLocalDatasource>(
        () => _i9.ReminderLocalDatasourceImpl(gh<_i4.AppDatabase>()));
    gh.lazySingleton<_i10.BackgroundService>(() =>
        _i10.BackgroundServiceImpl(gh<_i5.FlutterLocalNotificationsPlugin>()));
    gh.lazySingleton<_i11.LocationService>(() => _i11.LocationServiceImpl());
    gh.lazySingleton<_i12.ReminderRepository>(
        () => _i13.ReminderRepositoryImpl(gh<_i9.ReminderLocalDatasource>()));
    gh.lazySingleton<_i14.SettingsService>(
        () => _i14.SettingsServiceImpl(gh<_i3.SharedPreferences>()));
    gh.lazySingleton<_i15.MapboxService>(() => _i15.MapboxServiceImpl());
    gh.lazySingleton<_i16.NotificationService>(() =>
        _i16.NotificationServiceImpl(
            gh<_i5.FlutterLocalNotificationsPlugin>()));
    gh.lazySingleton<_i17.MonitoringCoordinator>(
        () => _i17.MonitoringCoordinatorImpl(
              gh<_i14.SettingsService>(),
              gh<_i10.BackgroundService>(),
              gh<_i12.ReminderRepository>(),
            ));
    gh.lazySingleton<_i18.PermissionValidationService>(
        () => _i18.PermissionValidationServiceImpl(
              gh<_i11.LocationService>(),
              gh<_i16.NotificationService>(),
            ));
    gh.factory<_i19.DeleteReminderUseCase>(
        () => _i19.DeleteReminderUseCase(gh<_i12.ReminderRepository>()));
    gh.factory<_i20.GetReminderByIdUseCase>(
        () => _i20.GetReminderByIdUseCase(gh<_i12.ReminderRepository>()));
    gh.factory<_i21.WatchAllRemindersUseCase>(
        () => _i21.WatchAllRemindersUseCase(gh<_i12.ReminderRepository>()));
    gh.factory<_i22.GetAllRemindersUseCase>(
        () => _i22.GetAllRemindersUseCase(gh<_i12.ReminderRepository>()));
    gh.factory<_i23.UpdateReminderUseCase>(
        () => _i23.UpdateReminderUseCase(gh<_i12.ReminderRepository>()));
    gh.factory<_i24.CreateReminderUseCase>(
        () => _i24.CreateReminderUseCase(gh<_i12.ReminderRepository>()));
    gh.lazySingleton<_i25.AlarmService>(() => _i25.AlarmServiceImpl(
          gh<_i6.AudioPlayer>(),
          gh<_i14.SettingsService>(),
        ));
    gh.lazySingleton<_i26.AppRoutingNotifier>(
        () => _i26.AppRoutingNotifier(gh<_i18.PermissionValidationService>()));
    gh.factory<_i27.ReminderBloc>(() => _i27.ReminderBloc(
          gh<_i21.WatchAllRemindersUseCase>(),
          gh<_i24.CreateReminderUseCase>(),
          gh<_i23.UpdateReminderUseCase>(),
          gh<_i19.DeleteReminderUseCase>(),
          gh<_i17.MonitoringCoordinator>(),
          gh<_i7.ReminderQueryService>(),
          gh<_i14.SettingsService>(),
          gh<_i11.LocationService>(),
        ));
    gh.factory<_i28.ValidationBloc>(() => _i28.ValidationBloc(
          gh<_i16.NotificationService>(),
          gh<_i25.AlarmService>(),
          gh<_i11.LocationService>(),
          gh<_i10.BackgroundService>(),
          gh<_i26.AppRoutingNotifier>(),
          gh<_i14.SettingsService>(),
          gh<_i17.MonitoringCoordinator>(),
        ));
    return this;
  }
}

class _$RegisterModule extends _i29.RegisterModule {}
