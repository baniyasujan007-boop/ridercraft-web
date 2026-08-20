import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridercraft_mobile/models/cart_item.dart';
import 'package:ridercraft_mobile/models/product.dart';
import 'package:ridercraft_mobile/models/promo.dart';
import 'package:ridercraft_mobile/providers/auth_provider.dart';
import 'package:ridercraft_mobile/providers/cart_provider.dart';
import 'package:ridercraft_mobile/screens/cart/cart_screen.dart';
import 'package:ridercraft_mobile/services/api_client.dart';
import 'package:ridercraft_mobile/services/api_exception.dart';
import 'package:ridercraft_mobile/services/auth_service.dart';
import 'package:ridercraft_mobile/services/promo_service.dart';
import 'package:ridercraft_mobile/services/storage_service.dart';
import 'package:ridercraft_mobile/services/token_store.dart';
import 'package:ridercraft_mobile/theme/app_theme.dart';
import 'package:ridercraft_mobile/widgets/rc_card.dart';

import 'support/test_storage.dart';

class _FakePromoService extends PromoService {
  _FakePromoService({this.valid = true, this.discount = 250})
      : super(ApiClient());

  final bool valid;
  final double discount;

  @override
  Future<PromoValidation> validate({
    required String code,
    required double subtotal,
    double shipping = 0,
  }) async {
    if (!valid) throw const ApiException(message: 'Invalid promo code.');
    return PromoValidation(
      code: code.toUpperCase(),
      discountType: 'flat',
      discountValue: discount,
      discountAmount: discount,
    );
  }
}

Product _jacket({
  int v1Stock = 5,
  int v2Stock = 0,
  String name = 'Riding Jacket',
}) => Product.fromJson({
      '_id': 'p1',
      'name': name,
      'price': 4999,
      'displayPrice': 4999,
      'originalPrice': 4999,
      'stock': 10,
      'image': '',
      'brand': 'RiderCraft',
      'tag': 'Riding Gear',
      'colorFamily': 'Neutral',
      'colors': ['Black', 'Red'],
      'sizes': ['M', 'L', 'XL'],
      'variants': [
        {
          '_id': 'v1',
          'color': 'Black',
          'colorHex': '#111827',
          'images': <String>[],
          'stock': v1Stock,
          'sku': 'RCJ-BLK-M',
        },
        {
          '_id': 'v2',
          'color': 'Red',
          'colorHex': '#DC2626',
          'images': <String>[],
          'stock': v2Stock,
          'sku': 'RCJ-RED-M',
        },
      ],
    });

Product _helmet() => Product.fromJson({
      '_id': 'p2',
      'name': 'Full-Face Helmet Rally Edition',
      'price': 12499,
      'displayPrice': 12499,
      'originalPrice': 14999,
      'stock': 4,
      'image': '',
      'brand': 'RiderCraft',
      'tag': 'Helmet',
      'colorFamily': 'Neutral',
    });

Future<CartProvider> _cart(
  List<CartItem> seed,
  PromoService promo,
) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final storage = StorageService(prefs);
  final cart = CartProvider(storage, promo);
  await cart.load();
  for (final item in seed) {
    await cart.addProduct(
      item.product,
      variantId: item.variantId,
      variantSku: item.variantSku,
      color: item.color,
      colorHex: item.colorHex,
      size: item.size,
      quantity: item.quantity,
    );
  }
  return cart;
}

Future<void> _pump(
  WidgetTester tester,
  CartProvider cart, {
  double width = 390,
  double textScale = 1.0,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: Size(width, 844),
        textScaler: TextScaler.linear(textScale),
      ),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: cart),
          ChangeNotifierProvider(
            create: (_) => AuthProvider(
              AuthService(ApiClient(), TestStorageService(prefs)),
              TokenStore(),
            ),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          home: const CartScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empty cart shows the ride-ready empty state', (tester) async {
    final cart = await _cart(const [], _FakePromoService());
    await _pump(tester, cart);

    expect(find.text('Your cart is ready for its next ride.'), findsOneWidget);
    expect(find.text('Explore Shop'), findsOneWidget);
  });

  testWidgets('shows premium header, count and item details', (tester) async {
    final product = _jacket();
    final cart = await _cart(
      [
        CartItem(
          product: product,
          variantId: 'v1',
          variantSku: 'RCJ-BLK-M',
          color: 'Black',
          colorHex: '#111827',
          size: 'M',
          quantity: 2,
        ),
      ],
      _FakePromoService(),
    );
    await _pump(tester, cart);

    expect(find.text('CART'), findsOneWidget);
    expect(find.text('Review your ride essentials'), findsOneWidget);
    expect(find.text('2 items'), findsOneWidget);
    expect(find.text('Riding Jacket'), findsOneWidget);
    expect(find.text('Black · Size M · RCJ-BLK-M'), findsOneWidget);
    expect(find.text('₹9,998'), findsWidgets);
    expect(find.text('₹4,999 each'), findsOneWidget);
    expect(find.textContaining('In stock'), findsOneWidget);
    expect(find.text('PROCEED TO CHECKOUT'), findsOneWidget);
    expect(find.text('TOTAL'), findsOneWidget);
  });

  testWidgets('quantity stepper animates and uses the provider', (tester) async {
    final cart = await _cart(
      [CartItem(product: _jacket(), variantId: 'v1', quantity: 1)],
      _FakePromoService(),
    );
    await _pump(tester, cart);

    await tester.tap(find.byTooltip('Increase quantity'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(cart.items.first.quantity, 2);

    await tester.tap(find.byTooltip('Decrease quantity'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(cart.items.first.quantity, 1);
  });

  testWidgets('quantity cannot go below one', (tester) async {
    final cart = await _cart(
      [CartItem(product: _jacket(), variantId: 'v1', quantity: 1)],
      _FakePromoService(),
    );
    await _pump(tester, cart);

    await tester.tap(find.byTooltip('Decrease quantity'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(cart.items.first.quantity, 1);
  });

  testWidgets('out-of-stock lines are muted, quantity locked, removal works',
      (tester) async {
    final cart = await _cart(
      [
        CartItem(
          product: _jacket(v2Stock: 0),
          variantId: 'v2',
          color: 'Red',
          quantity: 1,
        ),
      ],
      _FakePromoService(),
    );
    await _pump(tester, cart);

    expect(find.text('Out of stock'), findsOneWidget);

    await tester.tap(find.byTooltip('Increase quantity'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(cart.items.first.quantity, 1);

    await tester.tap(find.text('Remove'));
    await tester.pump(const Duration(milliseconds: 320));
    await tester.pumpAndSettle();
    expect(cart.isEmpty, isTrue);
    expect(find.text('Your cart is ready for its next ride.'), findsOneWidget);
  });

  testWidgets('quantity above stock warns and blocks increments', (tester) async {
    final cart = await _cart(
      [CartItem(product: _jacket(v1Stock: 3), variantId: 'v1', quantity: 5)],
      _FakePromoService(),
    );
    await _pump(tester, cart);

    expect(find.text('Only 3 available — reduce quantity'), findsOneWidget);

    await tester.tap(find.byTooltip('Increase quantity'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(cart.items.first.quantity, 5);
  });

  testWidgets('variant that no longer exists is explained and removable',
      (tester) async {
    final cart = await _cart(
      [CartItem(product: _jacket(), variantId: 'ghost', quantity: 1)],
      _FakePromoService(),
    );
    await _pump(tester, cart);

    expect(find.text('This option is no longer available'), findsOneWidget);
    expect(find.text('Remove'), findsOneWidget);

    await tester.tap(find.text('Remove'));
    await tester.pump(const Duration(milliseconds: 320));
    await tester.pumpAndSettle();
    expect(cart.isEmpty, isTrue);
  });

  testWidgets('removing an in-stock item animates it out', (tester) async {
    final cart = await _cart(
      [CartItem(product: _jacket(), variantId: 'v1', quantity: 1)],
      _FakePromoService(),
    );
    await _pump(tester, cart);

    await tester.tap(find.text('Remove'));
    await tester.pump(const Duration(milliseconds: 320));
    await tester.pumpAndSettle();
    expect(cart.isEmpty, isTrue);
  });

  testWidgets('a valid coupon applies with the server discount', (tester) async {
    final promo = _FakePromoService(valid: true, discount: 250);
    final cart = await _cart(
      [CartItem(product: _jacket(), variantId: 'v1', quantity: 1)],
      promo,
    );
    await _pump(tester, cart);
    // Advanced past the entrance animation so the field is settled.
    await tester.pump(const Duration(milliseconds: 400));

    await tester.enterText(find.byType(TextField), 'RIDE10');
    await tester.tap(find.text('APPLY'));
    await tester.pumpAndSettle();

    expect(find.text('Coupon applied.'), findsOneWidget);
    expect(find.text('-₹250 on this order'), findsOneWidget);
    expect(cart.appliedPromo?.code, 'RIDE10');
    expect(cart.discount, 250);
    expect(cart.total, 4999 - 250);

    // Removing the coupon reverts the totals (targets the coupon chip's
    // Remove, not the item card's).
    await tester.tap(
      find.descendant(
        of: find.byType(RcCard),
        matching: find.text('Remove'),
      ),
    );
    await tester.pumpAndSettle();
    expect(cart.appliedPromo, isNull);
    expect(cart.total, 4999);
  });

  testWidgets('an invalid coupon shows the server message and no discount',
      (tester) async {
    final promo = _FakePromoService(valid: false);
    final cart = await _cart(
      [CartItem(product: _jacket(), variantId: 'v1', quantity: 1)],
      promo,
    );
    await _pump(tester, cart);
    await tester.pump(const Duration(milliseconds: 400));

    await tester.enterText(find.byType(TextField), 'BAD');
    await tester.tap(find.text('APPLY'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid promo code.'), findsWidgets);
    expect(cart.appliedPromo, isNull);
    expect(cart.discount, 0);
    expect(cart.total, 4999);
  });

  testWidgets('an empty promo code is not sent to the backend', (tester) async {
    final promo = _FakePromoService();
    final cart = await _cart(
      [CartItem(product: _jacket(), variantId: 'v1', quantity: 1)],
      promo,
    );
    await _pump(tester, cart);
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('APPLY'));
    await tester.pump();
    expect(find.text('Enter a promo code first.'), findsOneWidget);
    expect(cart.appliedPromo, isNull);
  });

  for (final width in const [320.0, 360.0, 390.0, 430.0]) {
    for (final scale in const [1.0, 1.3, 2.0]) {
      testWidgets(
        'cart renders at ${width}px and ${scale}x text without overflow',
        (tester) async {
          final longName =
              'Premium Waterproof All-Weather Motorcycle Riding Jacket with '
              'Thermal Liner, Reflective Trim and Magnetic Pockets';
          final cart = await _cart(
            [
              CartItem(
                product: _jacket(
                  name: longName,
                  v1Stock: 8,
                ),
                variantId: 'v1',
                variantSku: 'RCJ-BLK-XL-LONG-SKU',
                color: 'Matte Black',
                size: 'XL',
                quantity: 4,
              ),
              CartItem(product: _helmet(), quantity: 1),
            ],
            _FakePromoService(),
          );
          // Two distinct lines should also carry their own totals.
          expect(cart.items, hasLength(2));
          await _pump(
            tester,
            cart,
            width: width,
            textScale: scale,
          );
          // Scroll through the summary, coupon and sticky bar.
          await tester.drag(
            find.byType(ListView),
            const Offset(0, -1400),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          await tester.drag(
            find.byType(ListView),
            const Offset(0, -900),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          expect(
            tester.takeException(),
            isNull,
            reason: 'overflow at ${width}px / ${scale}x',
          );
        },
      );
    }
  }
}