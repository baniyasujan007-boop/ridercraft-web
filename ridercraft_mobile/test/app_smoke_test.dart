import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridercraft_mobile/providers/auth_provider.dart';
import 'package:ridercraft_mobile/providers/bike_provider.dart';
import 'package:ridercraft_mobile/providers/booking_provider.dart';
import 'package:ridercraft_mobile/providers/cart_provider.dart';
import 'package:ridercraft_mobile/providers/home_provider.dart';
import 'package:ridercraft_mobile/providers/product_provider.dart';
import 'package:ridercraft_mobile/routes/app_routes.dart';
import 'package:ridercraft_mobile/screens/main_scaffold.dart';
import 'package:ridercraft_mobile/services/api_client.dart';
import 'package:ridercraft_mobile/services/auth_service.dart';
import 'package:ridercraft_mobile/services/booking_service.dart';
import 'package:ridercraft_mobile/services/notification_service.dart';
import 'package:ridercraft_mobile/services/order_service.dart';
import 'package:ridercraft_mobile/services/product_service.dart';
import 'package:ridercraft_mobile/services/promo_service.dart';
import 'package:ridercraft_mobile/services/token_store.dart';
import 'package:ridercraft_mobile/theme/app_theme.dart';

import 'support/test_storage.dart';

/// Always returns an empty JSON array — exercises empty/fallback states
/// without any network.
class _EmptyAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '[]',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<Widget> _buildApp() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final storage = TestStorageService(prefs);
  final tokenStore = TokenStore();

  final dio = Dio()..httpClientAdapter = _EmptyAdapter();
  final api = ApiClient(tokenProvider: () => tokenStore.current, dio: dio);

  final authService = AuthService(api, storage);
  final promoService = PromoService(api);
  final productService = ProductService(api);
  final orderService = OrderService(api);
  final notificationService = NotificationService(api);
  final bookingService = BookingService(api);

  final authProvider = AuthProvider(authService, tokenStore);
  // No token in the mock store, so the session resolves to a guest.
  await authProvider.restoreSession();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(
        value: authProvider,
      ),
      ChangeNotifierProvider(
        create: (_) => CartProvider(storage, promoService)..load(),
      ),
      ChangeNotifierProvider(create: (_) => ProductProvider(productService)),
      ChangeNotifierProvider(
        create: (_) => HomeProvider(productService, promoService)..load(),
      ),
      ChangeNotifierProvider(create: (_) => BookingProvider(bookingService)),
      ChangeNotifierProvider(create: (_) => BikeProvider(storage)..load()),
      Provider.value(value: orderService),
      Provider.value(value: notificationService),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      home: const MainScaffold(),
      onGenerateRoute: AppRouter.onGenerateRoute,
    ),
  );
}

void main() {
  testWidgets('Home screen renders with empty API data', (tester) async {
    await tester.pumpWidget(await _buildApp());
    // Let HomeProvider.load() (fake adapter) settle.
    await tester.pumpAndSettle();

    expect(find.text('RiderCraft'), findsWidgets);
    // Branded fallback hero when the API returns no offers.
    expect(
      find.text('Premium motorcycle gear\nfor every rider.'),
      findsOneWidget,
    );
    // Quick actions (also present as the fallback hero CTA label).
    expect(find.text('Book Service'), findsWidgets);
    expect(find.text('My Bike'), findsOneWidget);
    // Bottom navigation.
    expect(find.text('Services'), findsWidgets);
    expect(find.text('Shop'), findsWidgets);
    expect(find.text('Bookings'), findsWidgets);
    expect(find.text('Profile'), findsWidgets);
  });

  testWidgets('Bottom navigation switches tabs', (tester) async {
    await tester.pumpWidget(await _buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    // Guests see the sign-in prompt on the Profile tab.
    expect(
      find.text('Sign in to manage your rider profile.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Shop').last);
    await tester.pumpAndSettle();
    // Empty catalogue state (the _EmptyAdapter returns no products).
    expect(find.text('No products yet'), findsOneWidget);
  });

  testWidgets('Services tab renders the three package cards', (tester) async {
    await tester.pumpWidget(await _buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Services').last);
    await tester.pumpAndSettle();

    // Package names are rendered in uppercase on the cards.
    expect(find.text('BASIC TUNE-UP'), findsOneWidget);
    expect(find.text('FULL SERVICE'), findsOneWidget);
    expect(find.text('PREMIUM CARE'), findsOneWidget);
    // Honest copy: no fabricated price/duration.
    expect(find.text('Price confirmed during booking'), findsNWidgets(3));
    expect(find.text('Book Now'), findsNWidgets(3));
  });

  testWidgets('Guest tapping Book Now is routed to sign-in', (tester) async {
    await tester.pumpWidget(await _buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Services').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Book Now').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Book Now').first);
    await tester.pumpAndSettle();

    expect(find.text('WELCOME BACK'), findsOneWidget);
  });

  testWidgets('Bookings tab shows the sign-in prompt for guests', (
    tester,
  ) async {
    await tester.pumpWidget(await _buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bookings').last);
    await tester.pumpAndSettle();

    expect(find.text('Sign in to see your service bookings.'), findsOneWidget);
  });
}
