import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ridercraft_mobile/routes/app_routes.dart';
import 'package:ridercraft_mobile/screens/orders/orders_screen.dart';
import 'package:ridercraft_mobile/screens/orders/widgets/order_skeleton.dart';
import 'package:ridercraft_mobile/services/api_client.dart';
import 'package:ridercraft_mobile/services/order_service.dart';
import 'package:ridercraft_mobile/theme/app_theme.dart';
import 'package:ridercraft_mobile/utils/formatters.dart';

ResponseBody _json(String body, int status) => ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

Map<String, dynamic> _order({
  required String id,
  int items = 1,
  String firstName = 'Riding Jacket',
  DateTime? createdAt,
  String status = 'placed',
  String paymentStatus = 'pending',
  String paymentMethod = 'cod',
  double total = 7499,
}) {
  return {
    '_id': id,
    'items': [
      for (var i = 0; i < items; i++)
        {
          'productId': 'p$i',
          'variantId': 'v$i',
          'variantSku': 'RCJ-BLK-L',
          'color': 'Matte Black',
          'size': 'L',
          'name': firstName,
          'price': total,
          'qty': 1,
          'image': '',
        },
    ],
    'subtotal': total,
    'tax': 0,
    'shipping': 0,
    'discount': 0,
    'total': total,
    'promoCode': '',
    'paymentMethod': paymentMethod,
    'paymentStatus': paymentStatus,
    'paymentReference': '',
    'status': status,
    'deliveryAddress': '',
    'contactNumber': '',
    'createdAt': (createdAt ?? DateTime(2026, 8, 15, 10, 30))
        .toUtc()
        .toIso8601String(),
  };
}

/// In-memory backend for `GET /orders/my`.
class _OrdersAdapter implements HttpClientAdapter {
  List<Map<String, dynamic>> orders;
  int failNext;
  Duration? responseDelay;
  int getCalls = 0;

  _OrdersAdapter(
    this.orders, {
    this.failNext = 0,
    this.responseDelay,
  });

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method == 'GET' && options.path == '/orders/my') {
      getCalls++;
      if (responseDelay != null) {
        await Future<void>.delayed(responseDelay!);
      }
      if (getCalls <= failNext) {
        return _json('{"error":"Failed to load orders"}', 500);
      }
      return _json(jsonEncode(orders), 200);
    }
    return _json('{"error":"Not found"}', 404);
  }

  @override
  void close({bool force = false}) {}
}

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

Future<({Widget app, _OrdersAdapter adapter})> _buildApp({
  required WidgetTester tester,
  required List<Map<String, dynamic>> orders,
  int failNext = 0,
  Duration? responseDelay,
  double width = 390,
  double height = 844,
  double textScale = 1.0,
}) async {
  final adapter = _OrdersAdapter(
    orders,
    failNext: failNext,
    responseDelay: responseDelay,
  );
  final api = ApiClient(
    tokenProvider: () => 'test-token',
    dio: Dio()..httpClientAdapter = adapter,
  );
  _setViewport(
    tester,
    width: width,
    height: height,
    textScale: textScale,
  );
  final app = MultiProvider(
    providers: [Provider.value(value: OrderService(api))],
    child: MaterialApp(
      theme: AppTheme.dark,
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: const OrdersScreen(),
    ),
  );
  return (app: app, adapter: adapter);
}

// Mirrors the card's short order number: last eight characters, uppercased.
String _shortId(String id) =>
    id.length > 8 ? id.substring(id.length - 8).toUpperCase() : id;

void main() {
  setUpAll(Formatters.ensureDateSymbols);

  testWidgets('renders the header, live order count and a premium card', (
    tester,
  ) async {
    final bundle = await _buildApp(
      tester: tester,
      orders: [
        _order(id: 'ORD1234567890', items: 2, total: 7747),
        _order(id: 'ORD999988887777', status: 'shipped', items: 1),
      ],
    );
    await tester.pumpWidget(bundle.app);
    await tester.pumpAndSettle();

    expect(find.text('My Orders'), findsOneWidget);
    expect(
      find.text('Track every purchase from checkout to delivery.'),
      findsOneWidget,
    );
    expect(find.text('2 ORDERS'), findsOneWidget);
    // Order card content: number, date, item count, total, status + payment.
    expect(find.text('Order #${_shortId('ORD1234567890')}'), findsOneWidget);
    expect(find.text('Order #${_shortId('ORD999988887777')}'), findsOneWidget);
    expect(find.text('15 Aug'), findsNWidgets(2));
    expect(find.text('2 items'), findsOneWidget);
    expect(find.text('1 item'), findsOneWidget);
    expect(find.text('₹7,747'), findsOneWidget);
    expect(find.text('Placed'), findsWidgets);
    expect(find.text('Shipped'), findsWidgets);
    expect(find.text('Cash on delivery · Pending'), findsNWidgets(2));
  });

  testWidgets('one order renders a singular count', (tester) async {
    final bundle = await _buildApp(
      tester: tester,
      orders: [_order(id: 'ORD1234567890')]);
    await tester.pumpWidget(bundle.app);
    await tester.pumpAndSettle();

    expect(find.text('1 ORDER'), findsOneWidget);
    expect(find.text('1 item'), findsOneWidget);
  });

  testWidgets('shows the skeleton while loading', (tester) async {
    final bundle = await _buildApp(
      tester: tester,
      orders: [_order(id: 'ORD1234567890')],
      responseDelay: const Duration(seconds: 2),
    );
    await tester.pumpWidget(bundle.app);
    await tester.pump();

    expect(find.byType(OrderListSkeleton), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byType(OrderListSkeleton), findsNothing);
    expect(find.text('Order #${_shortId('ORD1234567890')}'), findsOneWidget);
  });

  testWidgets('API error shows the error state and Retry recovers', (
    tester,
  ) async {
    final bundle = await _buildApp(
      tester: tester,
      orders: [_order(id: 'ORD1234567890')],
      failNext: 1,
    );
    await tester.pumpWidget(bundle.app);
    await tester.pumpAndSettle();

    expect(find.text('Failed to load orders'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Order #${_shortId('ORD1234567890')}'), findsOneWidget);
  });

  testWidgets('empty state offers the Explore Shop action', (tester) async {
    final bundle = await _buildApp(
      tester: tester,
      orders: const []);
    await tester.pumpWidget(bundle.app);
    await tester.pumpAndSettle();

    expect(find.text('No orders yet'), findsOneWidget);
    expect(
      find.text('Your next ride essential starts here.'),
      findsOneWidget,
    );
    expect(find.text('EXPLORE SHOP'), findsOneWidget);
  });

  testWidgets('tapping an order opens its detail screen', (tester) async {
    final bundle = await _buildApp(
      tester: tester,
      orders: [_order(id: 'ORD1234567890')]);
    await tester.pumpWidget(bundle.app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Order #${_shortId('ORD1234567890')}'));
    await tester.pumpAndSettle();

    expect(find.text('Order Details'), findsOneWidget);
    expect(find.text('ORDER STATUS'), findsOneWidget);
    expect(find.text('ITEMS (1)'), findsOneWidget);
    expect(find.text('Riding Jacket'), findsOneWidget);
  });

  for (final width in const [320.0, 360.0, 390.0, 430.0]) {
    for (final scale in const [1.0, 1.3, 2.0]) {
      testWidgets(
          'no overflow at ${width}px width and ${scale}x text (long content)',
          (tester) async {
        final bundle = await _buildApp(
      tester: tester,
          // Long ids/names/totals stress the cards at every size.
          orders: [
            _order(
              id: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789ABCDEFGH',
              items: 1,
              firstName:
                  'Premium Waterproof All-Weather Motorcycle Riding Jacket '
                  'with Thermal Liner, Reflective Trim and Magnetic Pockets',
              total: 12500000,
              status: 'processing',
            ),
          ],
          width: width,
          height: 844,
          textScale: scale,
        );
        await tester.pumpWidget(bundle.app);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull,
            reason: 'overflow at ${width}px / ${scale}x');

        await tester.drag(find.byType(ListView), const Offset(0, -1200));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: 'overflow after scrolling at ${width}px / ${scale}x');
      });
    }
  }
}