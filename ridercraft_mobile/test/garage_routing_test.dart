// Garage-role routing: garage accounts must land in the GarageScaffold while
// customer accounts keep the existing MainScaffold. Covers both entry points:
// session restore (splash) and email sign-in (login screen).
import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridercraft_mobile/models/service_request.dart';
import 'package:ridercraft_mobile/models/user.dart';
import 'package:ridercraft_mobile/providers/auth_provider.dart';
import 'package:ridercraft_mobile/providers/bike_provider.dart';
import 'package:ridercraft_mobile/providers/booking_provider.dart';
import 'package:ridercraft_mobile/providers/cart_provider.dart';
import 'package:ridercraft_mobile/providers/garage_provider.dart';
import 'package:ridercraft_mobile/providers/home_provider.dart';
import 'package:ridercraft_mobile/providers/product_provider.dart';
import 'package:ridercraft_mobile/routes/app_routes.dart';
import 'package:ridercraft_mobile/routes/home_router.dart';
import 'package:ridercraft_mobile/routes/route_names.dart';
import 'package:ridercraft_mobile/screens/garage/garage_scaffold.dart';
import 'package:ridercraft_mobile/screens/main_scaffold.dart';
import 'package:ridercraft_mobile/services/api_client.dart';
import 'package:ridercraft_mobile/services/auth_service.dart';
import 'package:ridercraft_mobile/services/booking_service.dart';
import 'package:ridercraft_mobile/services/garage_service.dart';
import 'package:ridercraft_mobile/services/notification_service.dart';
import 'package:ridercraft_mobile/services/order_service.dart';
import 'package:ridercraft_mobile/services/product_service.dart';
import 'package:ridercraft_mobile/services/promo_service.dart';
import 'package:ridercraft_mobile/services/token_store.dart';
import 'package:ridercraft_mobile/utils/formatters.dart';

import 'support/test_storage.dart';

/// Always returns an empty JSON array — non-auth services resolve to empty
/// fallback states without any network.
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
  int loginCalls = 0;

  @override
  Future<User> fetchProfile() async => profile;

  @override
  Future<void> login({required String email, required String password}) async {
    loginCalls++;
    await storage.writeToken('fresh-token');
  }
}

class _FakeGarageService extends GarageService {
  _FakeGarageService() : super(ApiClient());

  @override
  Future<List<ServiceRequest>> listGarageBookings() async => [
        ServiceRequest.fromJson({
          '_id': 'r1',
          'packageType': 'basic',
          'bikeModel': 'Honda SP 125',
          'preferredDate': '2026-08-25',
          'preferredTime': '10:30',
          'pickupAddress': '12 MG Road',
          'contactNumber': '9876543210',
          'status': 'requested',
          'createdAt': '2026-08-19T05:00:00.000Z',
          'user': {'_id': 'u1', 'name': 'Aarav', 'email': 'a@x.in'},
        }),
      ];
}

Future<Widget> _buildApp({
  required bool signedIn,
  required User user,
}) async {
  SharedPreferences.setMockInitialValues(
    signedIn ? const {'ridercraft_auth_token': 'stored-token'} : const {},
  );
  final prefs = await SharedPreferences.getInstance();
  final storage = TestStorageService(prefs);
  final tokenStore = TokenStore();

  final dio = Dio()..httpClientAdapter = _EmptyAdapter();
  final api = ApiClient(tokenProvider: () => tokenStore.current, dio: dio);

  final authService = _FakeAuthService(api, storage, initial: user);
  final authProvider = AuthProvider(authService, tokenStore);

  final promoService = PromoService(api);
  final productService = ProductService(api);
  final orderService = OrderService(api);
  final notificationService = NotificationService(api);
  final bookingService = BookingService(api);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: authProvider),
      ChangeNotifierProvider(create: (_) => CartProvider(storage, promoService)),
      ChangeNotifierProvider(create: (_) => ProductProvider(productService)),
      ChangeNotifierProvider(
        create: (_) => HomeProvider(productService, promoService)..load(),
      ),
      ChangeNotifierProvider(create: (_) => BookingProvider(bookingService)),
      ChangeNotifierProvider(create: (_) => BikeProvider(storage)..load()),
      ChangeNotifierProvider(
        create: (_) => GarageProvider(_FakeGarageService())..loadBookings(),
      ),
      Provider.value(value: orderService),
      Provider.value(value: notificationService),
    ],
    child: const MaterialApp(
      initialRoute: RouteNames.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    ),
  );
}

User _customer() => User(
      id: 'u1',
      name: 'Aarav',
      email: 'aarav@ridercraft.app',
      role: 'customer',
    );

User _garage() => User(
      id: 'g1',
      name: 'Speed Motors',
      email: 'speed@garage.in',
      role: 'garage',
      garageProfile: GarageProfile.fromJson({
        'garageName': 'Speed Motors Workshop',
        'isAvailable': false,
      }),
    );

void main() {
  setUpAll(() async {
    await Formatters.ensureDateSymbols();
  });

  group('homeRouteFor', () {
    test('garage accounts land on garageMain', () {
      expect(homeRouteFor(_garage()), RouteNames.garageMain);
    });

    test('customer accounts keep the main shell', () {
      expect(homeRouteFor(_customer()), RouteNames.main);
    });
  });

  testWidgets('signed-in customer session restores into MainScaffold',
      (tester) async {
    await tester.pumpWidget(await _buildApp(signedIn: true, user: _customer()));

    await tester.pump();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(MainScaffold), findsOneWidget);
    expect(find.byType(GarageScaffold), findsNothing);
  });

  testWidgets('signed-in garage session restores into GarageScaffold',
      (tester) async {
    await tester.pumpWidget(await _buildApp(signedIn: true, user: _garage()));

    await tester.pump();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(GarageScaffold), findsOneWidget);
    expect(find.byType(MainScaffold), findsNothing);
  });

  testWidgets('email sign-in for a garage account routes to GarageScaffold',
      (tester) async {
    await tester.pumpWidget(await _buildApp(signedIn: false, user: _garage()));

    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('WELCOME BACK'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'you@example.com').first,
        'speed@garage.in');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'supersecret',
    );
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(GarageScaffold), findsOneWidget);
    expect(find.byType(MainScaffold), findsNothing);
  });
}