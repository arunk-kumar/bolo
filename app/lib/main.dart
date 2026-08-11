import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/bolo_theme.dart';
import 'data/repositories/content_repository.dart';
import 'features/home/stage_map_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
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
  // Hydrate the ageBand from prefs so the first game round after a restart
  // draws from the correct pool without waiting for onboarding again.
  final storedBand = prefs.getString(OnboardingScreen.prefsKeyAgeBand);
  final onboarded = prefs.getBool(OnboardingScreen.prefsKeyComplete) ?? false;

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        if (storedBand != null)
          ageBandProvider.overrideWith((_) => storedBand),
      ],
      child: BoloApp(onboarded: onboarded),
    ),
  );
}

class BoloApp extends StatelessWidget {
  final bool onboarded;
  const BoloApp({super.key, required this.onboarded});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bolo',
      debugShowCheckedModeBanner: false,
      theme: BoloTheme.light(),
      home: onboarded ? const StageMapScreen() : const OnboardingScreen(),
    );
  }
}
