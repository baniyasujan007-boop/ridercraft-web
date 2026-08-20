import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridercraft_mobile/models/cart_item.dart';
import 'package:ridercraft_mobile/models/order.dart';
import 'package:ridercraft_mobile/models/product.dart';
import 'package:ridercraft_mobile/models/promo.dart';
import 'package:ridercraft_mobile/models/user.dart';
import 'package:ridercraft_mobile/providers/auth_provider.dart';
import 'package:ridercraft_mobile/providers/cart_provider.dart';
import 'package:ridercraft_mobile/routes/app_routes.dart';
import 'package:ridercraft_mobile/screens/cart/checkout_screen.dart';
import 'package:ridercraft_mobile/screens/orders/order_screens.dart';
import 'package:ridercraft_mobile/services/api_client.dart';
import 'package:ridercraft_mobile/services/api_exception.dart';
import 'package:ridercraft_mobile/services/auth_service.dart';
import 'package:ridercraft_mobile/services/order_service.dart';
import 'package:ridercraft_mobile/services/promo_service.dart';
import 'package:ridercraft_mobile/services/token_store.dart';
import 'package:ridercraft_mobile/theme/app_theme.dart';

import 'support/test_storage.dart';

class _FakeAuthService extends AuthService {
  _FakeAuthService(super.api, super.storage, {required this.user});

  User user;

  @override
  Future<User> fetchProfile() async => user;

  @override
  Future<User> updateProfile({
    String? name,
    String? avatar,
    String? contactNumber,
    String? deliveryAddress,
  }) async {
    user = user.copyWith(
      contactNumber: contactNumber,
      deliveryAddress: deliveryAddress,
    );
    return user;
  }
}

class _RecordingOrderService extends OrderService {
  _RecordingOrderService(super.api);

  List<CartItem>? placedItems;
  double? placedSubtotal;
  double? placedDiscount;
  double? placedTotal;
  String? placedPromoCode;
  String? placedPaymentMethod;
  Map<String, dynamic>? placedPaymentDetails;
  bool failWithStock = false;

  @override
  Future<Order> createOrder({
    required List<CartItem> items,
    required double subtotal,
    required double tax,
    required double shipping,
    required double discount,
    required double total,
    required String promoCode,
    required String paymentMethod,
    Map<String, dynamic>? paymentDetails,
  }) async {
    placedItems = items;
    placedSubtotal = subtotal;
    placedDiscount = discount;
    placedTotal = total;
    placedPromoCode = promoCode;
    placedPaymentMethod = paymentMethod;
    placedPaymentDetails = paymentDetails;
    if (failWithStock) {
      throw const ApiException(
        message: 'Some items are out of stock. Please review your cart.',
      );
    }
    return Order(
      id: 'ORDABC12345',
      items: items
          .map(
            (item) => OrderItem(
              productId: item.product.id,
              name: item.product.name,
              price: item.unitPrice,
              qty: item.quantity,
            ),
          )
          .toList(),
      subtotal: subtotal,
      tax: tax,
      shipping: shipping,
      discount: discount,
      total: total,
      promoCode: promoCode,
      paymentMethod: paymentMethod,
    );
  }
}

class _FakePromoService extends PromoService {
  _FakePromoService() : super(ApiClient());

  static const double discount = 250;

  @override
  Future<PromoValidation> validate({
    required String code,
    required double subtotal,
    double shipping = 0,
  }) async {
    return PromoValidation(
      code: code.toUpperCase(),
      discountType: 'flat',
      discountValue: discount,
      discountAmount: discount,
    );
  }
}

class _Harness {
  final Widget app;
  final _RecordingOrderService orderService;
  final CartProvider cart;
  final _FakeAuthService authService;
  final AuthProvider authProvider;

  const _Harness({
    required this.app,
    required this.orderService,
    required this.cart,
    required this.authService,
    required this.authProvider,
  });
}

Product _jacket({String name = 'Riding Jacket'}) => Product.fromJson({
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
      'sizes': ['M', 'L'],
      'variants': [
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
      ],
    });

Future<_Harness> _build({
  required User user,
  required List<CartItem> seed,
  double width = 390,
  double textScale = 1.0,
}) async {
  SharedPreferences.setMockInitialValues({'ridercraft_auth_token': 'token'});
  final prefs = await SharedPreferences.getInstance();
  final storage = TestStorageService(prefs);
  final tokenStore = TokenStore();
  final api = ApiClient(tokenProvider: () => tokenStore.current, dio: Dio());

  final authService = _FakeAuthService(api, storage, user: user);
  final authProvider = AuthProvider(authService, tokenStore);
  await authProvider.restoreSession();

  final cart = CartProvider(storage, _FakePromoService());
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

  // Exposed to consumers as the base type (Provider<OrderService>); the
  // harness keeps the recording reference for assertions.
  final recordingOrderService = _RecordingOrderService(api);
  final OrderService orderService = recordingOrderService;

  final app = MediaQuery(
    data: MediaQueryData(
      size: Size(width, 844),
      textScaler: TextScaler.linear(textScale),
    ),
    child: MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: cart),
        Provider.value(value: orderService),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: const CheckoutScreen(),
      ),
    ),
  );

  return _Harness(
    app: app,
    orderService: recordingOrderService,
    cart: cart,
    authService: authService,
    authProvider: authProvider,
  );
}

CartItem _jacketItem({int quantity = 1}) => CartItem(
      product: _jacket(),
      variantId: 'v1',
      variantSku: 'RCJ-BLK-M',
      color: 'Black',
      colorHex: '#111827',
      size: 'M',
      quantity: quantity,
    );

User _user({String address = '12 Main Rd, Bengaluru 560001', String phone = '9876543210'}) =>
    User(
      id: 'u1',
      name: 'Aarav',
      email: 'aarav@ridercraft.app',
      deliveryAddress: address,
      contactNumber: phone,
    );

void main() {
  testWidgets('checkout renders sections with prefilled address and totals',
      (tester) async {
    final harness = await _build(
      user: _user(),
      seed: [_jacketItem(quantity: 2), CartItem(product: _jacket(), variantId: 'v2', color: 'Red', quantity: 1)],
    );
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(find.text('DELIVERY ADDRESS'), findsOneWidget);
    expect(find.text('12 Main Rd, Bengaluru 560001'), findsOneWidget);
    expect(find.text('9876543210'), findsOneWidget);
    expect(find.text('ORDER ITEMS'), findsOneWidget);
    expect(find.text('COUPON'), findsOneWidget);
    expect(find.text('PAYMENT METHOD'), findsOneWidget);
    expect(find.text('Cash on Delivery'), findsOneWidget);
    expect(find.text('E-Wallet (Demo)'), findsOneWidget);
    // Two line items are reviewed.
    expect(find.text('Riding Jacket'), findsNWidgets(2));
    expect(find.textContaining('Qty 2'), findsOneWidget);
    // Total: 2*4999 + 1*4999 = 14997.
    expect(find.text('₹14,997'), findsWidgets);
    expect(find.text('PLACE ORDER'), findsOneWidget);
  });

  testWidgets('placing a COD order posts the exact variant payload',
      (tester) async {
    final harness = await _build(
      user: _user(),
      seed: [_jacketItem(quantity: 2)],
    );
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('PLACE ORDER'));
    await tester.pumpAndSettle();

    expect(find.text('ORDER CONFIRMED'), findsOneWidget);
    expect(find.text('Your ride essentials are on the way.'), findsOneWidget);

    final posted = harness.orderService.placedItems!;
    expect(posted, hasLength(1));
    expect(posted.single.product.id, 'p1');
    expect(posted.single.variantId, 'v1');
    expect(posted.single.variantSku, 'RCJ-BLK-M');
    expect(posted.single.color, 'Black');
    expect(posted.single.colorHex, '#111827');
    expect(posted.single.size, 'M');
    expect(posted.single.quantity, 2);
    expect(harness.orderService.placedSubtotal, 2 * 4999);
    expect(harness.orderService.placedDiscount, 0);
    expect(harness.orderService.placedTotal, 2 * 4999);
    expect(harness.orderService.placedPromoCode, '');
    expect(harness.orderService.placedPaymentMethod, 'cod');
    // The profile is updated with the delivery details before the order.
    expect(harness.authService.user.deliveryAddress, '12 Main Rd, Bengaluru 560001');
    // The cart is cleared afterwards.
    expect(harness.cart.isEmpty, isTrue);
  });

  testWidgets('place order is blocked without an address or phone',
      (tester) async {
    final harness = await _build(
      user: _user(address: '', phone: ''),
      seed: [_jacketItem()],
    );
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('PLACE ORDER'));
    await tester.pump();

    expect(
      find.text('Enter a delivery address and contact number.'),
      findsOneWidget,
    );
    expect(harness.orderService.placedItems, isNull);
  });

  testWidgets('ewallet demo selection sends isDummy payment details',
      (tester) async {
    final harness = await _build(
      user: _user(),
      seed: [_jacketItem()],
    );
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    // Bring the payment card fully into view before selecting e-wallet so the
    // wallet field is laid out within the viewport.
    await tester.ensureVisible(find.text('E-Wallet (Demo)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('E-Wallet (Demo)'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('checkout-wallet')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('checkout-wallet')),
      'wallet@demo.com',
    );

    await tester.tap(find.text('PLACE ORDER'));
    await tester.pumpAndSettle();

    expect(harness.orderService.placedPaymentMethod, 'ewallet');
    expect(harness.orderService.placedPaymentDetails?['isDummy'], isTrue);
    expect(harness.orderService.placedPaymentDetails?['walletId'], 'wallet@demo.com');
    expect(find.text('ORDER CONFIRMED'), findsOneWidget);
  });

  testWidgets('an order failure keeps the cart and shows a friendly message',
      (tester) async {
    final harness = await _build(
      user: _user(),
      seed: [_jacketItem()],
    );
    harness.orderService.failWithStock = true;
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('PLACE ORDER'));
    await tester.pumpAndSettle();

    expect(
      find.text('Some items are out of stock. Please review your cart.'),
      findsOneWidget,
    );
    expect(
      find.text('ORDER CONFIRMED'),
      findsNothing,
    );
    expect(harness.cart.isEmpty, isFalse);
  });

  testWidgets('success screen shows order number, summary and actions',
      (tester) async {
    final order = Order(
      id: 'ORDABC12345',
      items: const [
        OrderItem(productId: 'p1', name: 'Riding Jacket', price: 4999, qty: 1),
        OrderItem(productId: 'p2', name: 'Gloves', price: 1499, qty: 2),
      ],
      subtotal: 7997,
      discount: 250,
      shipping: 0,
      total: 7747,
      paymentMethod: 'cod',
    );

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: OrderSuccessScreen(order: order),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ORDER CONFIRMED'), findsOneWidget);
    expect(find.text('Your ride essentials are on the way.'), findsOneWidget);
    expect(find.text('Order #ABC12345'), findsOneWidget);
    expect(find.text('2 item(s) · Payment Pending'), findsOneWidget);
    expect(find.text('₹7,747'), findsWidgets);
    expect(find.text('VIEW ORDER'), findsOneWidget);
    expect(find.text('CONTINUE SHOPPING'), findsOneWidget);
  });

  for (final width in const [320.0, 360.0, 390.0, 430.0]) {
    for (final scale in const [1.0, 1.3, 2.0]) {
      testWidgets(
        'checkout renders at ${width}px and ${scale}x text without overflow',
        (tester) async {
          const longName =
              'Premium Waterproof All-Weather Motorcycle Riding Jacket with '
              'Thermal Liner, Reflective Trim and Magnetic Pockets';
          final harness = await _build(
            user: _user(
              address: 'Apartment 12B, Sector 44 Noida Uttar Pradesh 201301',
            ),
            seed: [
              CartItem(
                product: _jacket(name: longName),
                variantId: 'v1',
                variantSku: 'RCJ-BLK-XL-LONG',
                color: 'Matte Black',
                size: 'XL',
                quantity: 4,
              ),
              CartItem(product: _jacket(), variantId: 'v2', color: 'Red', quantity: 1),
            ],
            width: width,
            textScale: scale,
          );
          await tester.pumpWidget(harness.app);
          await tester.pumpAndSettle();

          // Scroll to the bottom so the payment card, summary and totals lay
          // out fully.
          await tester.drag(
            find.byType(ListView),
            const Offset(0, -1600),
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