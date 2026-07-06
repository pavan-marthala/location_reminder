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
    as _i27;
import '../../features/reminders/data/datasources/reminder_local_datasource.dart'
    as _i8;
import '../../features/reminders/data/repositories/reminder_repository_impl.dart'
    as _i12;
import '../../features/reminders/domain/repositories/reminder_repository.dart'
    as _i11;
import '../../features/reminders/domain/services/reminder_query_service.dart'
    as _i7;
import '../../features/reminders/domain/usecases/create_reminder_usecase.dart'
    as _i23;
import '../../features/reminders/domain/usecases/delete_reminder_usecase.dart'
    as _i18;
import '../../features/reminders/domain/usecases/get_all_reminders_usecase.dart'
    as _i21;
import '../../features/reminders/domain/usecases/get_reminder_by_id_usecase.dart'
    as _i19;
import '../../features/reminders/domain/usecases/update_reminder_usecase.dart'
    as _i22;
import '../../features/reminders/domain/usecases/watch_all_reminders_usecase.dart'
    as _i20;
import '../../features/reminders/presentation/bloc/reminder_bloc.dart' as _i26;
import '../database/app_database.dart' as _i4;
import '../services/alarm_service.dart' as _i24;
import '../services/app_routing_notifier.dart' as _i25;
import '../services/background_service.dart' as _i9;
import '../services/location_service.dart' as _i10;
import '../services/mapbox_service.dart' as _i14;
import '../services/monitoring_coordinator.dart' as _i16;
import '../services/notification_service.dart' as _i15;
import '../services/permission_validation_service.dart' as _i17;
import '../services/settings_service.dart' as _i13;
import 'register_module.dart' as _i28;

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
    gh.lazySingleton<_i8.ReminderLocalDatasource>(
        () => _i8.ReminderLocalDatasourceImpl(gh<_i4.AppDatabase>()));
    gh.lazySingleton<_i9.BackgroundService>(() =>
        _i9.BackgroundServiceImpl(gh<_i5.FlutterLocalNotificationsPlugin>()));
    gh.lazySingleton<_i10.LocationService>(() => _i10.LocationServiceImpl());
    gh.lazySingleton<_i11.ReminderRepository>(
        () => _i12.ReminderRepositoryImpl(gh<_i8.ReminderLocalDatasource>()));
    gh.lazySingleton<_i13.SettingsService>(
        () => _i13.SettingsServiceImpl(gh<_i3.SharedPreferences>()));
    gh.lazySingleton<_i14.MapboxService>(() => _i14.MapboxServiceImpl());
    gh.lazySingleton<_i15.NotificationService>(() =>
        _i15.NotificationServiceImpl(
            gh<_i5.FlutterLocalNotificationsPlugin>()));
    gh.lazySingleton<_i16.MonitoringCoordinator>(
        () => _i16.MonitoringCoordinatorImpl(
              gh<_i13.SettingsService>(),
              gh<_i9.BackgroundService>(),
              gh<_i11.ReminderRepository>(),
            ));
    gh.lazySingleton<_i17.PermissionValidationService>(
        () => _i17.PermissionValidationServiceImpl(
              gh<_i10.LocationService>(),
              gh<_i15.NotificationService>(),
            ));
    gh.factory<_i18.DeleteReminderUseCase>(
        () => _i18.DeleteReminderUseCase(gh<_i11.ReminderRepository>()));
    gh.factory<_i19.GetReminderByIdUseCase>(
        () => _i19.GetReminderByIdUseCase(gh<_i11.ReminderRepository>()));
    gh.factory<_i20.WatchAllRemindersUseCase>(
        () => _i20.WatchAllRemindersUseCase(gh<_i11.ReminderRepository>()));
    gh.factory<_i21.GetAllRemindersUseCase>(
        () => _i21.GetAllRemindersUseCase(gh<_i11.ReminderRepository>()));
    gh.factory<_i22.UpdateReminderUseCase>(
        () => _i22.UpdateReminderUseCase(gh<_i11.ReminderRepository>()));
    gh.factory<_i23.CreateReminderUseCase>(
        () => _i23.CreateReminderUseCase(gh<_i11.ReminderRepository>()));
    gh.lazySingleton<_i24.AlarmService>(() => _i24.AlarmServiceImpl(
          gh<_i6.AudioPlayer>(),
          gh<_i13.SettingsService>(),
        ));
    gh.lazySingleton<_i25.AppRoutingNotifier>(
        () => _i25.AppRoutingNotifier(gh<_i17.PermissionValidationService>()));
    gh.factory<_i26.ReminderBloc>(() => _i26.ReminderBloc(
          gh<_i20.WatchAllRemindersUseCase>(),
          gh<_i23.CreateReminderUseCase>(),
          gh<_i22.UpdateReminderUseCase>(),
          gh<_i18.DeleteReminderUseCase>(),
          gh<_i16.MonitoringCoordinator>(),
          gh<_i7.ReminderQueryService>(),
          gh<_i13.SettingsService>(),
          gh<_i10.LocationService>(),
        ));
    gh.factory<_i27.ValidationBloc>(() => _i27.ValidationBloc(
          gh<_i15.NotificationService>(),
          gh<_i24.AlarmService>(),
          gh<_i10.LocationService>(),
          gh<_i9.BackgroundService>(),
          gh<_i25.AppRoutingNotifier>(),
          gh<_i13.SettingsService>(),
          gh<_i16.MonitoringCoordinator>(),
        ));
    return this;
  }
}

class _$RegisterModule extends _i28.RegisterModule {}
