// Smoke test for the RiderCraft app shell: the splash brand mark renders the
// RiderCraft logo asset without throwing.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ridercraft_mobile/theme/app_theme.dart';
import 'package:ridercraft_mobile/widgets/app_logo.dart';

void main() {
  testWidgets('AppLogo renders the RiderCraft brand asset', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const AppLogo(),
      ),
    );
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/ridercraft-logo.png',
      ),
      findsOneWidget,
    );
  });
}
