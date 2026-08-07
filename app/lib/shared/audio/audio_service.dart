import 'package:audioplayers/audioplayers.dart';

// Uses audioplayers directly for reliable Flutter Web audio context handling.
// All play calls are fire-and-forget — errors are swallowed so a missing
// audio file never crashes the game.
class AudioService {
  static final _tap      = AudioPlayer();
  static final _reward   = AudioPlayer();
  static final _complete = AudioPlayer();
  static final _word     = AudioPlayer();

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

  // Play a word audio file — pass the full Flutter asset path
  // e.g. 'assets/content/packs/en/audio/word_001.wav'
  static Future<void> playWord(String assetPath) async {
    try {
      // AssetSource path is relative to the assets/ root
      final relativePath = assetPath.replaceFirst('assets/', '');
      await _word.play(AssetSource(relativePath));
    } catch (_) {}
  }
}
