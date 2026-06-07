import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class SettingsService {
  Future<void> saveSelectedAlarmTonePath(String path);
  String getSelectedAlarmTonePath();
}

@LazySingleton(as: SettingsService)
class SettingsServiceImpl implements SettingsService {
  final SharedPreferences _prefs;
  static const String _keyAlarmTonePath = 'selected_alarm_tone_path';
  static const String _defaultAlarmTonePath = 'audio/Daybreak.mp3';

  SettingsServiceImpl(this._prefs);

  @override
  Future<void> saveSelectedAlarmTonePath(String path) async {
    await _prefs.setString(_keyAlarmTonePath, path);
  }

  @override
  String getSelectedAlarmTonePath() {
    return _prefs.getString(_keyAlarmTonePath) ?? _defaultAlarmTonePath;
  }
}
