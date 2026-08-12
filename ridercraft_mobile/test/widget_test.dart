// Smoke test for the RiderCraft app shell: the splash screen renders the
// brand mark without throwing.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ridercraft_mobile/theme/app_theme.dart';
import 'package:ridercraft_mobile/widgets/app_logo.dart';

void main() {
  testWidgets('AppLogo renders the RiderCraft mark', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const AppLogo(),
      ),
    );

    expect(find.text('RiderCraft'), findsOneWidget);
    expect(find.byIcon(Icons.sports_motorsports_rounded), findsOneWidget);
  });
}
