import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ridercraft_mobile/models/order.dart';
import 'package:ridercraft_mobile/screens/orders/order_detail_screen.dart';
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

Order _order() => Order(
      id: 'A1B2C3D4E5F6',
      items: const [
        OrderItem(
          productId: 'p1',
          variantId: 'v1',
          variantSku: 'RCJ-BLK-XL',
          color: 'Matte Black',
          size: 'XL',
          name: 'Riding Jacket',
          price: 4999,
          qty: 2,
          image: '',
        ),
        OrderItem(
          productId: 'p2',
          variantId: 'v2',
          variantSku: 'RCG-ORANGE-M',
          color: 'Hunter Orange',
          size: 'M',
          name: 'Gloves',
          price: 1499,
          qty: 1,
          image: '',
        ),
      ],
      subtotal: 11497,
      tax: 0,
      shipping: 0,
      discount: 250,
      total: 11247,
      promoCode: 'RIDE10',
      paymentMethod: 'card',
      paymentStatus: 'paid',
      status: 'shipped',
      deliveryAddress: 'Apartment 12B, Sector 44 Noida, Uttar Pradesh 201301',
      contactNumber: '+91 98765 43210',
      createdAt: DateTime(2026, 8, 15, 10, 30),
    );

Future<void> _pump(
  WidgetTester tester, {
  double width = 390,
  double height = 844,
  double textScale = 1.0,
}) async {
  _setViewport(tester, width: width, height: height, textScale: textScale);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: OrderDetailScreen(order: _order()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(Formatters.ensureDateSymbols);

  testWidgets('shows the order header with number, date and status', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Order Details'), findsOneWidget);
    expect(find.text('Order #A1B2C3D4E5F6'), findsOneWidget);
    expect(find.text('15 Aug 2026'), findsOneWidget);
    expect(find.text('Shipped'), findsWidgets);
  });

  testWidgets('renders the status timeline with the current step', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.byType(OrderStatusTimeline), findsOneWidget);
    expect(find.text('ORDER STATUS'), findsOneWidget);
    expect(find.text('Current status: Shipped'), findsOneWidget);
    for (final step in const ['Placed', 'Processing', 'Shipped', 'Delivered']) {
      expect(find.text(step), findsWidgets);
    }
  });

  testWidgets('renders items with variant, quantity and line totals', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('ITEMS (2)'), findsOneWidget);
    expect(find.text('Riding Jacket'), findsOneWidget);
    expect(find.text('Gloves'), findsOneWidget);
    expect(find.text('Matte Black · Size XL · RCJ-BLK-XL'), findsOneWidget);
    expect(find.text('Qty 2 × ₹4,999'), findsOneWidget);
    expect(find.text('₹9,998'), findsWidgets); // 2 × 4,999 line total
  });

  testWidgets('renders payment totals and payment state', (tester) async {
    await _pump(tester);

    expect(find.text('PAYMENT'), findsOneWidget);
    expect(find.text('Subtotal'), findsOneWidget);
    expect(find.text('₹11,497'), findsOneWidget);
    expect(find.text('Discount'), findsOneWidget);
    expect(find.text('- ₹250'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('₹11,247'), findsWidgets);
    expect(find.text('Card · Paid'), findsOneWidget);
    expect(find.text('Coupon RIDE10'), findsOneWidget);
  });

  testWidgets('renders delivery information from the order fields', (
    tester,
  ) async {
    await _pump(tester);
    // Delivery sits below the default test viewport fold; scroll to it.
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.text('DELIVERY'), findsOneWidget);
    expect(
      find.text('Apartment 12B, Sector 44 Noida, Uttar Pradesh 201301'),
      findsOneWidget,
    );
    expect(find.text('+91 98765 43210'), findsOneWidget);
  });

  for (final width in const [320.0, 360.0, 390.0, 430.0]) {
    for (final scale in const [1.0, 1.3, 2.0]) {
      testWidgets(
          'no overflow at ${width}px width and ${scale}x text (long content)',
          (tester) async {
        await _pump(tester, width: width, height: 844, textScale: scale);

        expect(tester.takeException(), isNull,
            reason: 'overflow at ${width}px / ${scale}x');

        await tester.drag(find.byType(ListView), const Offset(0, -2000));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: 'overflow after scrolling at ${width}px / ${scale}x');
      });
    }
  }
}