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
    as _i23;
import '../../features/reminders/data/datasources/reminder_local_datasource.dart'
    as _i7;
import '../../features/reminders/data/repositories/reminder_repository_impl.dart'
    as _i11;
import '../../features/reminders/domain/repositories/reminder_repository.dart'
    as _i10;
import '../../features/reminders/domain/usecases/create_reminder_usecase.dart'
    as _i20;
import '../../features/reminders/domain/usecases/delete_reminder_usecase.dart'
    as _i16;
import '../../features/reminders/domain/usecases/get_all_reminders_usecase.dart'
    as _i18;
import '../../features/reminders/domain/usecases/get_reminder_by_id_usecase.dart'
    as _i17;
import '../../features/reminders/domain/usecases/update_reminder_usecase.dart'
    as _i19;
import '../../features/reminders/presentation/bloc/reminder_bloc.dart' as _i24;
import '../database/app_database.dart' as _i4;
import '../services/alarm_service.dart' as _i21;
import '../services/app_routing_notifier.dart' as _i22;
import '../services/background_service.dart' as _i8;
import '../services/location_service.dart' as _i9;
import '../services/monitoring_coordinator.dart' as _i14;
import '../services/notification_service.dart' as _i13;
import '../services/permission_validation_service.dart' as _i15;
import '../services/settings_service.dart' as _i12;
import 'register_module.dart' as _i25;

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
    gh.lazySingleton<_i7.ReminderLocalDatasource>(
        () => _i7.ReminderLocalDatasourceImpl(gh<_i4.AppDatabase>()));
    gh.lazySingleton<_i8.BackgroundService>(() =>
        _i8.BackgroundServiceImpl(gh<_i5.FlutterLocalNotificationsPlugin>()));
    gh.lazySingleton<_i9.LocationService>(() => _i9.LocationServiceImpl());
    gh.lazySingleton<_i10.ReminderRepository>(
        () => _i11.ReminderRepositoryImpl(gh<_i7.ReminderLocalDatasource>()));
    gh.lazySingleton<_i12.SettingsService>(
        () => _i12.SettingsServiceImpl(gh<_i3.SharedPreferences>()));
    gh.lazySingleton<_i13.NotificationService>(() =>
        _i13.NotificationServiceImpl(
            gh<_i5.FlutterLocalNotificationsPlugin>()));
    gh.lazySingleton<_i14.MonitoringCoordinator>(
        () => _i14.MonitoringCoordinatorImpl(
              gh<_i12.SettingsService>(),
              gh<_i8.BackgroundService>(),
              gh<_i10.ReminderRepository>(),
            ));
    gh.lazySingleton<_i15.PermissionValidationService>(
        () => _i15.PermissionValidationServiceImpl(
              gh<_i9.LocationService>(),
              gh<_i13.NotificationService>(),
            ));
    gh.factory<_i16.DeleteReminderUseCase>(
        () => _i16.DeleteReminderUseCase(gh<_i10.ReminderRepository>()));
    gh.factory<_i17.GetReminderByIdUseCase>(
        () => _i17.GetReminderByIdUseCase(gh<_i10.ReminderRepository>()));
    gh.factory<_i18.GetAllRemindersUseCase>(
        () => _i18.GetAllRemindersUseCase(gh<_i10.ReminderRepository>()));
    gh.factory<_i19.UpdateReminderUseCase>(
        () => _i19.UpdateReminderUseCase(gh<_i10.ReminderRepository>()));
    gh.factory<_i20.CreateReminderUseCase>(
        () => _i20.CreateReminderUseCase(gh<_i10.ReminderRepository>()));
    gh.lazySingleton<_i21.AlarmService>(() => _i21.AlarmServiceImpl(
          gh<_i6.AudioPlayer>(),
          gh<_i12.SettingsService>(),
        ));
    gh.lazySingleton<_i22.AppRoutingNotifier>(
        () => _i22.AppRoutingNotifier(gh<_i15.PermissionValidationService>()));
    gh.factory<_i23.ValidationBloc>(() => _i23.ValidationBloc(
          gh<_i13.NotificationService>(),
          gh<_i21.AlarmService>(),
          gh<_i9.LocationService>(),
          gh<_i8.BackgroundService>(),
          gh<_i22.AppRoutingNotifier>(),
        ));
    gh.factory<_i24.ReminderBloc>(() => _i24.ReminderBloc(
          gh<_i18.GetAllRemindersUseCase>(),
          gh<_i20.CreateReminderUseCase>(),
          gh<_i19.UpdateReminderUseCase>(),
          gh<_i16.DeleteReminderUseCase>(),
          gh<_i14.MonitoringCoordinator>(),
        ));
    return this;
  }
}

class _$RegisterModule extends _i25.RegisterModule {}
