import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:injectable/injectable.dart';
import 'package:reminders/core/services/settings_service.dart';

abstract class AlarmService {
  Future<void> init();
  Future<void> playAlarm();
  Future<void> stopAlarm();
  bool get isPlaying;
}

@LazySingleton(as: AlarmService)
class AlarmServiceImpl implements AlarmService {
  final AudioPlayer _audioPlayer;
  final SettingsService _settingsService;
  bool _isPlaying = false;

  AlarmServiceImpl(this._audioPlayer, this._settingsService);

  @override
  bool get isPlaying => _isPlaying;

  @override
  Future<void> init() async {
    // Configure audio player settings for alarm/background capabilities
    await _audioPlayer.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.alarm,
          audioFocus: AndroidAudioFocus.gainTransient,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {},
        ),
      ),
    );

    // Listen to player state changes to keep our state in sync
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
    });
  }

  @override
  Future<void> playAlarm() async {
    if (_isPlaying) return;

    final assetPath = _settingsService.getSelectedAlarmTonePath();
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource(assetPath));
    _isPlaying = true;
  }

  @override
  Future<void> stopAlarm() async {
    try {
      FlutterBackgroundService().invoke('stopAlarm');
    } catch (_) {}

    if (!_isPlaying) return;

    await _audioPlayer.stop();
    _isPlaying = false;
  }
}
