import 'package:audioplayers/audioplayers.dart';
import 'package:injectable/injectable.dart';

abstract class AlarmService {
  Future<void> init();
  Future<void> playAlarm({String? url});
  Future<void> stopAlarm();
  bool get isPlaying;
}

@LazySingleton(as: AlarmService)
class AlarmServiceImpl implements AlarmService {
  final AudioPlayer _audioPlayer;
  bool _isPlaying = false;

  AlarmServiceImpl(this._audioPlayer);

  static const String _defaultAlarmUrl =
      'https://cdn.pixabay.com/audio/2022/03/24/audio_7ac39d50df.mp3'; // Standard Beep Sound

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
          options: const {
            AVAudioSessionOptions.defaultToSpeaker,
          },
        ),
      ),
    );

    // Listen to player state changes to keep our state in sync
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
    });
  }

  @override
  Future<void> playAlarm({String? url}) async {
    if (_isPlaying) return;

    final sourceUrl = url ?? _defaultAlarmUrl;
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(UrlSource(sourceUrl));
    _isPlaying = true;
  }

  @override
  Future<void> stopAlarm() async {
    if (!_isPlaying) return;

    await _audioPlayer.stop();
    _isPlaying = false;
  }
}
