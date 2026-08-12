import 'package:audioplayers/audioplayers.dart';

/// The seven Version-C feedback / prompt clips.
///
/// Each maps to a WAV under `assets/audio/sfx/`. Kept as an enum so callers
/// can never fat-finger a filename and the compiler flags any missing case
/// when we add a new clip.
enum FeedbackKind {
  /// Turn prompt on odd-indexed words (1, 3, 5). Rule 1.
  promptNowYou,

  /// Turn prompt on even-indexed words (2, 4, 6). Rule 1.
  promptSayIt,

  /// Silence re-prompt (Rule 3) — plays alongside re-modeling the word.
  promptLetsTry,

  /// Path Y — child said the target word (STT matched under Rule 5).
  saidIt,

  /// Design B early-listen — child voiced right after the app finished.
  saidItFirst,

  /// Path X — child made a sound but STT didn't match.
  niceTry,

  /// Path Z — child tapped the card without speaking.
  good,
}

/// Thin wrapper around `audioplayers` that also exposes futures which
/// complete when playback naturally ends (needed by the naming-game state
/// machine — it can't advance to LISTEN until the prompt audio has actually
/// finished, otherwise the mic hears the tail of our own speaker).
class AudioService {
  // Legacy static players — kept for fire-and-forget SFX where completion
  // ordering doesn't matter (tap/reward/word).
  static final _reward   = AudioPlayer();
  static final _complete = AudioPlayer();
  static final _word     = AudioPlayer();

  static const _sfxRoot = 'audio/sfx';

  static String _pathFor(FeedbackKind kind) {
    switch (kind) {
      case FeedbackKind.promptNowYou:   return '$_sfxRoot/prompt_now_you.wav';
      case FeedbackKind.promptSayIt:    return '$_sfxRoot/prompt_say_it.wav';
      case FeedbackKind.promptLetsTry:  return '$_sfxRoot/prompt_lets_try.wav';
      case FeedbackKind.saidIt:         return '$_sfxRoot/feedback_said_it.wav';
      case FeedbackKind.saidItFirst:    return '$_sfxRoot/feedback_said_it_first.wav';
      case FeedbackKind.niceTry:        return '$_sfxRoot/feedback_nice_try.wav';
      case FeedbackKind.good:           return '$_sfxRoot/feedback_good.wav';
    }
  }

  /// Play a feedback/prompt clip and return a Future that resolves when
  /// playback finishes. The state machine awaits this before opening the
  /// mic to avoid our own speaker feeding back into the recognizer.
  static Future<void> playFeedback(FeedbackKind kind) =>
      _playAndWait(_pathFor(kind));

  /// Play a vocabulary word audio and wait for it to finish. Same rationale
  /// as playFeedback — mic must stay off while our voice is speaking.
  static Future<void> playWordAndWait(String assetPath) {
    // AssetSource paths are relative to the assets/ root.
    final relative = assetPath.replaceFirst('assets/', '');
    return _playAndWait(relative);
  }

  /// Fire-and-forget word playback. Kept for callers that don't need
  /// completion ordering — e.g. debug tools, session-complete overlay.
  static Future<void> playWord(String assetPath) async {
    try {
      final relative = assetPath.replaceFirst('assets/', '');
      await _word.play(AssetSource(relative));
    } catch (_) {}
  }

  /// The small chime that fires after every word (kept per user's Pile-1
  /// call — silence-per-tap was too dead).
  static Future<void> playReward() async {
    try {
      await _reward.play(AssetSource('$_sfxRoot/reward.wav'));
    } catch (_) {}
  }

  /// End-of-round 4-second crowd cheer.
  static Future<void> playSessionComplete() async {
    try {
      await _complete.play(AssetSource('$_sfxRoot/session_complete.wav'));
    } catch (_) {}
  }

  /// Spin up a one-shot player, start playback, wait for the completion
  /// event, then dispose. Overhead per call is a few ms on Android/iOS —
  /// acceptable for prompts/feedback that fire every ~10-15 sec, and it
  /// keeps state clean (no shared mutable player + no leaked streams).
  static Future<void> _playAndWait(String assetPath) async {
    final player = AudioPlayer();
    try {
      // Subscribe BEFORE calling play(), so we don't miss the event if the
      // clip is very short.
      final done = player.onPlayerComplete.first;
      await player.play(AssetSource(assetPath));
      await done;
    } catch (_) {
      // Missing asset, permission denied, etc. — swallow so the game loop
      // doesn't stall. State machine treats this the same as normal
      // completion.
    } finally {
      try {
        await player.dispose();
      } catch (_) {}
    }
  }
}
