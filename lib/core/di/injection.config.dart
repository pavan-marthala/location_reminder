// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:audioplayers/audioplayers.dart' as _i5;
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as _i4;
import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;
import 'package:isar/isar.dart' as _i3;

import '../../features/infrastructure_validation/presentation/bloc/validation_bloc.dart'
    as _i10;
import '../services/alarm_service.dart' as _i6;
import '../services/background_service.dart' as _i9;
import '../services/location_service.dart' as _i7;
import '../services/notification_service.dart' as _i8;
import '../services/permission_validation_service.dart' as _i11;
import 'register_module.dart' as _i12;

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
    await gh.factoryAsync<_i3.Isar>(
      () => registerModule.isar,
      preResolve: true,
    );
    gh.lazySingleton<_i4.FlutterLocalNotificationsPlugin>(
        () => registerModule.localNotifications);
    gh.lazySingleton<_i5.AudioPlayer>(() => registerModule.audioPlayer);
    gh.lazySingleton<_i6.AlarmService>(
        () => _i6.AlarmServiceImpl(gh<_i5.AudioPlayer>()));
    gh.lazySingleton<_i7.LocationService>(() => _i7.LocationServiceImpl());
    gh.lazySingleton<_i8.NotificationService>(() =>
        _i8.NotificationServiceImpl(gh<_i4.FlutterLocalNotificationsPlugin>()));
    gh.lazySingleton<_i9.BackgroundService>(() => _i9.BackgroundServiceImpl());
    gh.factory<_i10.ValidationBloc>(() => _i10.ValidationBloc(
          gh<_i8.NotificationService>(),
          gh<_i6.AlarmService>(),
          gh<_i7.LocationService>(),
          gh<_i9.BackgroundService>(),
        ));
    gh.lazySingleton<_i11.PermissionValidationService>(
        () => _i11.PermissionValidationServiceImpl(
              gh<_i7.LocationService>(),
              gh<_i8.NotificationService>(),
            ));
    return this;
  }
}

class _$RegisterModule extends _i12.RegisterModule {}
