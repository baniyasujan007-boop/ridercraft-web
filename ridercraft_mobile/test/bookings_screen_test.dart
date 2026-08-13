import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridercraft_mobile/providers/auth_provider.dart';
import 'package:ridercraft_mobile/providers/booking_provider.dart';
import 'package:ridercraft_mobile/routes/app_routes.dart';
import 'package:ridercraft_mobile/screens/bookings/bookings_screen.dart';
import 'package:ridercraft_mobile/services/api_client.dart';
import 'package:ridercraft_mobile/services/auth_service.dart';
import 'package:ridercraft_mobile/services/booking_service.dart';
import 'package:ridercraft_mobile/services/token_store.dart';
import 'package:ridercraft_mobile/theme/app_theme.dart';
import 'package:ridercraft_mobile/utils/formatters.dart';

import 'support/test_storage.dart';

ResponseBody _json(String body, int status) => ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

Map<String, dynamic> _booking({
  required String id,
  required String package,
  String status = 'requested',
  String priority = 'normal',
  String bike = 'Yamaha R15 V4',
  String date = '2026-08-15',
  String time = '10:30',
  String address = 'MG Road, Pune',
  Map<String, dynamic>? garage,
  double? garageDistanceKm,
}) {
  return {
    '_id': id,
    'packageType': package,
    'bikeModel': bike,
    'preferredDate': date,
    'preferredTime': time,
    'pickupAddress': address,
    'pickupLocation': {'latitude': 18.5204, 'longitude': 73.8567},
    'contactNumber': '9876543210',
    'priority': priority,
    'breakdownIssue': priority == 'emergency' ? 'Bike won\'t start' : '',
    'status': status,
    'assignedGarage': garage,
    'assignedGarageDistanceKm': garageDistanceKm,
    'createdAt': '2026-08-11T09:00:00.000Z',
  };
}

/// /service-requests/my backend. Optionally fails the first GET so Retry can
/// be exercised.
class _ListAdapter implements HttpClientAdapter {
  final List<Map<String, dynamic>> bookings;
  int failNext;
  int _calls = 0;

  _ListAdapter(this.bookings, {this.failNext = 0});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method == 'GET' && options.path == '/service-requests/my') {
      _calls++;
      if (_calls <= failNext) {
        return _json('{"error":"Failed to load service requests"}', 500);
      }
      return _json(jsonEncode(bookings), 200);
    }
    if (options.method == 'GET' && options.path == '/auth/profile') {
      return _json(
        jsonEncode({
          '_id': 'abc123',
          'name': 'Chandan Chhetry',
          'email': 'chandan@ridercraft.app',
          'role': 'user',
          'avatar': '',
          'contactNumber': '+15550000000',
          'deliveryAddress': 'River Rd, Gangtok, Sikkim 737101',
        }),
        200,
      );
    }
    return _json('[]', 200);
  }

  @override
  void close({bool force = false}) {}
}

Future<({Widget app, AuthProvider auth})> _buildApp({
  required bool authenticated,
  List<Map<String, dynamic>> bookings = const [],
  int failNext = 0,
}) async {
  SharedPreferences.setMockInitialValues(
    authenticated ? {'ridercraft_auth_token': 'test-token'} : {},
  );
  final prefs = await SharedPreferences.getInstance();
  final storage = TestStorageService(prefs);
  final tokenStore = TokenStore();

  final api = ApiClient(
    tokenProvider: () => tokenStore.current,
    dio: Dio()..httpClientAdapter = _ListAdapter(bookings, failNext: failNext),
  );
  final authProvider = AuthProvider(AuthService(api, storage), tokenStore);

  final app = MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: authProvider),
      ChangeNotifierProvider(create: (_) => BookingProvider(BookingService(api))),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      home: const BookingsScreen(),
      onGenerateRoute: AppRouter.onGenerateRoute,
    ),
  );
  return (app: app, auth: authProvider);
}

Future<void> _pump(WidgetTester tester, {required bool authenticated, List<Map<String, dynamic>> bookings = const [], int failNext = 0}) async {
  final bundle = await _buildApp(
    authenticated: authenticated,
    bookings: bookings,
    failNext: failNext,
  );
  await tester.runAsync(() async {
    await bundle.auth.restoreSession();
    await Future<void>.delayed(Duration.zero);
  });
  await tester.pumpWidget(bundle.app);
  await tester.pumpAndSettle();
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

void main() {
  setUpAll(Formatters.ensureDateSymbols);

  testWidgets('guests see the sign-in prompt', (tester) async {
    await _pump(tester, authenticated: false);

    expect(find.text('Sign in to see your service bookings.'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('authenticated users with no bookings see the empty state', (
    tester,
  ) async {
    await _pump(tester, authenticated: true, bookings: []);

    expect(find.textContaining('No service bookings yet'), findsOneWidget);
    expect(find.text('Explore Services'), findsOneWidget);
  });

  testWidgets('API error shows the error state and Retry recovers', (
    tester,
  ) async {
    await _pump(
      tester,
      authenticated: true,
      bookings: [_booking(id: 'sr_1', package: 'full')],
      failNext: 1,
    );

    expect(find.text('Failed to load service requests'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Full Service'), findsOneWidget);
  });

  testWidgets('booking cards show package, bike, date/time, address and status',
      (tester) async {
    await _pump(
      tester,
      authenticated: true,
      bookings: [_booking(id: 'sr_1', package: 'full', status: 'confirmed')],
    );

    expect(find.text('Full Service'), findsOneWidget);
    expect(find.text('Confirmed'), findsOneWidget);
    expect(find.text('Yamaha R15 V4'), findsOneWidget);
    expect(find.text('15 Aug 2026 at 10:30 AM'), findsOneWidget);
    expect(find.text('MG Road, Pune'), findsOneWidget);
  });

  testWidgets('emergency bookings show the priority flag', (tester) async {
    await _pump(
      tester,
      authenticated: true,
      bookings: [
        _booking(id: 'sr_1', package: 'full', priority: 'emergency'),
      ],
    );

    expect(find.text('Emergency service'), findsOneWidget);
  });

  testWidgets('assigned garage and distance render on the card', (tester) async {
    await _pump(
      tester,
      authenticated: true,
      bookings: [
        _booking(
          id: 'sr_1',
          package: 'premium',
          garage: {
            '_id': 'g_1',
            'name': 'Rider Garage',
            'garageProfile': {'garageName': 'Rider Garage'},
          },
          garageDistanceKm: 2.4,
        ),
      ],
    );

    expect(find.text('Premium Service'), findsOneWidget);
    expect(find.textContaining('Rider Garage'), findsOneWidget);
    expect(find.textContaining('2.4 km'), findsOneWidget);
  });

  testWidgets('every backend status renders its label', (tester) async {
    await _pump(
      tester,
      authenticated: true,
      bookings: [
        _booking(id: 'sr_1', package: 'basic', status: 'requested'),
        _booking(id: 'sr_2', package: 'full', status: 'confirmed'),
        _booking(id: 'sr_3', package: 'premium', status: 'in_progress'),
        _booking(id: 'sr_4', package: 'basic', status: 'completed'),
        _booking(id: 'sr_5', package: 'full', status: 'cancelled'),
      ],
    );

    for (final label in [
      'Requested',
      'Confirmed',
      'In Progress',
      'Completed',
      'Cancelled',
    ]) {
      await tester.scrollUntilVisible(find.text(label), 150);
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('tapping a booking opens details with garage contact', (
    tester,
  ) async {
    await _pump(
      tester,
      authenticated: true,
      bookings: [
        _booking(
          id: 'sr_1',
          package: 'full',
          status: 'in_progress',
          garage: {
            '_id': 'g_1',
            'name': 'Rider Garage',
            'email': 'garage@ridercraft.app',
            'contactNumber': '9876500112',
            'garageProfile': {'garageName': 'Rider Garage'},
          },
          garageDistanceKm: 2.4,
        ),
      ],
    );

    await tester.tap(find.text('Full Service'));
    await tester.pumpAndSettle();

    expect(find.text('Booking Details'), findsOneWidget);
    expect(find.text('Assigned garage'), findsOneWidget);
    expect(find.text('Rider Garage (2.4 km)'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Garage contact'), 150);
    expect(find.text('Garage contact'), findsOneWidget);
    expect(find.textContaining('9876500112'), findsOneWidget);
    expect(find.textContaining('garage@ridercraft.app'), findsOneWidget);
  });

  group('responsive My Bookings never overflows', () {
    final bookings = [
      _booking(id: 'sr_1', package: 'premium', priority: 'emergency'),
      _booking(
        id: 'sr_2',
        package: 'full',
        status: 'in_progress',
        bike: 'Honda CB Shine SP 125',
        address: 'House 42, Long Street Road, Sector 9, Chandigarh',
        garage: {'_id': 'g_1', 'name': 'Rider Garage'},
        garageDistanceKm: 12.7,
      ),
      _booking(id: 'sr_3', package: 'basic', status: 'completed'),
    ];

    for (final width in [320.0, 360.0, 390.0, 430.0, 768.0, 1024.0]) {
      for (final textScale in [1.0, 1.3, 2.0]) {
        testWidgets(
            'renders list at ${width}px width, ${textScale}x text without overflow',
            (tester) async {
          _setViewport(
            tester,
            width: width,
            height: 844,
            textScale: textScale,
          );
          await _pump(tester, authenticated: true, bookings: bookings);

          expect(tester.takeException(), isNull,
              reason: 'overflow in the initial bookings viewport');

          await tester.drag(find.byType(ListView), const Offset(0, -1500));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: 'overflow after scrolling the bookings list');
        });
      }
    }

    for (final textScale in [1.0, 1.3, 2.0]) {
      testWidgets('renders list on a Pixel 7 Pro (412x915) at ${textScale}x text',
          (tester) async {
        _setViewport(
          tester,
          width: 412,
          height: 915,
          textScale: textScale,
        );
        await _pump(tester, authenticated: true, bookings: bookings);

        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(ListView), const Offset(0, -1500));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('renders empty state at 320px width, 2.0x text', (tester) async {
      _setViewport(tester, width: 320, height: 568, textScale: 2.0);
      await _pump(tester, authenticated: true, bookings: []);

      expect(find.textContaining('No service bookings yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders guest state at 320px width, 2.0x text', (tester) async {
      _setViewport(tester, width: 320, height: 568, textScale: 2.0);
      await _pump(tester, authenticated: false);

      expect(find.text('Sign in to see your service bookings.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}