// Regression coverage for the AuthProvider startup exception:
//
//   "setState() or markNeedsBuild() called during build"
//
//   AuthProvider.restoreSession()
//   -> SplashScreen._bootstrap()
//   -> SplashScreen.initState()
//
// SplashScreen now schedules the session restore after the first frame, so
// restoreSession()'s notifyListeners() never runs during the widget build
// phase. A guest launch must reach Login (with the Google button) and a
// signed-in launch must reach Home — with no build-time exception.
import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridercraft_mobile/models/user.dart';
import 'package:ridercraft_mobile/providers/auth_provider.dart';
import 'package:ridercraft_mobile/providers/bike_provider.dart';
import 'package:ridercraft_mobile/providers/booking_provider.dart';
import 'package:ridercraft_mobile/providers/cart_provider.dart';
import 'package:ridercraft_mobile/providers/home_provider.dart';
import 'package:ridercraft_mobile/providers/product_provider.dart';
import 'package:ridercraft_mobile/routes/app_routes.dart';
import 'package:ridercraft_mobile/routes/route_names.dart';
import 'package:ridercraft_mobile/services/api_client.dart';
import 'package:ridercraft_mobile/services/auth_service.dart';
import 'package:ridercraft_mobile/services/booking_service.dart';
import 'package:ridercraft_mobile/services/notification_service.dart';
import 'package:ridercraft_mobile/services/order_service.dart';
import 'package:ridercraft_mobile/services/product_service.dart';
import 'package:ridercraft_mobile/services/promo_service.dart';
import 'package:ridercraft_mobile/services/token_store.dart';

import 'support/test_storage.dart';

/// Always returns an empty JSON array — the non-auth services resolve to
/// empty fallback states without any network.
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

class _FakeAuthService extends AuthService {
  _FakeAuthService(super.api, super.storage, {required User initial})
      : profile = initial;

  User profile;

  @override
  Future<User> fetchProfile() async => profile;
}

Future<Widget> _buildApp({required bool signedIn}) async {
  SharedPreferences.setMockInitialValues(
    signedIn ? const {'ridercraft_auth_token': 'stored-token'} : const {},
  );
  final prefs = await SharedPreferences.getInstance();
  final storage = TestStorageService(prefs);
  final tokenStore = TokenStore();

  final dio = Dio()..httpClientAdapter = _EmptyAdapter();
  final api = ApiClient(tokenProvider: () => tokenStore.current, dio: dio);

  final authService = _FakeAuthService(
    api,
    storage,
    initial: User(
      id: 'u1',
      name: 'Aarav',
      email: 'aarav@ridercraft.app',
      role: 'customer',
    ),
  );
  final authProvider = AuthProvider(authService, tokenStore);

  final promoService = PromoService(api);
  final productService = ProductService(api);
  final orderService = OrderService(api);
  final notificationService = NotificationService(api);
  final bookingService = BookingService(api);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: authProvider),
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
    child: const MaterialApp(
      initialRoute: RouteNames.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    ),
  );
}

void main() {
  testWidgets(
    'guest launch restores after the first frame, no build exception, hits Login',
    (tester) async {
      await tester.pumpWidget(await _buildApp(signedIn: false));

      // First frame builds the splash; the post-frame callback now fires after
      // it, starting restoreSession() outside the build phase.
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('WELCOME BACK'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    },
  );

  testWidgets(
    'signed-in launch restores the session and lands on Home',
    (tester) async {
      await tester.pumpWidget(await _buildApp(signedIn: true));

      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('RiderCraft'), findsWidgets);
    },
  );
}