import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/word_entry.dart';
import '../../data/repositories/content_repository.dart';
import '../../shared/audio/audio_service.dart';

class NamingGameScreen extends ConsumerStatefulWidget {
  final String ageBand;
  final String locale;

  const NamingGameScreen({
    super.key,
    this.ageBand = '2-3',
    this.locale = 'en',
  });

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
    _roundWords = ContentRepository.instance.roundWords(
      ageBand: widget.ageBand,
      count: 6,
    );
    _currentIndex = 0;
    _score = 0;
    _sessionComplete = false;
  }

  WordEntry get _current => _roundWords[_currentIndex];

  void _onTap() {
    if (_showReward || _sessionComplete) return;
    // Fire-and-forget — audio initialises from within this gesture handler,
    // satisfying the browser's "user gesture required" policy.
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
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.brown),
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
              child: Text(
                '⭐ $_score',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.orange,
                ),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Phone: fill width. Tablet/Desktop: cap at 480, center it.
          final isWide = constraints.maxWidth > 520;
          Widget content = _sessionComplete
              ? _SessionCompleteView(
                  score: _score,
                  total: _roundWords.length,
                  onPlayAgain: () => setState(_loadRound),
                )
              : _GameView(
                  word: _current,
                  locale: widget.locale,
                  showReward: _showReward,
                  onTap: _onTap,
                );
          if (isWide) {
            content = Center(
              child: SizedBox(width: 480, child: content),
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
  final String locale;
  final bool showReward;
  final VoidCallback onTap;

  const _GameView({
    required this.word,
    required this.locale,
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
                  color: showReward
                      ? const Color(0xFFFFE082)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange
                          .withValues(alpha: showReward ? 0.5 : 0.15),
                      blurRadius: showReward ? 32 : 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Image placeholder (replaced with real art later)
                    _WordImagePlaceholder(
                      wordId: word.id,
                      category: word.category,
                    ),

                    // Reward burst
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

        // ── Bilingual word label ──────────────────────────────────
        _BilingualLabel(word: word, locale: locale),

        const SizedBox(height: 16),

        // ── Tap hint ─────────────────────────────────────────────
        if (!showReward)
          Text(
            locale == 'hi' ? 'छूकर देखो! 👆' : 'Tap to say it! 👆',
            style: TextStyle(
              fontSize: 14,
              color: Colors.brown.shade400,
              fontWeight: FontWeight.w600,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeIn(duration: 600.ms)
              .fadeOut(delay: 600.ms, duration: 600.ms),

        const SizedBox(height: 32),
      ],
    );
  }
}

// ── Bilingual label ───────────────────────────────────────────────

class _BilingualLabel extends StatelessWidget {
  final WordEntry word;
  final String locale;

  const _BilingualLabel({required this.word, required this.locale});

  @override
  Widget build(BuildContext context) {
    final isHindi = locale == 'hi';

    return Column(
      children: [
        Text(
          word.word,
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            color: const Color(0xFFE65100),
            fontFamily: isHindi ? 'NotoSansDevanagari' : null,
          ),
        ),
        if (isHindi && word.transliteration != null)
          Text(
            word.transliteration!,
            style: TextStyle(
              fontSize: 18,
              color: Colors.brown.shade400,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

// ── Word image placeholder ────────────────────────────────────────

class _WordImagePlaceholder extends StatelessWidget {
  final String wordId;
  final String category;

  const _WordImagePlaceholder({
    required this.wordId,
    required this.category,
  });

  // Per-word placeholder emojis — replaced with real art later
  static const _wordEmojis = {
    'word_001': '🐱', // cat
    'word_002': '🐶', // dog
    'word_003': '🐄', // cow
    'word_004': '🐦', // bird
    'word_005': '🐘', // elephant
    'word_006': '🥛', // milk
    'word_007': '🍌', // banana
    'word_008': '💧', // water
    'word_009': '🫓', // roti
    'word_010': '🍎', // apple
    'word_011': '👩', // mama
    'word_012': '👨', // papa
    'word_013': '👵', // grandma/nani
    'word_014': '👴', // grandpa/nana
    'word_015': '👶', // baby
    'word_016': '👁️', // eye
    'word_017': '👃', // nose
    'word_018': '🖐️', // hand
    'word_019': '🦶', // foot
    'word_020': '👄', // mouth
  };

  @override
  Widget build(BuildContext context) {
    final emoji = _wordEmojis[wordId] ?? '🎯';
    return Center(
      child: Text(emoji, style: const TextStyle(fontSize: 120)),
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
        return Expanded(
          child: Container(
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: i < current
                  ? const Color(0xFFE65100)
                  : i == current
                      ? const Color(0xFFFFB74D)
                      : Colors.brown.shade100,
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
    return Center(
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
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFE65100),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '$score / $total words',
              style: TextStyle(
                fontSize: 20,
                color: Colors.brown.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: onPlayAgain,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
                child: const Text(
                  'Play again! 🔄',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
