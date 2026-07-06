import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reminders/generated/assets.dart';

abstract class SettingsService {
  Future<void> saveSelectedAlarmTonePath(String path);
  String getSelectedAlarmTonePath();
  Future<void> saveMonitoringEnabled(bool enabled);
  bool isMonitoringEnabled();
  Future<void> setOnboardingCompleted(bool completed);
  bool isOnboardingCompleted();
  Future<void> saveVibrationEnabled(bool enabled);
  bool isVibrationEnabled();
}

@LazySingleton(as: SettingsService)
class SettingsServiceImpl implements SettingsService {
  final SharedPreferences _prefs;
  static const String _keyAlarmTonePath = 'selected_alarm_tone_path';
  static const String _keyMonitoringEnabled = 'monitoring_enabled';
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyVibrationEnabled = 'vibration_enabled';

  SettingsServiceImpl(this._prefs);

  @override
  Future<void> saveSelectedAlarmTonePath(String path) async {
    await _prefs.setString(_keyAlarmTonePath, path);
  }

  @override
  String getSelectedAlarmTonePath() {
    return _prefs.getString(_keyAlarmTonePath) ?? Assets.audioDaybreak;
  }

  @override
  Future<void> saveMonitoringEnabled(bool enabled) async {
    await _prefs.setBool(_keyMonitoringEnabled, enabled);
  }

  @override
  bool isMonitoringEnabled() {
    return _prefs.getBool(_keyMonitoringEnabled) ?? true;
  }

  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    await _prefs.setBool(_keyOnboardingCompleted, completed);
  }

  @override
  bool isOnboardingCompleted() {
    return _prefs.getBool(_keyOnboardingCompleted) ?? false;
  }

  @override
  Future<void> saveVibrationEnabled(bool enabled) async {
    await _prefs.setBool(_keyVibrationEnabled, enabled);
  }

  @override
  bool isVibrationEnabled() {
    return _prefs.getBool(_keyVibrationEnabled) ?? true;
  }
}
