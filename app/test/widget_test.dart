import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bolo/main.dart';
import 'package:bolo/shared/providers/content_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Boots into onboarding on first launch', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: const BoloApp(onboarded: false),
      ),
    );
    // Just enough frames for the animated widgets to render — pumpAndSettle
    // never returns when there's an infinite-loop animation (mic emoji pulse).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Bolo'), findsOneWidget);
    expect(find.text("Let's begin"), findsOneWidget);
  });

  testWidgets('Boots into stage map when already onboarded', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: const BoloApp(onboarded: true),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text("Let's play"), findsOneWidget);
  });
}
