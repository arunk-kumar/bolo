import 'dart:math' as math;

/// Version-C naming-game state machine.
///
/// Pure Dart — no Flutter, no async, no I/O. The [NamingGameScreen] pumps
/// events into it (audio finished, voice detected, tap, timer fired) and
/// reacts to the emitted [NamingEffect]s. This split makes the whole loop
/// unit-testable without pumping widgets.
///
/// See docs/design/version-c-plan.md §3 for the FSM diagram this
/// implements.

/// Phases visible to the screen (drives UI: card tappable? glow on?
/// hint text? star burst?).
enum NamingPhase {
  idle,
  speakWord,
  earlyListen,
  celebFirst,
  speakPrompt,
  listen,
  celebY,
  celebX,
  celebZ,
  reprompt,
  silentAdvance,
  advance,
  sessionComplete,
}

/// Which of the four success paths (or the timeout) resolved the word.
enum NamingPath { y, x, z, first, silent }

/// Effects the state machine wants the screen to execute. Each is a
/// value type; the screen matches on the runtime type in a switch.
sealed class NamingEffect {
  const NamingEffect();
}

class PlayWordAudio extends NamingEffect {
  final String assetPath;
  const PlayWordAudio(this.assetPath);
}

class PlayFeedback extends NamingEffect {
  /// String — the FeedbackKind enum lives in AudioService; we pass it
  /// as its name to avoid importing Flutter/audio into this pure file.
  final String kindName;
  const PlayFeedback(this.kindName);
}

class OpenEarlyListen extends NamingEffect {
  final Duration duration;
  const OpenEarlyListen(this.duration);
}

class OpenListen extends NamingEffect {
  final Duration timeout;
  const OpenListen(this.timeout);
}

class CloseMic extends NamingEffect {
  const CloseMic();
}

class Advance extends NamingEffect {
  const Advance();
}

class ReplayCurrentWord extends NamingEffect {
  const ReplayCurrentWord();
}

class SessionCompleted extends NamingEffect {
  final int score;
  const SessionCompleted(this.score);
}

/// Events the screen pumps into the machine.
sealed class NamingEvent { const NamingEvent(); }

class StartRound extends NamingEvent {
  final List<WordRef> words;
  const StartRound(this.words);
}
class AudioFinished     extends NamingEvent { const AudioFinished(); }
class EarlyVoiceDetected extends NamingEvent { const EarlyVoiceDetected(); }
class EarlyWindowExpired extends NamingEvent { const EarlyWindowExpired(); }
class VoiceMatched     extends NamingEvent { const VoiceMatched(); }
class VoiceUnmatched   extends NamingEvent { const VoiceUnmatched(); }
class CardTapped       extends NamingEvent { const CardTapped(); }
class ListenTimedOut   extends NamingEvent { const ListenTimedOut(); }
class RepromptFinished extends NamingEvent { const RepromptFinished(); }
class CelebrationDone  extends NamingEvent { const CelebrationDone(); }

/// Minimal projection of WordEntry needed by the FSM. Kept in-file so
/// the pure-Dart guarantee holds — no import of the full data model.
class WordRef {
  final String id;
  final String word;         // e.g. "chicken" — used for Rule 5 match
  final String audioAsset;   // asset path to the pre-recorded WAV
  const WordRef({
    required this.id,
    required this.word,
    required this.audioAsset,
  });
}

/// The state machine itself. Owns the current phase + word index +
/// score + reprompt count. Pump events into [handle]; harvest effects
/// from the returned list; UI updates from `phase`.
class NamingStateMachine {
  NamingStateMachine();

  NamingPhase phase = NamingPhase.idle;
  List<WordRef> _words = const [];
  int _currentIndex = 0;
  int _score = 0;
  int _repromptCount = 0;
  NamingPath _lastPath = NamingPath.silent;

  int get currentIndex => _currentIndex;
  int get score => _score;
  int get roundLength => _words.length;
  WordRef get currentWord => _words[_currentIndex];
  NamingPath get lastPath => _lastPath;

  /// Timeout for the main LISTEN phase. First word gets a longer
  /// buffer per Rule 3.
  Duration listenTimeout() =>
      _currentIndex == 0 ? const Duration(seconds: 8) : const Duration(seconds: 6);

  /// The prompt alternates across words (Rule 1: "Now you!" on odd,
  /// "Say it!" on even, both 0-indexed adjusted so word 1 = odd).
  String promptKind() =>
      (_currentIndex % 2 == 0) ? 'promptNowYou' : 'promptSayIt';

  /// Push [event] into the machine, mutate state, return the effects
  /// the screen should run in order.
  List<NamingEffect> handle(NamingEvent event) {
    switch ((phase, event)) {
      // ── Round bootstrap ─────────────────────────────────────────
      case (NamingPhase.idle, StartRound e):
        _words = List.of(e.words);
        _currentIndex = 0;
        _score = 0;
        return _enterWord();

      // ── SPEAK_WORD → EARLY_LISTEN ───────────────────────────────
      case (NamingPhase.speakWord, AudioFinished _):
        phase = NamingPhase.earlyListen;
        return [const OpenEarlyListen(Duration(milliseconds: 400))];

      // ── EARLY_LISTEN branches ───────────────────────────────────
      case (NamingPhase.earlyListen, EarlyVoiceDetected _):
        phase = NamingPhase.celebFirst;
        // "You said it first!" plays; we then wait for STT's final
        // result (if any) to decide Y vs X before advancing. Screen
        // is responsible for keeping the mic open through celebFirst
        // and forwarding VoiceMatched / VoiceUnmatched / ListenTimedOut.
        return [
          const CloseMic(),
          const PlayFeedback('saidItFirst'),
        ];

      case (NamingPhase.earlyListen, EarlyWindowExpired _):
        phase = NamingPhase.speakPrompt;
        return [
          const CloseMic(),
          PlayFeedback(promptKind()),
        ];

      // ── SPEAK_PROMPT → LISTEN ───────────────────────────────────
      case (NamingPhase.speakPrompt, AudioFinished _):
        phase = NamingPhase.listen;
        return [OpenListen(listenTimeout())];

      // ── LISTEN branches ─────────────────────────────────────────
      case (NamingPhase.listen, VoiceMatched _):
        _lastPath = NamingPath.y;
        _score++;
        phase = NamingPhase.celebY;
        return [const CloseMic(), const PlayFeedback('saidIt')];

      case (NamingPhase.listen, VoiceUnmatched _):
        _lastPath = NamingPath.x;
        _score++;
        phase = NamingPhase.celebX;
        return [const CloseMic(), const PlayFeedback('niceTry')];

      case (NamingPhase.listen, CardTapped _):
        _lastPath = NamingPath.z;
        _score++;
        phase = NamingPhase.celebZ;
        return [const CloseMic(), const PlayFeedback('good')];

      case (NamingPhase.listen, ListenTimedOut _):
        if (_repromptCount == 0) {
          _repromptCount = 1;
          phase = NamingPhase.reprompt;
          return [
            const CloseMic(),
            const PlayFeedback('promptLetsTry'),
            const ReplayCurrentWord(),
          ];
        }
        // Second silence — advance silently, no score bump.
        _lastPath = NamingPath.silent;
        return [const CloseMic(), ..._advance()];

      // ── celebFirst — mic still open, waits for STT final ────────
      case (NamingPhase.celebFirst, VoiceMatched _):
        _lastPath = NamingPath.y;
        _score++;
        return [const CloseMic(), ..._advance()];

      case (NamingPhase.celebFirst, VoiceUnmatched _):
        _lastPath = NamingPath.x;
        _score++;
        return [const CloseMic(), ..._advance()];

      case (NamingPhase.celebFirst, ListenTimedOut _):
        // Voice was detected in early-listen but STT never finalized.
        // Count as Path X (vocalized) so the child is credited.
        _lastPath = NamingPath.x;
        _score++;
        return [const CloseMic(), ..._advance()];

      case (NamingPhase.celebFirst, CelebrationDone _):
        // Fallback: celebration audio finished before STT resolved.
        // Assume Path X — the eager kid gets credit either way.
        _lastPath = NamingPath.x;
        _score++;
        return [const CloseMic(), ..._advance()];

      // ── After a celebration audio (Y/X/Z) → advance ─────────────
      case (NamingPhase.celebY, CelebrationDone _):
      case (NamingPhase.celebX, CelebrationDone _):
      case (NamingPhase.celebZ, CelebrationDone _):
        return _advance();

      // ── REPROMPT → replay word → back to SPEAK_WORD ─────────────
      case (NamingPhase.reprompt, RepromptFinished _):
        // The "Let's try again" clip has finished and the word has
        // been replayed. Return to earlyListen for another attempt.
        phase = NamingPhase.earlyListen;
        return [const OpenEarlyListen(Duration(milliseconds: 400))];

      // ── SILENT_ADVANCE / ADVANCE → next word or session complete ─
      case (NamingPhase.silentAdvance, _):
      case (NamingPhase.advance, _):
        // Should have been consumed by _advance() already; ignore.
        return const [];

      // Unknown pairing — ignore rather than crash.
      default:
        return const [];
    }
  }

  List<NamingEffect> _advance() {
    _repromptCount = 0;
    if (_currentIndex + 1 >= _words.length) {
      phase = NamingPhase.sessionComplete;
      return [SessionCompleted(_score)];
    }
    _currentIndex++;
    return _enterWord();
  }

  List<NamingEffect> _enterWord() {
    phase = NamingPhase.speakWord;
    _repromptCount = 0;
    return [PlayWordAudio(currentWord.audioAsset)];
  }

  /// Rule 5 (§version-c-plan §Rule 5): substring OR edit-distance OR
  /// first-3-char prefix. Used by the screen when a TranscriptEvent
  /// arrives — screen normalizes and calls this to decide Y vs X.
  static bool matchesTarget(String transcript, String target) {
    final t = _normalize(transcript);
    final g = _normalize(target);
    if (t.isEmpty || g.isEmpty) return false;

    // 1. Substring — either direction.
    if (t.contains(g) || g.contains(t)) return true;

    // 2. Edit distance ≤ 2 for targets ≥ 5 chars, else ≤ 1.
    final maxEdits = g.length >= 5 ? 2 : 1;
    if (_editDistance(t, g) <= maxEdits) return true;

    // 3. First-3-char prefix, with the transcript at least half the
    //    target's length (so single-syllable stubs still qualify but
    //    a random letter doesn't).
    if (g.length >= 3 && t.length >= 3) {
      final pfxG = g.substring(0, 3);
      final pfxT = t.substring(0, 3);
      if (pfxG == pfxT && t.length >= (g.length / 2).ceil()) return true;
    }

    return false;
  }

  static String _normalize(String s) {
    final buf = StringBuffer();
    for (final rune in s.toLowerCase().runes) {
      final c = String.fromCharCode(rune);
      if (RegExp(r'[a-z]').hasMatch(c)) buf.write(c);
    }
    return buf.toString();
  }

  /// Iterative Levenshtein distance, single row, no allocations per
  /// character. Comfortably handles the 3-15 char words this app uses.
  static int _editDistance(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final prev = List<int>.filled(b.length + 1, 0);
    final curr = List<int>.filled(b.length + 1, 0);
    for (var j = 0; j <= b.length; j++) { prev[j] = j; }
    for (var i = 1; i <= a.length; i++) {
      curr[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        curr[j] = math.min(
          math.min(curr[j - 1] + 1, prev[j] + 1),
          prev[j - 1] + cost,
        );
      }
      for (var j = 0; j <= b.length; j++) { prev[j] = curr[j]; }
    }
    return prev[b.length];
  }
}
