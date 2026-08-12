import 'package:flutter_test/flutter_test.dart';

import 'package:bolo/features/game_naming/naming_state_machine.dart';

/// Six-word round used by most tests. The words are deliberately from
/// different categories/lengths so the Rule 5 match logic gets exercised
/// on realistic vocabulary.
final _sixWords = <WordRef>[
  WordRef(id: 'w1', word: 'chicken',  audioAsset: 'assets/x/chicken.wav'),
  WordRef(id: 'w2', word: 'cat',      audioAsset: 'assets/x/cat.wav'),
  WordRef(id: 'w3', word: 'elephant', audioAsset: 'assets/x/elephant.wav'),
  WordRef(id: 'w4', word: 'ball',     audioAsset: 'assets/x/ball.wav'),
  WordRef(id: 'w5', word: 'apple',    audioAsset: 'assets/x/apple.wav'),
  WordRef(id: 'w6', word: 'dog',      audioAsset: 'assets/x/dog.wav'),
];

/// Helper: walk the FSM through the first word's initial audio phase,
/// leaving it in [NamingPhase.earlyListen] ready to receive a Path event.
NamingStateMachine _bootedThroughSpeakWord() {
  final fsm = NamingStateMachine();
  fsm.handle(StartRound(_sixWords));
  // After StartRound, phase = speakWord. Simulate the audio finishing.
  fsm.handle(const AudioFinished());
  return fsm;
}

void main() {
  group('Rule 5 — word matching', () {
    test('exact match', () {
      expect(NamingStateMachine.matchesTarget('chicken', 'chicken'), true);
    });

    test('case-insensitive', () {
      expect(NamingStateMachine.matchesTarget('CHICKEN', 'chicken'), true);
      expect(NamingStateMachine.matchesTarget('Chicken.', 'chicken'), true);
    });

    test('substring — transcript contains target', () {
      expect(
        NamingStateMachine.matchesTarget('you said chicken', 'chicken'),
        true,
      );
    });

    test('substring — target contains transcript', () {
      // "chic" is inside "chicken" — Rule 5 point 1
      expect(NamingStateMachine.matchesTarget('chic', 'chicken'), true);
    });

    test('edit distance — 2 char difference for ≥5-char target', () {
      // "chikin" -> "chicken" is 2 edits
      expect(NamingStateMachine.matchesTarget('chikin', 'chicken'), true);
    });

    test('edit distance — 1 char difference for short target', () {
      // "kat" -> "cat" is 1 edit; threshold for target<5 chars = 1
      expect(NamingStateMachine.matchesTarget('kat', 'cat'), true);
    });

    test('edit distance — 2 edits for short target should FAIL', () {
      // "kot" -> "cat" is 2 edits (k→c, o→a); threshold for 3-char = 1.
      // Also fails substring & prefix (no shared start) — a clean point-2
      // reject case.
      expect(NamingStateMachine.matchesTarget('kot', 'cat'), false);
    });

    test('first-3 prefix — partial match with sufficient length', () {
      // "chic" starts with "chi", target = "chicken". 4 chars >= 7/2 = 4.
      expect(NamingStateMachine.matchesTarget('chic', 'chicken'), true);
    });

    // Note: we don't unit-test the point-3 half-length constraint in
    // isolation because point 1 (substring) dominates every case where
    // that constraint would matter — any short string that's a prefix
    // of the target hits substring first. That's the intended union
    // behavior: Rule 5 is generous by design.

    test('rejects garbage', () {
      expect(NamingStateMachine.matchesTarget('banana', 'chicken'), false);
      expect(NamingStateMachine.matchesTarget('xyz', 'chicken'), false);
    });

    test('rejects empty', () {
      expect(NamingStateMachine.matchesTarget('', 'chicken'), false);
      expect(NamingStateMachine.matchesTarget('chicken', ''), false);
    });
  });

  group('Round bootstrap', () {
    test('StartRound emits PlayWordAudio for word 0', () {
      final fsm = NamingStateMachine();
      final effects = fsm.handle(StartRound(_sixWords));
      expect(fsm.phase, NamingPhase.speakWord);
      expect(fsm.currentIndex, 0);
      expect(fsm.score, 0);
      expect(effects.length, 1);
      expect(effects.first, isA<PlayWordAudio>());
      expect(
        (effects.first as PlayWordAudio).assetPath,
        'assets/x/chicken.wav',
      );
    });

    test('empty word list still bootstraps to speakWord', () {
      final fsm = NamingStateMachine();
      // Edge case: caller shouldn't do this, but the FSM shouldn't crash.
      // We can't actually PlayWordAudio(...) with an out-of-bounds word,
      // so this test is really just documenting the behavior.
      expect(
        () => fsm.handle(const StartRound([])),
        throwsA(anything),
      );
    });
  });

  group('First-word 8s timeout — Rule 3', () {
    test('word 0 gets 8s listen timeout', () {
      final fsm = _bootedThroughSpeakWord();
      expect(fsm.listenTimeout(), const Duration(seconds: 8));
    });

    test('subsequent words get 6s', () {
      final fsm = _bootedThroughSpeakWord();
      // Force-advance to word 1 by simulating a full Path Z round.
      fsm.handle(const EarlyWindowExpired());   // exit early-listen -> prompt
      fsm.handle(const AudioFinished());         // prompt done -> listen
      fsm.handle(const CardTapped());            // tap -> celebZ
      fsm.handle(const CelebrationDone());       // celeb done -> advance -> word 1

      expect(fsm.currentIndex, 1);
      expect(fsm.listenTimeout(), const Duration(seconds: 6));
    });
  });

  group('Rule 1 — alternating prompt', () {
    test('even index → Now you!', () {
      final fsm = _bootedThroughSpeakWord();
      // word 0 -> promptNowYou
      final effects = fsm.handle(const EarlyWindowExpired());
      final playFeedback = effects.whereType<PlayFeedback>().first;
      expect(playFeedback.kindName, 'promptNowYou');
    });

    test('odd index → Say it!', () {
      final fsm = _bootedThroughSpeakWord();
      // Advance to word 1 via a full Path Z round
      fsm.handle(const EarlyWindowExpired());
      fsm.handle(const AudioFinished());
      fsm.handle(const CardTapped());
      fsm.handle(const CelebrationDone());
      // Now on word 1, currently in speakWord phase after _enterWord
      expect(fsm.currentIndex, 1);
      expect(fsm.phase, NamingPhase.speakWord);
      // Simulate word audio finished + early-listen expired
      fsm.handle(const AudioFinished());
      final effects = fsm.handle(const EarlyWindowExpired());
      final playFeedback = effects.whereType<PlayFeedback>().first;
      expect(playFeedback.kindName, 'promptSayIt');
    });
  });

  group('Design B — early-listen', () {
    test('EarlyVoiceDetected → celebFirst + saidItFirst', () {
      final fsm = _bootedThroughSpeakWord();
      final effects = fsm.handle(const EarlyVoiceDetected());
      expect(fsm.phase, NamingPhase.celebFirst);
      final feedback = effects.whereType<PlayFeedback>().first;
      expect(feedback.kindName, 'saidItFirst');
      // Mic closed so the celebration audio doesn't feed back in.
      expect(effects.whereType<CloseMic>().length, 1);
    });

    test('celebFirst + VoiceMatched → advance, score +1, path=Y', () {
      final fsm = _bootedThroughSpeakWord();
      fsm.handle(const EarlyVoiceDetected());
      fsm.handle(const VoiceMatched());
      expect(fsm.currentIndex, 1);
      expect(fsm.score, 1);
      expect(fsm.lastPath, NamingPath.y);
    });

    test('celebFirst + VoiceUnmatched → advance, score +1, path=X', () {
      final fsm = _bootedThroughSpeakWord();
      fsm.handle(const EarlyVoiceDetected());
      fsm.handle(const VoiceUnmatched());
      expect(fsm.currentIndex, 1);
      expect(fsm.score, 1);
      expect(fsm.lastPath, NamingPath.x);
    });

    test('celebFirst + ListenTimedOut → still Path X (credit given)', () {
      final fsm = _bootedThroughSpeakWord();
      fsm.handle(const EarlyVoiceDetected());
      fsm.handle(const ListenTimedOut());
      expect(fsm.currentIndex, 1);
      expect(fsm.score, 1);
      expect(fsm.lastPath, NamingPath.x);
    });
  });

  group('Main LISTEN branches', () {
    test('VoiceMatched → celebY, saidIt, score +1, path=Y', () {
      final fsm = _bootedThroughSpeakWord();
      fsm.handle(const EarlyWindowExpired());
      fsm.handle(const AudioFinished()); // prompt finished
      expect(fsm.phase, NamingPhase.listen);
      final effects = fsm.handle(const VoiceMatched());
      expect(fsm.phase, NamingPhase.celebY);
      expect(fsm.lastPath, NamingPath.y);
      expect(fsm.score, 1);
      expect(effects.whereType<PlayFeedback>().first.kindName, 'saidIt');
    });

    test('VoiceUnmatched → celebX, niceTry, score +1, path=X', () {
      final fsm = _bootedThroughSpeakWord();
      fsm.handle(const EarlyWindowExpired());
      fsm.handle(const AudioFinished());
      final effects = fsm.handle(const VoiceUnmatched());
      expect(fsm.phase, NamingPhase.celebX);
      expect(fsm.lastPath, NamingPath.x);
      expect(fsm.score, 1);
      expect(effects.whereType<PlayFeedback>().first.kindName, 'niceTry');
    });

    test('CardTapped → celebZ, good, score +1, path=Z', () {
      final fsm = _bootedThroughSpeakWord();
      fsm.handle(const EarlyWindowExpired());
      fsm.handle(const AudioFinished());
      final effects = fsm.handle(const CardTapped());
      expect(fsm.phase, NamingPhase.celebZ);
      expect(fsm.lastPath, NamingPath.z);
      expect(fsm.score, 1);
      expect(effects.whereType<PlayFeedback>().first.kindName, 'good');
    });
  });

  group('Rule 3 — silence handling', () {
    test('first silence → reprompt (word audio replay + Lets try)', () {
      final fsm = _bootedThroughSpeakWord();
      fsm.handle(const EarlyWindowExpired());
      fsm.handle(const AudioFinished());
      final effects = fsm.handle(const ListenTimedOut());
      expect(fsm.phase, NamingPhase.reprompt);
      expect(fsm.score, 0); // silence does NOT bump the score
      expect(effects.whereType<PlayFeedback>().first.kindName, 'promptLetsTry');
      expect(effects.whereType<ReplayCurrentWord>().length, 1);
    });

    test('second silence → advance silently, path=silent, no score bump', () {
      final fsm = _bootedThroughSpeakWord();
      fsm.handle(const EarlyWindowExpired());
      fsm.handle(const AudioFinished());
      fsm.handle(const ListenTimedOut()); // first silence → reprompt
      fsm.handle(const RepromptFinished()); // back to earlyListen
      fsm.handle(const EarlyWindowExpired());
      fsm.handle(const AudioFinished());
      fsm.handle(const ListenTimedOut()); // second silence → advance
      expect(fsm.currentIndex, 1);
      expect(fsm.score, 0);
      expect(fsm.lastPath, NamingPath.silent);
    });
  });

  group('Round completion', () {
    test('6 tap-only rounds → session complete, score=6', () {
      final fsm = NamingStateMachine();
      final endEffects = <NamingEffect>[];
      fsm.handle(StartRound(_sixWords));
      for (var i = 0; i < 6; i++) {
        fsm.handle(const AudioFinished()); // word audio done
        fsm.handle(const EarlyWindowExpired());
        fsm.handle(const AudioFinished()); // prompt done
        fsm.handle(const CardTapped());
        endEffects.addAll(fsm.handle(const CelebrationDone()));
      }
      expect(fsm.phase, NamingPhase.sessionComplete);
      expect(fsm.score, 6);
      expect(
        endEffects.whereType<SessionCompleted>().length,
        1,
      );
    });

    test('6 rounds mixing all paths → score matches vocalized+tapped count', () {
      final fsm = NamingStateMachine();
      fsm.handle(StartRound(_sixWords));

      // Word 0: Path Y (matched)
      fsm.handle(const AudioFinished());
      fsm.handle(const EarlyWindowExpired());
      fsm.handle(const AudioFinished());
      fsm.handle(const VoiceMatched());
      fsm.handle(const CelebrationDone());

      // Word 1: Path X (vocalized, unmatched)
      fsm.handle(const AudioFinished());
      fsm.handle(const EarlyWindowExpired());
      fsm.handle(const AudioFinished());
      fsm.handle(const VoiceUnmatched());
      fsm.handle(const CelebrationDone());

      // Word 2: Path Z (tap)
      fsm.handle(const AudioFinished());
      fsm.handle(const EarlyWindowExpired());
      fsm.handle(const AudioFinished());
      fsm.handle(const CardTapped());
      fsm.handle(const CelebrationDone());

      // Word 3: silent-advance (two timeouts)
      fsm.handle(const AudioFinished());
      fsm.handle(const EarlyWindowExpired());
      fsm.handle(const AudioFinished());
      fsm.handle(const ListenTimedOut());
      fsm.handle(const RepromptFinished());
      fsm.handle(const EarlyWindowExpired());
      fsm.handle(const AudioFinished());
      fsm.handle(const ListenTimedOut()); // silent advance, no bump

      // Word 4: eager-listen matched
      fsm.handle(const AudioFinished());
      fsm.handle(const EarlyVoiceDetected());
      fsm.handle(const VoiceMatched()); // celebFirst → advance immediately

      // Word 5: tap
      fsm.handle(const AudioFinished());
      fsm.handle(const EarlyWindowExpired());
      fsm.handle(const AudioFinished());
      fsm.handle(const CardTapped());
      fsm.handle(const CelebrationDone());

      // Expected: 5 successful paths (Y, X, Z, celebFirst-Y, Z) + 1 silent
      expect(fsm.phase, NamingPhase.sessionComplete);
      expect(fsm.score, 5);
    });
  });
}
