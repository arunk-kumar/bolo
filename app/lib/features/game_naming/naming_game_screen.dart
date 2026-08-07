import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/bolo_colors.dart';
import '../../core/theme/bolo_dimens.dart';
import '../../core/theme/bolo_typography.dart';
import '../../data/generated/word_emoji.g.dart';
import '../../data/models/word_entry.dart';
import '../../data/repositories/content_repository.dart';
import '../../shared/audio/audio_service.dart';
import '../../shared/providers/content_provider.dart';

/// The naming game — MVP's only game screen.
///
/// Layout matches Design System v0.2 §03 (Word Game phone frame):
///   status bar → close + progress bar + ⭐ score → word card → English
///   label → tap hint. Six words per round. Bilingual pairing is Phase 2.
class NamingGameScreen extends ConsumerStatefulWidget {
  /// Optional category filter (e.g. `animals`, `food`). When null the round
  /// draws from every category — used for the "mixed" fallback.
  final String? category;

  /// Optional label shown in the app bar (the stage name). Defaults to
  /// `"Play"` when no category is given.
  final String? title;

  const NamingGameScreen({super.key, this.category, this.title});

  @override
  ConsumerState<NamingGameScreen> createState() => _NamingGameScreenState();
}

class _NamingGameScreenState extends ConsumerState<NamingGameScreen> {
  late List<WordEntry> _roundWords;
  int _currentIndex = 0;
  int _score = 0;
  bool _showReward = false;
  bool _sessionComplete = false;

  @override
  void initState() {
    super.initState();
    _loadRound();
  }

  void _loadRound() {
    // Age band comes from the Riverpod state — the parent-picker (Phase 2
    // onboarding) writes there; MVP defaults to 2-3.
    final ageBand = ref.read(ageBandProvider);
    _roundWords = ContentRepository.instance.roundWords(
      ageBand: ageBand,
      category: widget.category,
      count: 6,
    );
    _currentIndex = 0;
    _score = 0;
    _sessionComplete = false;
    // Speak first word after the UI is rendered.
    Future.delayed(const Duration(milliseconds: 600), _speakCurrentWord);
  }

  void _speakCurrentWord() {
    if (!mounted || _sessionComplete || _roundWords.isEmpty) return;
    AudioService.playWord(_current.audioAsset);
  }

  WordEntry get _current => _roundWords[_currentIndex];

  void _onTap() {
    if (_showReward || _sessionComplete) return;
    // Fire-and-forget — audio initialises from this gesture handler,
    // satisfying the browser's user-gesture policy on Flutter web.
    AudioService.playTap();
    setState(() => _showReward = true);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) AudioService.playReward();
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _showReward = false;
        _score++;
        if (_currentIndex < _roundWords.length - 1) {
          _currentIndex++;
          Future.delayed(const Duration(milliseconds: 400), _speakCurrentWord);
        } else {
          _sessionComplete = true;
          AudioService.playSessionComplete();
        }
      });
    });
  }

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
          current: _currentIndex,
          total: _roundWords.length,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: const BoxDecoration(
                  color: BoloColors.turmeric,
                  borderRadius: BoloRadius.pillAll,
                ),
                child: Text(
                  '⭐ $_score',
                  style: BoloTypography.numericDisplay(
                    size: 15,
                    color: BoloColors.ink,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 520;
          Widget content;
          if (_roundWords.isEmpty) {
            content = _EmptyPoolView(category: widget.category);
          } else if (_sessionComplete) {
            content = _SessionCompleteView(
              score: _score,
              total: _roundWords.length,
              onPlayAgain: () => setState(_loadRound),
            );
          } else {
            content = _GameView(
              word: _current,
              showReward: _showReward,
              onTap: _onTap,
            );
          }
          if (isWide) {
            content = Center(
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
}

// ── Game view (one word card) ─────────────────────────────────────

class _GameView extends StatelessWidget {
  final WordEntry word;
  final bool showReward;
  final VoidCallback onTap;

  const _GameView({
    required this.word,
    required this.showReward,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color:
                      showReward ? BoloColors.turmeric.withValues(alpha: 0.35) : Colors.white,
                  borderRadius: BoloRadius.xlAll,
                  boxShadow: showReward
                      ? BoloShadow.lift
                      : BoloShadow.wordCard,
                  border: Border.all(
                    color: BoloColors.turmeric.withValues(alpha: 0.35),
                    width: 3,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _WordImagePlaceholder(wordId: word.id),
                    if (showReward)
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
            )
                .animate(target: showReward ? 1 : 0)
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.04, 1.04),
                  duration: 150.ms,
                ),
          ),
        ),

        const SizedBox(height: 24),

        // ── Word label (English only at MVP) ─────────────────────
        Text(
          word.word,
          style: BoloTypography.wordDisplay(color: BoloColors.saffron),
        ),

        const SizedBox(height: 16),

        // ── Tap hint ─────────────────────────────────────────────
        if (!showReward)
          Text(
            'Tap to say it! 👆',
            style: BoloTypography.body(color: BoloColors.ink3)
                .copyWith(fontSize: 14, fontWeight: FontWeight.w700),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeIn(duration: 600.ms)
              .fadeOut(delay: 600.ms, duration: 600.ms),

        const SizedBox(height: 32),
      ],
    );
  }
}

// ── Word image placeholder ────────────────────────────────────────

class _WordImagePlaceholder extends StatelessWidget {
  final String wordId;

  const _WordImagePlaceholder({required this.wordId});

  @override
  Widget build(BuildContext context) {
    // Falls back to the generated map. This is a *placeholder* — the real
    // deliverable is a Rive 2D animation per word (elephant trunk swing,
    // lion mouth-open + roar, etc). Track in ART todo.
    final emoji = wordEmoji[wordId] ?? '🎯';
    return Center(
      child: Text(emoji, style: const TextStyle(fontSize: 120)),
    );
  }
}

// ── Empty pool view (safety net) ──────────────────────────────────
//
// Rendered when the age × category pool is empty. Shouldn't happen in
// production — the repository widens the pool before we hit this — but it
// keeps the app from crashing while content grows.

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

// ── Reward burst ──────────────────────────────────────────────────

class _RewardBurst extends StatelessWidget {
  const _RewardBurst();

  @override
  Widget build(BuildContext context) {
    return const Text('⭐', style: TextStyle(fontSize: 72));
  }
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

// ── Session complete view ─────────────────────────────────────────

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
