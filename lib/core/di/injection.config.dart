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
    as _i12;
import '../database/app_database.dart' as _i4;
import '../services/alarm_service.dart' as _i7;
import '../services/background_service.dart' as _i11;
import '../services/location_service.dart' as _i8;
import '../services/notification_service.dart' as _i10;
import '../services/permission_validation_service.dart' as _i13;
import '../services/settings_service.dart' as _i9;
import 'register_module.dart' as _i14;

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
    gh.lazySingleton<_i7.AlarmService>(
        () => _i7.AlarmServiceImpl(gh<_i6.AudioPlayer>()));
    gh.lazySingleton<_i8.LocationService>(() => _i8.LocationServiceImpl());
    gh.lazySingleton<_i9.SettingsService>(
        () => _i9.SettingsServiceImpl(gh<_i3.SharedPreferences>()));
    gh.lazySingleton<_i10.NotificationService>(() =>
        _i10.NotificationServiceImpl(
            gh<_i5.FlutterLocalNotificationsPlugin>()));
    gh.lazySingleton<_i11.BackgroundService>(
        () => _i11.BackgroundServiceImpl());
    gh.factory<_i12.ValidationBloc>(() => _i12.ValidationBloc(
          gh<_i10.NotificationService>(),
          gh<_i7.AlarmService>(),
          gh<_i8.LocationService>(),
          gh<_i11.BackgroundService>(),
        ));
    gh.lazySingleton<_i13.PermissionValidationService>(
        () => _i13.PermissionValidationServiceImpl(
              gh<_i8.LocationService>(),
              gh<_i10.NotificationService>(),
            ));
    return this;
  }
}

class _$RegisterModule extends _i14.RegisterModule {}
