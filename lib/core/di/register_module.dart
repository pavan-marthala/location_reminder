import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

@module
abstract class RegisterModule {
  @preResolve
  Future<Isar> get isar async {
    final dir = await getApplicationDocumentsDirectory();
    return Isar.open(
      [], // Will add ReminderSchema here in Phase 2
      directory: dir.path,
    );
  }

  @lazySingleton
  FlutterLocalNotificationsPlugin get localNotifications =>
      FlutterLocalNotificationsPlugin();

  @lazySingleton
  AudioPlayer get audioPlayer => AudioPlayer();
}
