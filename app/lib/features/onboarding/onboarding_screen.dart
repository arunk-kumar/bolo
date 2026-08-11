import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../core/theme/bolo_colors.dart';
import '../../core/theme/bolo_dimens.dart';
import '../../core/theme/bolo_typography.dart';
import '../../shared/providers/content_provider.dart';
import '../home/stage_map_screen.dart';

/// First-launch onboarding — welcome, age band, mic permission.
///
/// Writes two SharedPreferences keys on completion:
///   `onboarding_complete` = true
///   `age_band`            = "2-3" | "3-4" | "4-5"
/// and updates [ageBandProvider] so the naming game picks the right pool
/// as soon as the child taps in.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static const prefsKeyComplete = 'onboarding_complete';
  static const prefsKeyAgeBand = 'age_band';

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  String _pickedAge = '2-3';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setBool(OnboardingScreen.prefsKeyComplete, true);
    await prefs.setString(OnboardingScreen.prefsKeyAgeBand, _pickedAge);
    ref.read(ageBandProvider.notifier).state = _pickedAge;

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const StageMapScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BoloColors.paper,
      body: SafeArea(
        child: PageView(
          controller: _controller,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _WelcomePage(onNext: () => _goToPage(1)),
            _AgePickerPage(
              picked: _pickedAge,
              onPick: (age) => setState(() => _pickedAge = age),
              onNext: () => _goToPage(2),
            ),
            _MicPermissionPage(onFinish: _finish),
          ],
        ),
      ),
    );
  }
}

// ── Page 1 · Welcome ─────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 2),
          const Text('🌱', style: TextStyle(fontSize: 96))
              .animate()
              .scale(
                begin: const Offset(0, 0),
                end: const Offset(1, 1),
                duration: 700.ms,
                curve: Curves.elasticOut,
              ),
          const SizedBox(height: 24),
          Text('Bolo',
                  textAlign: TextAlign.center,
                  style: BoloTypography.hero(color: BoloColors.saffron))
              .animate()
              .fadeIn(delay: 200.ms, duration: 500.ms)
              .slideY(begin: 0.15, end: 0),
          const SizedBox(height: 12),
          Text(
            'A speech-play space for little ones.',
            textAlign: TextAlign.center,
            style: BoloTypography.body(color: BoloColors.ink2)
                .copyWith(fontSize: 18),
          )
              .animate()
              .fadeIn(delay: 400.ms, duration: 500.ms),
          const Spacer(flex: 3),
          _BigButton(label: "Let's begin", onTap: onNext),
        ],
      ),
    );
  }
}

// ── Page 2 · Age picker ───────────────────────────────────────────

class _AgePickerPage extends StatelessWidget {
  final String picked;
  final ValueChanged<String> onPick;
  final VoidCallback onNext;

  const _AgePickerPage({
    required this.picked,
    required this.onPick,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'How old is your little one?',
            textAlign: TextAlign.center,
            style: BoloTypography.screenTitle(),
          ),
          const SizedBox(height: 8),
          Text(
            "We'll pick words that suit them.",
            textAlign: TextAlign.center,
            style: BoloTypography.body(color: BoloColors.ink3),
          ),
          const SizedBox(height: 40),
          _AgeCard(
            band: '2-3',
            label: '2 to 3 years',
            hint: 'First words · single objects',
            emoji: '👶',
            picked: picked == '2-3',
            onTap: () => onPick('2-3'),
          ),
          const SizedBox(height: 16),
          _AgeCard(
            band: '3-4',
            label: '3 to 4 years',
            hint: 'Growing vocabulary · action words',
            emoji: '🧒',
            picked: picked == '3-4',
            onTap: () => onPick('3-4'),
          ),
          const SizedBox(height: 16),
          _AgeCard(
            band: '4-5',
            label: '4 to 5 years',
            hint: 'Full sentences · colours & concepts',
            emoji: '🧑',
            picked: picked == '4-5',
            onTap: () => onPick('4-5'),
          ),
          const Spacer(),
          _BigButton(label: 'Next', onTap: onNext),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _AgeCard extends StatelessWidget {
  final String band;
  final String label;
  final String hint;
  final String emoji;
  final bool picked;
  final VoidCallback onTap;

  const _AgeCard({
    required this.band,
    required this.label,
    required this.hint,
    required this.emoji,
    required this.picked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BoloRadius.mdAll,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: picked ? BoloColors.turmeric : BoloColors.paper2,
            border: Border.all(
              color: picked ? BoloColors.saffron : BoloColors.paper3,
              width: picked ? 2.5 : 1,
            ),
            borderRadius: BoloRadius.mdAll,
            boxShadow: picked ? BoloShadow.wordCard : BoloShadow.card,
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: BoloTypography.subhead(color: BoloColors.ink)
                          .copyWith(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hint,
                      style: BoloTypography.utilityLabel(
                        color: picked ? BoloColors.saffronD : BoloColors.ink3,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: picked ? BoloColors.saffron : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: picked ? BoloColors.saffron : BoloColors.paper3,
                    width: 2,
                  ),
                ),
                child: picked
                    ? const Icon(Icons.check_rounded,
                        size: 16, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Page 3 · Mic permission ──────────────────────────────────────

class _MicPermissionPage extends StatefulWidget {
  final VoidCallback onFinish;
  const _MicPermissionPage({required this.onFinish});

  @override
  State<_MicPermissionPage> createState() => _MicPermissionPageState();
}

class _MicPermissionPageState extends State<_MicPermissionPage> {
  bool _asking = false;

  Future<void> _requestMic() async {
    setState(() => _asking = true);
    try {
      final speech = stt.SpeechToText();
      // initialize() triggers the OS mic permission prompt on first call.
      // We do not care about the result at MVP — cheer-on-vocalization is
      // Phase 5. This just gets the permission dialog out of the way.
      await speech.initialize(
        onError: (_) {},
        onStatus: (_) {},
      );
    } catch (_) {
      // Web / unsupported platforms just skip through.
    }
    if (!mounted) return;
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 2),
          const Text('🎤', style: TextStyle(fontSize: 80))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.08, 1.08),
                duration: 900.ms,
              ),
          const SizedBox(height: 20),
          Text(
            'One more thing',
            textAlign: TextAlign.center,
            style: BoloTypography.screenTitle(),
          ),
          const SizedBox(height: 12),
          Text(
            'Bolo listens to your little one so it can cheer when they speak.\n\n'
            'No recordings are ever stored or sent anywhere.',
            textAlign: TextAlign.center,
            style: BoloTypography.body(color: BoloColors.ink2)
                .copyWith(fontSize: 16, height: 1.45),
          ),
          const Spacer(flex: 3),
          _BigButton(
            label: _asking ? 'Please wait…' : 'Allow microphone',
            onTap: _asking ? null : _requestMic,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _asking ? null : widget.onFinish,
            child: Text(
              'Skip for now',
              style: BoloTypography.utilityLabel(color: BoloColors.ink3),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Big primary button ───────────────────────────────────────────

class _BigButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _BigButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: BoloColors.saffron,
          disabledBackgroundColor: BoloColors.paper3,
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BoloRadius.pillAll,
          ),
          elevation: 6,
          shadowColor: Colors.black26,
        ),
        child: Text(
          label,
          style: BoloTypography.subhead(color: Colors.white)
              .copyWith(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
