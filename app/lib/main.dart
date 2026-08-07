import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/bolo_theme.dart';
import 'data/repositories/content_repository.dart';
import 'features/home/stage_map_screen.dart';
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
      home: const StageMapScreen(),
    );
  }
}
