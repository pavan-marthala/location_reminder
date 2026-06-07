import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reminders/generated/assets.dart';

abstract class SettingsService {
  Future<void> saveSelectedAlarmTonePath(String path);
  String getSelectedAlarmTonePath();
  Future<void> saveMonitoringEnabled(bool enabled);
  bool isMonitoringEnabled();
}

@LazySingleton(as: SettingsService)
class SettingsServiceImpl implements SettingsService {
  final SharedPreferences _prefs;
  static const String _keyAlarmTonePath = 'selected_alarm_tone_path';
  static const String _keyMonitoringEnabled = 'monitoring_enabled';

  SettingsServiceImpl(this._prefs);

  @override
  Future<void> saveSelectedAlarmTonePath(String path) async {
    await _prefs.setString(_keyAlarmTonePath, path);
  }

  @override
  String getSelectedAlarmTonePath() {
    // Strip 'assets/' prefix since AssetSource expects path relative to assets/
    final fullPath = _prefs.getString(_keyAlarmTonePath) ?? Assets.audioDaybreak;
    return fullPath.startsWith('assets/') ? fullPath.substring(7) : fullPath;
  }

  @override
  Future<void> saveMonitoringEnabled(bool enabled) async {
    await _prefs.setBool(_keyMonitoringEnabled, enabled);
  }

  @override
  bool isMonitoringEnabled() {
    return _prefs.getBool(_keyMonitoringEnabled) ?? true;
  }
}
