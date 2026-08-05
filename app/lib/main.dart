import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/repositories/content_repository.dart';
import 'features/game_naming/naming_game_screen.dart';
import 'shared/providers/content_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load content for English pack at startup
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
      theme: _buildTheme(),
      home: const HomeScreen(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFF9800),
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.nunitoTextTheme(),
      useMaterial3: true,
    );
  }
}

// ── Home Screen ───────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(activeLocaleProvider);
    final isHindi = locale == 'hi';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Character ──────────────────────────────────
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE082),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🦁', style: TextStyle(fontSize: 80)),
                  ),
                ),

                const SizedBox(height: 32),

                // ── App name ───────────────────────────────────
                Text(
                  isHindi ? 'बोलो' : 'Bolo',
                  style: GoogleFonts.nunito(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFE65100),
                    letterSpacing: -1,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  isHindi
                      ? 'बच्चों के लिए बोलना सीखें'
                      : 'Speech-play for little ones',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    color: Colors.brown.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // ── Language toggle ────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _langChip(ref, 'en', 'English', !isHindi),
                      _langChip(ref, 'hi', 'हिन्दी', isHindi),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // ── Let's play button ──────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 72,
                  child: ElevatedButton(
                    onPressed: () => _startGame(context, locale),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE65100),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(36),
                      ),
                      elevation: 6,
                    ),
                    child: Text(
                      isHindi ? 'चलो खेलें! 🎮' : "Let's play! 🎮",
                      style: GoogleFonts.nunito(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
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

  void _startGame(BuildContext context, String locale) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NamingGameScreen(
          ageBand: '2-3',
          locale: locale,
        ),
      ),
    );
  }

  Widget _langChip(
      WidgetRef ref, String lang, String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        ref.read(activeLocaleProvider.notifier).state = lang;
        // Reload content for the new locale
        ContentRepository.initialize(lang);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE65100)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : Colors.brown.shade400,
          ),
        ),
      ),
    );
  }
}
