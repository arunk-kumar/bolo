import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bolo/main.dart';

void main() {
  testWidgets('Bolo home screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: BoloApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bolo'), findsOneWidget);
    expect(find.text("Let's play! 🎮"), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('हिन्दी'), findsOneWidget);
  });
}
