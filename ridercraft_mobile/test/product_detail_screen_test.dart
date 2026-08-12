import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridercraft_mobile/models/product.dart';
import 'package:ridercraft_mobile/providers/cart_provider.dart';
import 'package:ridercraft_mobile/providers/product_provider.dart';
import 'package:ridercraft_mobile/screens/products/product_detail_screen.dart';
import 'package:ridercraft_mobile/services/api_client.dart';
import 'package:ridercraft_mobile/services/product_service.dart';
import 'package:ridercraft_mobile/services/promo_service.dart';
import 'package:ridercraft_mobile/services/storage_service.dart';
import 'package:ridercraft_mobile/theme/app_theme.dart';

Product _product({bool withOptions = true}) {
  final json = <String, dynamic>{
    '_id': 'p1',
    'name': 'Riding Jacket',
    'price': 4999,
    'displayPrice': 4999,
    'originalPrice': 4999,
    'stock': 10,
    'image': '',
    'description': 'A durable riding jacket.',
    'tag': 'Riding Gear',
    'brand': 'RiderCraft',
    'colorFamily': 'Neutral',
  };
  if (withOptions) {
    json['colors'] = ['Black', 'Red'];
    json['sizes'] = ['M', 'L', 'XL'];
    json['variants'] = [
      {
        '_id': 'v1',
        'color': 'Black',
        'colorHex': '#111827',
        'images': <String>[],
        'stock': 5,
        'sku': 'RCJ-BLK-M',
      },
      {
        '_id': 'v2',
        'color': 'Red',
        'colorHex': '#DC2626',
        'images': <String>[],
        'stock': 5,
        'sku': 'RCJ-RED-M',
      },
    ];
  }
  return Product.fromJson(json);
}

Future<Widget> _buildApp(Product product) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final storage = StorageService(prefs);
  final api = ApiClient(dio: Dio());
  final promoService = PromoService(api);
  final productService = ProductService(api);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => CartProvider(storage, promoService)..load(),
      ),
      ChangeNotifierProvider(create: (_) => ProductProvider(productService)),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      home: ProductDetailScreen(product: product),
    ),
  );
}

void main() {
  Future<void> clearSnackBars(WidgetTester tester) async {
    final messenger = ScaffoldMessenger.of(
      tester.element(find.byType(ProductDetailScreen)),
    );
    messenger.clearSnackBars();
    await tester.pumpAndSettle();
  }

  testWidgets('requires color and size selections before adding to cart',
      (tester) async {
    tester.view.physicalSize = const Size(600, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(await _buildApp(_product()));
    await tester.pumpAndSettle();

    // Options from the API are rendered.
    expect(find.text('COLOR'), findsOneWidget);
    expect(find.byKey(const ValueKey('swatch-Black')), findsOneWidget);
    expect(find.byKey(const ValueKey('swatch-Red')), findsOneWidget);
    expect(find.text('SIZE'), findsOneWidget);
    expect(find.text('M'), findsOneWidget);

    // Add to Cart without any selection is blocked.
    await tester.tap(find.text('Add to Cart'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Please select a color to continue.'), findsOneWidget);
    await clearSnackBars(tester);

    // Color chosen, size missing -> still blocked.
    await tester.tap(find.byKey(const ValueKey('swatch-Black')));
    await tester.pump();
    await tester.tap(find.text('Add to Cart'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Please select a size to continue.'), findsOneWidget);
    await clearSnackBars(tester);

    // Both chosen -> added with the selection carried into the cart.
    await tester.tap(find.text('M'));
    await tester.pump();
    await tester.tap(find.text('Add to Cart'));
    await tester.pump(const Duration(seconds: 1));

    final provider = Provider.of<CartProvider>(
      tester.element(find.byType(ProductDetailScreen)),
      listen: false,
    );
    expect(provider.items, hasLength(1));
    expect(provider.items.first.color, 'Black');
    expect(provider.items.first.colorHex, '#111827');
    expect(provider.items.first.variantId, 'v1');
    expect(provider.items.first.size, 'M');
    expect(provider.items.first.quantity, 1);
    expect(find.text('Riding Jacket added to cart'), findsOneWidget);
  });

  testWidgets('products without options can be added directly',
      (tester) async {
    tester.view.physicalSize = const Size(600, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(await _buildApp(_product(withOptions: false)));
    await tester.pumpAndSettle();

    expect(find.text('Color'), findsNothing);
    expect(find.text('Size'), findsNothing);

    await tester.tap(find.text('Add to Cart'));
    await tester.pump(const Duration(seconds: 1));

    final provider = Provider.of<CartProvider>(
      tester.element(find.byType(ProductDetailScreen)),
      listen: false,
    );
    expect(provider.items, hasLength(1));
    expect(provider.items.first.color, '');
    expect(provider.items.first.size, '');
    expect(find.text('Riding Jacket added to cart'), findsOneWidget);
  });
}
