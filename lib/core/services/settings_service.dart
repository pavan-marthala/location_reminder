import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reminders/generated/assets.dart';

import 'package:reminders/features/reminders/domain/entities/reminder_enums.dart';

abstract class SettingsService {
  Future<void> saveSelectedAlarmTonePath(String path);
  String getSelectedAlarmTonePath();
  Future<void> saveMonitoringEnabled(bool enabled);
  bool isMonitoringEnabled();
  Future<void> setOnboardingCompleted(bool completed);
  bool isOnboardingCompleted();
  Future<void> saveVibrationEnabled(bool enabled);
  bool isVibrationEnabled();
  Future<void> saveVibrationPattern(VibrationPattern pattern);
  VibrationPattern getVibrationPattern();
  Future<void> saveSortOption(SortOption option);
  SortOption getSortOption();
}

@LazySingleton(as: SettingsService)
class SettingsServiceImpl implements SettingsService {
  final SharedPreferences _prefs;
  static const String _keyAlarmTonePath = 'selected_alarm_tone_path';
  static const String _keyMonitoringEnabled = 'monitoring_enabled';
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyVibrationEnabled = 'vibration_enabled';
  static const String _keyVibrationPattern = 'vibration_pattern';

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

  @override
  Future<void> saveVibrationPattern(VibrationPattern pattern) async {
    await _prefs.setString(_keyVibrationPattern, pattern.name);
  }

  @override
  VibrationPattern getVibrationPattern() {
    final val = _prefs.getString(_keyVibrationPattern);
    return VibrationPattern.fromString(val);
  }

  @override
  Future<void> saveSortOption(SortOption option) async {
    await _prefs.setString('selected_sort_option', option.name);
  }

  @override
  SortOption getSortOption() {
    final val = _prefs.getString('selected_sort_option');
    return SortOption.fromString(val);
  }
}
