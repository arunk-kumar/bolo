import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/bolo_colors.dart';
import '../../core/theme/bolo_dimens.dart';
import '../../core/theme/bolo_typography.dart';
import '../../data/generated/word_emoji.g.dart';
import '../../data/repositories/content_repository.dart';
import '../../shared/audio/audio_service.dart';
import '../../shared/audio/speech_recognition_service.dart';
import '../../shared/providers/content_provider.dart';
import '../parent/progress_service.dart';
import 'naming_state_machine.dart';

/// Version C — speech-first naming game.
///
/// The screen is glue between three things:
///   1. [NamingStateMachine]        — pure logic per docs/design/version-c-plan.md
///   2. [SpeechRecognitionService]  — mic + on-device STT
///   3. [AudioService]              — pre-recorded feedback playback
///
/// Every widget-facing state (card tappable? glow on? star-burst?) is
/// derived from `_fsm.phase`; every side effect is dispatched by
/// [_runEffect]. See §3 of the plan for the FSM diagram.
class NamingGameScreen extends ConsumerStatefulWidget {
  /// Optional category filter (e.g. `animals`, `food`). When null, the
  /// round draws from every category.
  final String? category;

  /// Optional label shown in the app bar (the stage name).
  final String? title;

  const NamingGameScreen({super.key, this.category, this.title});

  @override
  ConsumerState<NamingGameScreen> createState() => _NamingGameScreenState();
}

class _NamingGameScreenState extends ConsumerState<NamingGameScreen> {
  final NamingStateMachine _fsm = NamingStateMachine();
  final SpeechRecognitionService _stt = SpeechRecognitionService();

  StreamSubscription<SpeechEvent>? _speechSub;
  Timer? _phaseTimer;

  /// Latest amplitude 0..1 for the card-border glow visualization
  /// (Design C — "mic amplitude visualization: yes").
  double _micLevel = 0.0;

  /// Set true briefly whenever Path Y fires so the score pill's
  /// star-burst overlay is triggered (Q6a).
  bool _showStarBurst = false;

  /// Tracks amplitude for the amplitude+duration filter used during
  /// early-listen (Design C — C1c).
  DateTime? _amplitudeAboveThresholdSince;

  static const double _amplitudeThreshold = 0.35; // ~C1c "-30dB" region
  static const Duration _sustainedDurationRequired =
      Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _speechSub?.cancel();
    _phaseTimer?.cancel();
    _stt.stop();
    super.dispose();
  }

  // ── Bootstrap ─────────────────────────────────────────────────────

  Future<void> _bootstrap() async {
    // Initialize STT eagerly. If unavailable, we run in vocalization-only
    // mode (Rule 4 fallback) — the mic still opens; only Path Y is
    // unreachable. UI does not surface the difference per Q1a.
    await _stt.initialize();

    final ageBand = ref.read(ageBandProvider);
    final words = ContentRepository.instance.roundWords(
      ageBand: ageBand,
      category: widget.category,
      count: 6,
    );
    if (!mounted) return;
    if (words.isEmpty) {
      setState(() {}); // triggers the empty-pool view
      return;
    }
    final refs = words
        .map((w) => WordRef(id: w.id, word: w.word, audioAsset: w.audioAsset))
        .toList();
    _pump(StartRound(refs));
  }

  // ── FSM pump + effect dispatch ────────────────────────────────────

  void _pump(NamingEvent event) {
    if (!mounted) return;
    final prevScore = _fsm.score;
    final effects = _fsm.handle(event);
    // Fire the star-burst overlay on the score pill IF this event
    // resolved into a Path Y (matched word). Score bumping alone isn't
    // enough — Path X/Z also bump; the burst is Y-specific per Q6a.
    final scoreBumped = _fsm.score > prevScore;
    final justMatchedWord = scoreBumped && _fsm.lastPath == NamingPath.y;
    setState(() {
      if (justMatchedWord) _showStarBurst = true;
    });
    if (justMatchedWord) {
      // Auto-hide the burst after the animation duration used by
      // _ScorePill (400ms scale + 300ms fade @ 500ms delay = 800ms total).
      Timer(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => _showStarBurst = false);
      });
    }
    _runEffects(effects);
  }

  Future<void> _runEffects(List<NamingEffect> effects) async {
    for (final effect in effects) {
      if (!mounted) return;
      await _runEffect(effect);
    }
  }

  Future<void> _runEffect(NamingEffect effect) async {
    switch (effect) {
      case PlayWordAudio(:final assetPath):
        await AudioService.playWordAndWait(assetPath);
        if (!mounted) return;
        _pump(const AudioFinished());

      case PlayFeedback(:final kindName):
        final kind = _kindFrom(kindName);
        if (kind == null) return;
        await AudioService.playFeedback(kind);
        if (!mounted) return;
        _pumpAfterFeedback(kind);

      case OpenEarlyListen(:final duration):
        _openEarlyListen(duration);

      case OpenListen(:final timeout):
        _openListen(timeout);

      case CloseMic():
        _closeMic();

      case Advance():
        // The FSM already advanced internally; the resulting effects
        // (PlayWordAudio for the next word) are enqueued after this in
        // the same effect list. Nothing to do here.
        break;

      case ReplayCurrentWord():
        await AudioService.playWordAndWait(_fsm.currentWord.audioAsset);
        if (!mounted) return;
        _pump(const RepromptFinished());

      case SessionCompleted(:final score):
        await _onSessionComplete(score);
    }
  }

  /// After a feedback clip finishes, decide which FSM event to pump. The
  /// choice is context-dependent because different clips serve different
  /// FSM transitions.
  void _pumpAfterFeedback(FeedbackKind kind) {
    switch (kind) {
      case FeedbackKind.promptNowYou:
      case FeedbackKind.promptSayIt:
        // Turn prompt done → SPEAK_PROMPT → LISTEN.
        _pump(const AudioFinished());
      case FeedbackKind.saidIt:
      case FeedbackKind.saidItFirst:
      case FeedbackKind.niceTry:
      case FeedbackKind.good:
        // Celebration done → advance to next word.
        _pump(const CelebrationDone());
      case FeedbackKind.promptLetsTry:
        // "Let's try again" clip finished; the ReplayCurrentWord effect
        // fires next in the queue and will pump RepromptFinished when
        // the word replay itself ends.
        break;
    }
  }

  FeedbackKind? _kindFrom(String name) {
    for (final k in FeedbackKind.values) {
      if (k.name == name) return k;
    }
    return null;
  }

  // ── Mic control ───────────────────────────────────────────────────

  void _openEarlyListen(Duration duration) {
    _amplitudeAboveThresholdSince = null;
    _speechSub?.cancel();
    _speechSub = _stt.listen(timeout: duration).listen(_onEarlySpeechEvent);
    _phaseTimer?.cancel();
    _phaseTimer = Timer(duration, () {
      if (!mounted) return;
      if (_fsm.phase != NamingPhase.earlyListen) return;
      _pump(const EarlyWindowExpired());
    });
  }

  void _openListen(Duration timeout) {
    _speechSub?.cancel();
    _speechSub = _stt.listen(timeout: timeout).listen(_onListenSpeechEvent);
    _phaseTimer?.cancel();
    _phaseTimer = Timer(timeout, () {
      if (!mounted) return;
      if (_fsm.phase != NamingPhase.listen) return;
      _pump(const ListenTimedOut());
    });
  }

  void _closeMic() {
    _speechSub?.cancel();
    _speechSub = null;
    _phaseTimer?.cancel();
    _phaseTimer = null;
    _stt.stop();
    if (_micLevel != 0.0) {
      setState(() => _micLevel = 0.0);
    }
  }

  // ── Speech event handlers ─────────────────────────────────────────

  void _onEarlySpeechEvent(SpeechEvent event) {
    // Early-listen only cares about amplitude (Design B — 400ms window,
    // amplitude-only detection). Transcripts are ignored here; the mic
    // will re-open with full STT for the main listen phase.
    if (event is AmplitudeEvent) {
      _updateMicLevel(event.level);
      _observeAmplitudeForSustain(event.level, () {
        _pump(const EarlyVoiceDetected());
      });
    }
  }

  void _onListenSpeechEvent(SpeechEvent event) {
    if (event is AmplitudeEvent) {
      _updateMicLevel(event.level);
    } else if (event is TranscriptEvent) {
      // Rule E1 — act only on the final transcript.
      if (!event.isFinal) return;
      if (_fsm.phase != NamingPhase.listen) return;
      final matched = NamingStateMachine.matchesTarget(
        event.text,
        _fsm.currentWord.word,
      );
      _pump(matched ? const VoiceMatched() : const VoiceUnmatched());
    }
  }

  void _updateMicLevel(double level) {
    // Small EMA to keep the glow from jittering with every packet.
    const alpha = 0.4;
    final smoothed = alpha * level + (1 - alpha) * _micLevel;
    if ((smoothed - _micLevel).abs() < 0.02) return;
    setState(() => _micLevel = smoothed);
  }

  /// Rule C1c — count amplitude spikes only when they sustain above
  /// [_amplitudeThreshold] for [_sustainedDurationRequired] contiguous
  /// milliseconds. Filters brief background spikes (car horns, coughs).
  void _observeAmplitudeForSustain(double level, VoidCallback onSustained) {
    final now = DateTime.now();
    if (level >= _amplitudeThreshold) {
      _amplitudeAboveThresholdSince ??= now;
      final held = now.difference(_amplitudeAboveThresholdSince!);
      if (held >= _sustainedDurationRequired) {
        _amplitudeAboveThresholdSince = null;
        onSustained();
      }
    } else {
      _amplitudeAboveThresholdSince = null;
    }
  }

  // ── Session complete ──────────────────────────────────────────────

  Future<void> _onSessionComplete(int score) async {
    // Path Y star-burst may still be showing from the last word; let it
    // finish before firing the crowd cheer.
    await AudioService.playSessionComplete();
    if (!mounted) return;
    // Record round completion (Rule 6a — score = engagements).
    await ref.read(progressServiceProvider).recordRoundComplete(
      wordsSpoken: score,
      category: widget.category,
    );
    if (!mounted) return;
    ref.read(progressBumpProvider.notifier).state++;
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BoloColors.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: BoloColors.ink2),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: _ProgressBar(
          current: _fsm.currentIndex,
          total: _fsm.roundLength == 0 ? 6 : _fsm.roundLength,
        ),
        actions: [_ScorePill(score: _fsm.score, burst: _showStarBurst)],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 520;
          final content = _buildContent();
          if (isWide) {
            return Center(
              child: SizedBox(
                width: BoloLayout.contentMaxWidth,
                child: content,
              ),
            );
          }
          return content;
        },
      ),
    );
  }

  Widget _buildContent() {
    // Bootstrap or empty-pool cases first.
    if (_fsm.phase == NamingPhase.idle) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_fsm.roundLength == 0) {
      return _EmptyPoolView(category: widget.category);
    }
    if (_fsm.phase == NamingPhase.sessionComplete) {
      return _SessionCompleteView(
        score: _fsm.score,
        total: _fsm.roundLength,
        onPlayAgain: () {
          setState(() {
            _fsm.phase = NamingPhase.idle;
          });
          _bootstrap();
        },
      );
    }
    return _GameView(
      word: _fsm.currentWord,
      phase: _fsm.phase,
      micLevel: _micLevel,
      onTap: _fsm.phase == NamingPhase.listen
          ? () => _pump(const CardTapped())
          : null,
    );
  }
}

// ── GameView — one word card + glow + hint ────────────────────────

class _GameView extends StatelessWidget {
  final WordRef word;
  final NamingPhase phase;
  final double micLevel;
  final VoidCallback? onTap;

  const _GameView({
    required this.word,
    required this.phase,
    required this.micLevel,
    required this.onTap,
  });

  bool get _showGlow =>
      phase == NamingPhase.listen || phase == NamingPhase.earlyListen;

  bool get _showRewardBurst =>
      phase == NamingPhase.celebY ||
      phase == NamingPhase.celebX ||
      phase == NamingPhase.celebZ ||
      phase == NamingPhase.celebFirst;

  @override
  Widget build(BuildContext context) {
    // Glow opacity — a soft base + amplitude-driven boost during listen.
    final baseGlow = _showGlow ? 0.20 : 0.0;
    final ampBoost = _showGlow ? (micLevel * 0.35) : 0.0;
    final glowAlpha = (baseGlow + ampBoost).clamp(0.0, 0.7);

    return Column(
      children: [
        const SizedBox(height: 16),

        // ── Word card (the big tap target) ───────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GestureDetector(
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BoloRadius.xlAll,
                  boxShadow: [
                    // Base soft card shadow — always present.
                    ...BoloShadow.wordCard,
                    // Amplitude-responsive saffron glow layered on top
                    // when the mic is open. Fades to 0 when closed.
                    if (glowAlpha > 0)
                      BoxShadow(
                        color: BoloColors.saffron.withValues(alpha: glowAlpha),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                  ],
                  border: Border.all(
                    color: BoloColors.turmeric.withValues(alpha: 0.35),
                    width: 3,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _WordImagePlaceholder(wordId: word.id),
                    if (_showRewardBurst)
                      const _RewardBurst()
                          .animate()
                          .scale(
                            begin: const Offset(0.5, 0.5),
                            end: const Offset(1.2, 1.2),
                            duration: 300.ms,
                            curve: Curves.elasticOut,
                          )
                          .fadeOut(delay: 800.ms, duration: 300.ms),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // ── Word label ───────────────────────────────────────────
        Text(
          word.word,
          style: BoloTypography.wordDisplay(color: BoloColors.saffron),
        ),

        const SizedBox(height: 16),

        // ── Hint text (always visible, pops on entering listen) ──
        _HintText(phase: phase),

        const SizedBox(height: 32),
      ],
    );
  }
}

/// Always-visible hint per Q1b + user's "open book" call. Pops with a
/// gentle scale when entering the LISTEN phase so the child's eye
/// notices "your turn is now" without the copy itself changing.
class _HintText extends StatelessWidget {
  final NamingPhase phase;
  const _HintText({required this.phase});

  @override
  Widget build(BuildContext context) {
    final text = Text(
      '🎤 Say it, or tap!',
      style: BoloTypography.body(color: BoloColors.ink3)
          .copyWith(fontSize: 14, fontWeight: FontWeight.w700),
    );
    if (phase == NamingPhase.listen) {
      // Pop-in bounce every time we (re-)enter listen — the animate key
      // ties to the phase so re-prompt-into-listen retriggers it.
      return text
          .animate(key: const ValueKey('hint-listen'))
          .scale(
            begin: const Offset(0.9, 0.9),
            end: const Offset(1.0, 1.0),
            duration: 200.ms,
            curve: Curves.elasticOut,
          );
    }
    return text;
  }
}

/// Score pill on the AppBar. When a Path Y win comes in, a ⭐ overlay
/// bursts out of the pill (Q6a — visual weight, no math change).
class _ScorePill extends StatelessWidget {
  final int score;
  final bool burst;
  const _ScorePill({required this.score, required this.burst});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Center(
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: const BoxDecoration(
                color: BoloColors.turmeric,
                borderRadius: BoloRadius.pillAll,
              ),
              child: Text(
                '⭐ $score',
                style: BoloTypography.numericDisplay(
                  size: 15,
                  color: BoloColors.ink,
                ),
              ),
            ),
            if (burst)
              const Positioned(
                child: Text('⭐', style: TextStyle(fontSize: 28)),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1.8, 1.8),
                    duration: 400.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeOut(delay: 500.ms, duration: 300.ms),
          ],
        ),
      ),
    );
  }
}

// ── Emoji placeholder (scales to fill the card) ───────────────────

class _WordImagePlaceholder extends StatelessWidget {
  final String wordId;
  const _WordImagePlaceholder({required this.wordId});

  @override
  Widget build(BuildContext context) {
    // FittedBox scales the glyph to fill the card so a small emoji
    // isn't lost inside the big white surface.
    final emoji = wordEmoji[wordId] ?? '🎯';
    return Padding(
      padding: const EdgeInsets.all(24),
      child: FittedBox(
        fit: BoxFit.contain,
        child: Text(emoji, style: const TextStyle(fontSize: 200)),
      ),
    );
  }
}

// ── Empty pool ─────────────────────────────────────────────────────

class _EmptyPoolView extends StatelessWidget {
  final String? category;
  const _EmptyPoolView({required this.category});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🐣', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 24),
            Text(
              'More words coming soon',
              style: BoloTypography.subhead(color: BoloColors.ink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              category == null
                  ? "We're still growing this pack."
                  : "The $category words for this age are still hatching.",
              style: BoloTypography.body(color: BoloColors.ink3),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reward burst (⭐ on the card, per Path Y celebration) ──────────

class _RewardBurst extends StatelessWidget {
  const _RewardBurst();
  @override
  Widget build(BuildContext context) =>
      const Text('⭐', style: TextStyle(fontSize: 72));
}

// ── Progress bar ──────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final int current;
  final int total;
  const _ProgressBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final Color color;
        if (i < current) {
          color = BoloColors.saffron;
        } else if (i == current) {
          color = BoloColors.turmeric;
        } else {
          color = BoloColors.paper3;
        }
        return Expanded(
          child: Container(
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}

// ── Session complete ──────────────────────────────────────────────

class _SessionCompleteView extends StatelessWidget {
  final int score;
  final int total;
  final VoidCallback onPlayAgain;
  const _SessionCompleteView({
    required this.score,
    required this.total,
    required this.onPlayAgain,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [BoloColors.turmeric, BoloColors.saffron],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 80))
                  .animate()
                  .scale(
                    begin: const Offset(0, 0),
                    end: const Offset(1, 1),
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  ),
              const SizedBox(height: 24),
              Text(
                'Amazing!',
                style: BoloTypography.hero(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                '$score / $total words',
                style: BoloTypography.body(color: Colors.white)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onPlayAgain,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: BoloColors.saffron,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BoloRadius.pillAll,
                    ),
                    elevation: 8,
                    shadowColor: Colors.black26,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'Play again! 🔄',
                      style: BoloTypography.subhead(color: BoloColors.saffron)
                          .copyWith(fontSize: 22),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
