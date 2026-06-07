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

import 'register_module.dart' as _i6;

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
    return this;
  }
}

class _$RegisterModule extends _i6.RegisterModule {}
