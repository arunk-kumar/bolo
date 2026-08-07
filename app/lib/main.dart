import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/bolo_colors.dart';
import 'core/theme/bolo_dimens.dart';
import 'core/theme/bolo_theme.dart';
import 'core/theme/bolo_typography.dart';
import 'data/repositories/content_repository.dart';
import 'features/game_naming/naming_game_screen.dart';
import 'shared/providers/content_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // MVP: English pack only. Hindi and further packs land in Phase 2.
  try {
    await ContentRepository.initialize('en');
  } catch (e) {
    // ignore: avoid_print
    print('ContentRepository init error: $e');
  }

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const BoloApp(),
    ),
  );
}

class BoloApp extends StatelessWidget {
  const BoloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bolo',
      debugShowCheckedModeBanner: false,
      theme: BoloTheme.light(),
      home: const HomeScreen(),
    );
  }
}

// ── Home Screen ───────────────────────────────────────────────────
//
// MVP placeholder — a single "Let's play" CTA. The full stage-map from
// Design System v0.2 §03 lands in the next commit.

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: BoloLayout.contentMaxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Character placeholder ─────────────────────
                  Container(
                    width: 180,
                    height: 180,
                    decoration: const BoxDecoration(
                      color: BoloColors.turmeric,
                      shape: BoxShape.circle,
                      boxShadow: BoloShadow.lift,
                    ),
                    child: const Center(
                      child: Text('🦁', style: TextStyle(fontSize: 80)),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Wordmark ──────────────────────────────────
                  Text('Bolo', style: BoloTypography.wordDisplay()),
                  const SizedBox(height: 8),
                  Text(
                    'Speech-play for little ones',
                    style: BoloTypography.body(color: BoloColors.ink3),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 48),

                  // ── Let's play CTA ────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _startGame(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          "Let's play! 🎮",
                          style: BoloTypography.subhead(color: Colors.white)
                              .copyWith(fontSize: 22),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _startGame(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const NamingGameScreen(ageBand: '2-3'),
      ),
    );
  }
}
