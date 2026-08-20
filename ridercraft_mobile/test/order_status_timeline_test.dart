import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ridercraft_mobile/screens/orders/order_status_style.dart';
import 'package:ridercraft_mobile/screens/orders/order_status_timeline.dart';
import 'package:ridercraft_mobile/theme/app_theme.dart';
import 'package:ridercraft_mobile/utils/formatters.dart';

void _setViewport(
  WidgetTester tester, {
  required double width,
  required double height,
  required double textScale,
}) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(width, height);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

void main() {
  setUpAll(Formatters.ensureDateSymbols);

  group('OrderStatusStyle', () {
    test('maps the four backend statuses to steps', () {
      expect(OrderStatusStyle.steps,
          ['placed', 'processing', 'shipped', 'delivered']);
      expect(OrderStatusStyle.stepIndex('placed'), 0);
      expect(OrderStatusStyle.stepIndex('processing'), 1);
      expect(OrderStatusStyle.stepIndex('shipped'), 2);
      expect(OrderStatusStyle.stepIndex('delivered'), 3);
    });

    test('unknown statuses fall back to the first step without inventing', () {
      expect(OrderStatusStyle.stepIndex('cancelled'), 0);
      expect(OrderStatusStyle.stepLabel('cancelled'), 'Placed');
    });

    test('labels come from the model, not invented vocabulary', () {
      expect(OrderStatusStyle.stepLabel('placed'), 'Placed');
      expect(OrderStatusStyle.stepLabel('shipped'), 'Shipped');
    });
  });

  group('OrderStatusTimeline', () {
    for (final status in const [
      'placed',
      'processing',
      'shipped',
      'delivered',
    ]) {
      testWidgets('status "$status" renders its own current-state line', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: OrderStatusTimeline(status: status),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final label = OrderStatusStyle.stepLabel(status);
        expect(
          find.text('Current status: $label'),
          findsOneWidget,
          reason: 'current status must be spelled out, not color-only',
        );
        for (final step in OrderStatusStyle.stepLabels) {
          expect(find.text(step), findsWidgets);
        }
      });
    }

    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('no overflow at 320px width and ${scale}x text', (tester) async {
        _setViewport(tester, width: 320, height: 640, textScale: scale);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: OrderStatusTimeline(status: 'processing'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull,
            reason: 'overflow for the timeline at $scale x text');
      });
    }
  });
}