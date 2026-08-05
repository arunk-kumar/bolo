import 'package:audioplayers/audioplayers.dart';

// Uses audioplayers directly (not flame_audio wrapper) for reliable
// Flutter Web audio context handling.
class AudioService {
  static final _tap      = AudioPlayer();
  static final _reward   = AudioPlayer();
  static final _complete = AudioPlayer();

  static Future<void> playTap() async {
    try {
      await _tap.play(AssetSource('audio/sfx/tap.wav'));
    } catch (_) {}
  }

  static Future<void> playReward() async {
    try {
      await _reward.play(AssetSource('audio/sfx/reward.wav'));
    } catch (_) {}
  }

  static Future<void> playSessionComplete() async {
    try {
      await _complete.play(AssetSource('audio/sfx/session_complete.wav'));
    } catch (_) {}
  }
}
