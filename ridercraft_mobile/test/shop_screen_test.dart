import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridercraft_mobile/providers/auth_provider.dart';
import 'package:ridercraft_mobile/providers/cart_provider.dart';
import 'package:ridercraft_mobile/providers/product_provider.dart';
import 'package:ridercraft_mobile/routes/app_routes.dart';
import 'package:ridercraft_mobile/screens/shop/shop_screen.dart';
import 'package:ridercraft_mobile/services/api_client.dart';
import 'package:ridercraft_mobile/services/auth_service.dart';
import 'package:ridercraft_mobile/services/product_service.dart';
import 'package:ridercraft_mobile/services/promo_service.dart';
import 'package:ridercraft_mobile/services/storage_service.dart';
import 'package:ridercraft_mobile/services/token_store.dart';
import 'package:ridercraft_mobile/theme/app_theme.dart';

class _FakeAdapter implements HttpClientAdapter {
  final List<Map<String, dynamic>> products;

  _FakeAdapter(this.products);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = options.path == '/products' ? jsonEncode(products) : '[]';
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _product({
  required String id,
  required String name,
  String brand = 'Shoei',
  String tag = 'Helmets',
  int stock = 12,
  double price = 12999,
}) {
  return {
    '_id': id,
    'name': name,
    'brand': brand,
    'tag': tag,
    'colorFamily': 'Neutral',
    'stock': stock,
    'image': '',
    'sizes': <String>[],
    'colors': <String>[],
    'variants': <Map<String, dynamic>>[],
    'price': price,
    'displayPrice': price,
    'originalPrice': price * 1.3,
    'discountPercent': 23,
    'ratingAverage': 4.6,
    'ratingCount': 42,
  };
}

Future<Widget> _buildApp(List<Map<String, dynamic>> products) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final storage = StorageService(prefs);
  final tokenStore = TokenStore();

  final dio = Dio()..httpClientAdapter = _FakeAdapter(products);
  final api = ApiClient(tokenProvider: () => tokenStore.current, dio: dio);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => AuthProvider(AuthService(api, storage), tokenStore),
      ),
      ChangeNotifierProvider(
        create: (_) => CartProvider(storage, PromoService(api))..load(),
      ),
      ChangeNotifierProvider(
        create: (_) => ProductProvider(ProductService(api)),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      home: const ShopScreen(),
      onGenerateRoute: AppRouter.onGenerateRoute,
    ),
  );
}

// Renders the Shop grid at an exact viewport size and text scalar, then
// confirms neither the initial viewport nor a scroll to the bottom reports a
// layout overflow.
Future<void> _pumpShopAt(
  WidgetTester tester,
  List<Map<String, dynamic>> products, {
  required double width,
  required double height,
  required double textScale,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(width, height);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(await _buildApp(products));
  await tester.pumpAndSettle();

  expect(tester.takeException(), isNull,
      reason: 'overflow in the initial Shop viewport');

  // Build every grid row below the fold too.
  await tester.drag(find.byType(GridView), const Offset(0, -1200));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull,
      reason: 'overflow after scrolling the Shop grid');
}

List<Map<String, dynamic>> _manyProducts(int count) => [
      for (var i = 0; i < count; i++)
        _product(
          id: 'p$i',
          name: 'Ridercraft Premium Full-Face Helmet with Bluetooth $i',
          tag: i.isEven ? 'Helmets' : 'Gloves',
        ),
    ];

void main() {
  testWidgets('renders the real product catalogue from the API', (
    tester,
  ) async {
    final products = [
      _product(id: 'p1', name: 'Rider Helmet Pro', tag: 'Helmets'),
      _product(
        id: 'p2',
        name: 'Trail Gloves',
        brand: 'Alpinestars',
        tag: 'Gloves',
      ),
    ];

    await tester.pumpWidget(await _buildApp(products));
    await tester.pumpAndSettle();

    // Search + tag filter controls are present.
    expect(find.text('Search products, brands…'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);

    // Both products are shown with website-style fields.
    expect(find.text('Rider Helmet Pro'), findsOneWidget);
    expect(find.text('SHOEI'), findsOneWidget);
    expect(find.text('Trail Gloves'), findsOneWidget);
    expect(find.text('ALPINESTARS'), findsOneWidget);
    expect(find.text('₹12,999'), findsWidgets);
  });

  testWidgets('empty catalogue shows the empty state', (tester) async {
    await tester.pumpWidget(await _buildApp([]));
    await tester.pumpAndSettle();

    expect(find.text('No products yet'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('search filters the loaded catalogue', (tester) async {
    final products = [
      _product(id: 'p1', name: 'Rider Helmet Pro'),
      _product(
        id: 'p2',
        name: 'Trail Gloves',
        brand: 'Alpinestars',
        tag: 'Gloves',
      ),
    ];

    await tester.pumpWidget(await _buildApp(products));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'gloves');
    await tester.pumpAndSettle();

    expect(find.text('Trail Gloves'), findsOneWidget);
    expect(find.text('Rider Helmet Pro'), findsNothing);
  });

  testWidgets('tapping a product opens the product detail screen', (
    tester,
  ) async {
    final products = [_product(id: 'p1', name: 'Rider Helmet Pro')];

    await tester.pumpWidget(await _buildApp(products));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rider Helmet Pro'));
    await tester.pumpAndSettle();

    // Product detail shows the brand kicker and the primary CTA.
    expect(find.text('SHOEI'), findsOneWidget);
    expect(find.text('Add to Cart'), findsOneWidget);
    expect(find.text('IN STOCK'), findsOneWidget);
  });

  group('responsive Shop grid never overflows', () {
    final products = _manyProducts(12);

    for (final width in [320.0, 360.0, 390.0, 430.0, 768.0, 1024.0]) {
      for (final textScale in [1.0, 1.3, 2.0]) {
        testWidgets(
            'renders at ${width}px width, ${textScale}x text without overflow',
            (tester) async {
          await _pumpShopAt(
            tester,
            products,
            width: width,
            height: 844,
            textScale: textScale,
          );
        });
      }
    }

    testWidgets('renders on a Pixel 7 Pro (412x915) at 1.0x text', (
      tester,
    ) async {
      await _pumpShopAt(
        tester,
        products,
        width: 412,
        height: 915,
        textScale: 1.0,
      );
    });

    testWidgets('renders on a Pixel 7 Pro (412x915) at 1.3x text', (
      tester,
    ) async {
      await _pumpShopAt(
        tester,
        products,
        width: 412,
        height: 915,
        textScale: 1.3,
      );
    });

    testWidgets('renders on a Pixel 7 Pro (412x915) at 2.0x text', (
      tester,
    ) async {
      await _pumpShopAt(
        tester,
        products,
        width: 412,
        height: 915,
        textScale: 2.0,
      );
    });
  });
}
