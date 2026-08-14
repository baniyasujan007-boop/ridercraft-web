import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridercraft_mobile/models/service_package.dart';
import 'package:ridercraft_mobile/models/service_request.dart';
import 'package:ridercraft_mobile/providers/bike_provider.dart';
import 'package:ridercraft_mobile/providers/booking_provider.dart';
import 'package:ridercraft_mobile/routes/app_routes.dart';
import 'package:ridercraft_mobile/screens/bookings/booking_success_screen.dart';
import 'package:ridercraft_mobile/screens/bookings/service_booking_screen.dart';
import 'package:ridercraft_mobile/services/api_client.dart';
import 'package:ridercraft_mobile/services/booking_service.dart';
import 'package:ridercraft_mobile/services/storage_service.dart';
import 'package:ridercraft_mobile/services/token_store.dart';
import 'package:ridercraft_mobile/theme/app_theme.dart';
import 'package:ridercraft_mobile/utils/formatters.dart';

ResponseBody _json(String body, int status) => ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

Map<String, dynamic> _createdBooking({String package = 'basic'}) => {
      '_id': 'sr_12345',
      'packageType': package,
      'bikeModel': 'Yamaha R15 V4',
      'preferredDate': '2026-08-15',
      'preferredTime': '10:30',
      'pickupAddress': 'MG Road, Pune',
      'contactNumber': '9876543210',
      'priority': 'normal',
      'status': 'requested',
      'createdAt': '2026-08-11T09:00:00.000Z',
    };

/// In-memory backend for the two real service-request endpoints.
class _FlowAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;

  _FlowAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

Future<Widget> _buildFormScreen(StorageService storage) async {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => BikeProvider(storage)..load()),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: ServiceBookingScreen(package: servicePackages.first),
    ),
  );
}

Future<Widget> _buildFlowScreen({
  required StorageService storage,
  required TokenStore tokenStore,
  required HttpClientAdapter adapter,
}) async {
  final api = ApiClient(
    tokenProvider: () => tokenStore.current,
    dio: Dio()..httpClientAdapter = adapter,
  );
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => BikeProvider(storage)..load()),
      ChangeNotifierProvider(create: (_) => BookingProvider(BookingService(api))),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: ServiceBookingScreen(package: servicePackages.first),
    ),
  );
}

void _setViewport(
  WidgetTester tester, {
  required double width,
  required double height,
  double textScale = 1.0,
}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

Future<StorageService> _storageWithBike() async {
  SharedPreferences.setMockInitialValues({
    'ridercraft_my_bikes_v1': jsonEncode({
      'bikes': [
        {
          'id': 'b1',
          'brand': 'Yamaha',
          'model': 'R15 V4',
          'registrationNumber': 'MH-12-AB-1234',
        }
      ],
      'selectedId': null,
    }),
  });
  final prefs = await SharedPreferences.getInstance();
  return StorageService(prefs);
}

Future<StorageService> _storageWithBikes({
  required List<Map<String, dynamic>> bikes,
  String? selectedId,
}) async {
  SharedPreferences.setMockInitialValues({
    'ridercraft_my_bikes_v1': jsonEncode({
      'bikes': bikes,
      'selectedId': selectedId,
    }),
  });
  final prefs = await SharedPreferences.getInstance();
  return StorageService(prefs);
}

Future<void> _selectDate(WidgetTester tester) async {
  await tester.tap(find.text('Select date'));
  await tester.pumpAndSettle();
  // Tapping the current day selects today (>= firstDate) in the M3 grid.
  await tester.tap(find.text('${DateTime.now().day}'));
  await tester.pump();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

Future<void> _selectTime(WidgetTester tester) async {
  await tester.tap(find.text('Select time'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(Formatters.ensureDateSymbols);

  testWidgets('pre-selects the saved bike and validates required fields', (
    tester,
  ) async {
    _setViewport(tester, width: 600, height: 2600);
    final storage = await _storageWithBike();

    await tester.pumpWidget(await _buildFormScreen(storage));
    await tester.pumpAndSettle();

    expect(find.text('Yamaha R15 V4'), findsOneWidget);
    // The single saved bike is auto-selected as the booking default.
    expect(
      find.descendant(
        of: find.widgetWithText(InkWell, 'Yamaha R15 V4'),
        matching: find.byIcon(Icons.radio_button_checked_rounded),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Continue to Review'));
    await tester.pump();
    expect(find.text('Pickup address is required'), findsOneWidget);

    // Let the first snack bar fully show, expire and dismiss so the next one
    // can appear immediately instead of queuing behind it.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    await tester.enterText(_field('Pickup address'), 'MG Road, Pune');
    await tester.enterText(_field('Latitude'), '18.5204');
    await tester.enterText(_field('Longitude'), '73.8567');
    await tester.enterText(_field('Contact number'), '9876543210');
    await tester.tap(find.text('Continue to Review'));
    await tester.pump();

    // A bike is already selected, so the next required step is the schedule.
    expect(find.text('Select a preferred date to continue.'), findsOneWidget);
  });

  testWidgets('demands a bike when none is saved', (tester) async {
    _setViewport(tester, width: 600, height: 2600);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);

    await tester.pumpWidget(await _buildFormScreen(storage));
    await tester.pumpAndSettle();

    expect(find.text("You don't have a bike saved yet."), findsOneWidget);

    await tester.enterText(_field('Pickup address'), 'MG Road, Pune');
    await tester.enterText(_field('Latitude'), '18.5204');
    await tester.enterText(_field('Longitude'), '73.8567');
    await tester.enterText(_field('Contact number'), '9876543210');
    await tester.tap(find.text('Continue to Review'));
    await tester.pump();

    expect(find.text('Select a bike to continue.'), findsOneWidget);
  });

  testWidgets('default bike auto-populates from My Bike and can be changed', (
    tester,
  ) async {
    _setViewport(tester, width: 600, height: 2600);
    final storage = await _storageWithBikes(
      bikes: [
        {'id': 'a', 'brand': 'Honda', 'model': 'SP 125'},
        {'id': 'b', 'brand': 'Yamaha', 'model': 'R15 V4'},
      ],
      selectedId: 'b',
    );
    final tokenStore = TokenStore()..current = 'test-token';
    Map<String, dynamic>? posted;

    final adapter = _FlowAdapter((options) async {
      if (options.method == 'GET') return _json('[]', 200);
      if (options.method == 'POST') {
        posted = Map<String, dynamic>.from(options.data as Map);
        return _json(
          jsonEncode({'message': 'ok', 'request': _createdBooking()}),
          201,
        );
      }
      return _json('[]', 200);
    });

    await tester.pumpWidget(await _buildFlowScreen(
      storage: storage,
      tokenStore: tokenStore,
      adapter: adapter,
    ));
    await tester.pumpAndSettle();

    // The bike selected in My Bike (Yamaha) is the auto-selected default.
    expect(
      find.descendant(
        of: find.widgetWithText(InkWell, 'Yamaha R15 V4'),
        matching: find.byIcon(Icons.radio_button_checked_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.widgetWithText(InkWell, 'Honda SP 125'),
        matching: find.byIcon(Icons.radio_button_checked_rounded),
      ),
      findsNothing,
    );

    // The rider can still switch to another saved bike.
    await tester.tap(find.text('Honda SP 125'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.widgetWithText(InkWell, 'Honda SP 125'),
        matching: find.byIcon(Icons.radio_button_checked_rounded),
      ),
      findsOneWidget,
    );

    await tester.enterText(_field('Pickup address'), 'MG Road, Pune');
    await tester.enterText(_field('Latitude'), '18.5204');
    await tester.enterText(_field('Longitude'), '73.8567');
    await tester.enterText(_field('Contact number'), '9876543210');
    await _selectDate(tester);
    await _selectTime(tester);

    await tester.tap(find.text('Continue to Review'));
    await tester.pumpAndSettle();
    // Review reflects the changed bike.
    expect(find.text('Honda SP 125'), findsOneWidget);

    await tester.ensureVisible(find.text('Confirm Booking'));
    await tester.tap(find.text('Confirm Booking'));
    await tester.pumpAndSettle();

    // The payload sends the rider's chosen bike as `bikeModel`.
    expect(posted, isNotNull);
    expect(posted!['bikeModel'], 'Honda SP 125');
  });

  testWidgets('rejects invalid latitude and longitude', (tester) async {
    _setViewport(tester, width: 600, height: 2600);
    final storage = await _storageWithBike();

    await tester.pumpWidget(await _buildFormScreen(storage));
    await tester.pumpAndSettle();

    await tester.enterText(_field('Pickup address'), 'MG Road, Pune');
    await tester.enterText(_field('Latitude'), '120');
    await tester.enterText(_field('Longitude'), '999');
    await tester.enterText(_field('Contact number'), '9876543210');
    await tester.tap(find.text('Continue to Review'));
    await tester.pump();

    expect(find.text('Invalid latitude'), findsOneWidget);
    expect(find.text('Invalid longitude'), findsOneWidget);
  });

  testWidgets('rejects a too-short contact number', (tester) async {
    _setViewport(tester, width: 600, height: 2600);
    final storage = await _storageWithBike();

    await tester.pumpWidget(await _buildFormScreen(storage));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Yamaha R15 V4'));
    await tester.enterText(_field('Pickup address'), 'MG Road, Pune');
    await tester.enterText(_field('Latitude'), '18.5204');
    await tester.enterText(_field('Longitude'), '73.8567');
    await tester.enterText(_field('Contact number'), '12345');
    await tester.tap(find.text('Continue to Review'));
    await tester.pump();

    expect(find.text('Enter a valid phone number'), findsOneWidget);
  });

  testWidgets('requires date and time before continuing', (tester) async {
    _setViewport(tester, width: 600, height: 2600);
    final storage = await _storageWithBike();

    await tester.pumpWidget(await _buildFormScreen(storage));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Yamaha R15 V4'));
    await tester.enterText(_field('Pickup address'), 'MG Road, Pune');
    await tester.enterText(_field('Latitude'), '18.5204');
    await tester.enterText(_field('Longitude'), '73.8567');
    await tester.enterText(_field('Contact number'), '9876543210');

    await tester.tap(find.text('Continue to Review'));
    await tester.pumpAndSettle();
    expect(find.text('Select a preferred date to continue.'), findsOneWidget);

    // Let the first snack bar fully show, expire and dismiss so the next one
    // can appear immediately instead of queuing behind it.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    await _selectDate(tester);
    await tester.tap(find.text('Continue to Review'));
    await tester.pumpAndSettle();
    expect(find.text('Select a preferred time to continue.'), findsOneWidget);
  });

  testWidgets('emergency priority requires a breakdown issue description', (
    tester,
  ) async {
    _setViewport(tester, width: 600, height: 2600);
    final storage = await _storageWithBike();

    await tester.pumpWidget(await _buildFormScreen(storage));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Yamaha R15 V4'));
    await tester.enterText(_field('Pickup address'), 'MG Road, Pune');
    await tester.enterText(_field('Latitude'), '18.5204');
    await tester.enterText(_field('Longitude'), '73.8567');
    await tester.enterText(_field('Contact number'), '9876543210');
    await _selectDate(tester);
    await _selectTime(tester);

    await tester.tap(find.text('Emergency'));
    await tester.pumpAndSettle();
    expect(find.text('Breakdown issue'), findsOneWidget);

    await tester.tap(find.text('Continue to Review'));
    await tester.pump();
    expect(
      find.text('Describe the breakdown issue for emergency service.'),
      findsOneWidget,
    );
  });

  testWidgets('complete flow posts the real payload and shows success', (
    tester,
  ) async {
    _setViewport(tester, width: 600, height: 2600);
    final storage = await _storageWithBike();
    final tokenStore = TokenStore()..current = 'test-token';
    Map<String, dynamic>? posted;

    final adapter = _FlowAdapter((options) async {
      if (options.method == 'GET') return _json('[]', 200);
      if (options.method == 'POST' && options.path == '/service-requests') {
        posted = Map<String, dynamic>.from(options.data as Map);
        return _json(
          jsonEncode({'message': 'ok', 'request': _createdBooking()}),
          201,
        );
      }
      return _json('[]', 200);
    });

    await tester.pumpWidget(await _buildFlowScreen(
      storage: storage,
      tokenStore: tokenStore,
      adapter: adapter,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Yamaha R15 V4'));
    await tester.enterText(_field('Pickup address'), 'MG Road, Pune');
    await tester.enterText(_field('Latitude'), '18.5204');
    await tester.enterText(_field('Longitude'), '73.8567');
    await tester.enterText(_field('Contact number'), '9876543210');
    await _selectDate(tester);
    await _selectTime(tester);
    await tester.enterText(_field('Notes (optional)'), 'Please check brakes');

    await tester.tap(find.text('Continue to Review'));
    await tester.pumpAndSettle();

    // Review reflects the entered values.
    expect(find.text('Review Booking'), findsOneWidget);
    expect(find.text('Basic Tune-Up'), findsOneWidget);
    expect(find.text('MG Road, Pune'), findsOneWidget);
    expect(find.textContaining('18.520400'), findsOneWidget);
    expect(find.text('Please check brakes'), findsOneWidget);

    await tester.ensureVisible(find.text('Confirm Booking'));
    await tester.tap(find.text('Confirm Booking'));
    await tester.pumpAndSettle();

    // The payload matches the backend contract.
    expect(posted, isNotNull);
    expect(posted!['packageType'], 'basic');
    expect(posted!['bikeModel'], 'Yamaha R15 V4');
    expect(posted!['pickupAddress'], 'MG Road, Pune');
    expect(posted!['contactNumber'], '9876543210');
    expect(posted!['priority'], 'normal');
    expect(posted!['notes'], 'Please check brakes');
    expect(posted!.containsKey('breakdownIssue'), isFalse,
        reason: 'breakdownIssue only sent when non-empty');
    final location = posted!['pickupLocation'] as Map<String, dynamic>;
    expect(location['latitude'], 18.5204);
    expect(location['longitude'], 73.8567);

    expect(find.text('Booking Confirmed!'), findsOneWidget);
  });

  testWidgets('emergency booking sends breakdownIssue in the payload', (
    tester,
  ) async {
    _setViewport(tester, width: 600, height: 2600);
    final storage = await _storageWithBike();
    final tokenStore = TokenStore()..current = 'test-token';
    Map<String, dynamic>? posted;

    final adapter = _FlowAdapter((options) async {
      if (options.method == 'GET') return _json('[]', 200);
      if (options.method == 'POST') {
        posted = Map<String, dynamic>.from(options.data as Map);
        return _json(
          jsonEncode({
            'message': 'ok',
            'request': _createdBooking(package: 'full'),
          }),
          201,
        );
      }
      return _json('[]', 200);
    });

    await tester.pumpWidget(await _buildFlowScreen(
      storage: storage,
      tokenStore: tokenStore,
      adapter: adapter,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Yamaha R15 V4'));
    await tester.enterText(_field('Pickup address'), 'MG Road, Pune');
    await tester.enterText(_field('Latitude'), '18.5204');
    await tester.enterText(_field('Longitude'), '73.8567');
    await tester.enterText(_field('Contact number'), '9876543210');
    await _selectDate(tester);
    await _selectTime(tester);
    await tester.tap(find.text('Emergency'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Breakdown issue'), 'Bike won\'t start');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue to Review'));
    await tester.pumpAndSettle();

    expect(find.text('Emergency'), findsOneWidget);
    expect(find.text('Bike won\'t start'), findsOneWidget);

    await tester.ensureVisible(find.text('Confirm Booking'));
    await tester.tap(find.text('Confirm Booking'));
    await tester.pumpAndSettle();

    expect(posted, isNotNull);
    expect(posted!['priority'], 'emergency');
    expect(posted!['breakdownIssue'], 'Bike won\'t start');
  });

  testWidgets('API failure on confirm shows the error and stays on review', (
    tester,
  ) async {
    _setViewport(tester, width: 600, height: 2600);
    final storage = await _storageWithBike();
    final tokenStore = TokenStore()..current = 'test-token';

    final adapter = _FlowAdapter((options) async {
      if (options.method == 'GET') return _json('[]', 200);
      if (options.method == 'POST') {
        return _json('{"error":"Invalid service package"}', 400);
      }
      return _json('[]', 200);
    });

    await tester.pumpWidget(await _buildFlowScreen(
      storage: storage,
      tokenStore: tokenStore,
      adapter: adapter,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Yamaha R15 V4'));
    await tester.enterText(_field('Pickup address'), 'MG Road, Pune');
    await tester.enterText(_field('Latitude'), '18.5204');
    await tester.enterText(_field('Longitude'), '73.8567');
    await tester.enterText(_field('Contact number'), '9876543210');
    await _selectDate(tester);
    await _selectTime(tester);

    await tester.tap(find.text('Continue to Review'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Confirm Booking'));
    await tester.tap(find.text('Confirm Booking'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid service package'), findsOneWidget);
    expect(find.text('Review Booking'), findsOneWidget);
    expect(find.text('Booking Confirmed!'), findsNothing);
  });

  group('responsive Service Booking form never overflows', () {
    for (final width in [320.0, 360.0, 390.0, 430.0, 768.0, 1024.0]) {
      for (final textScale in [1.0, 1.3, 2.0]) {
        testWidgets(
            'renders at ${width}px width, ${textScale}x text without overflow',
            (tester) async {
          _setViewport(
            tester,
            width: width,
            height: 844,
            textScale: textScale,
          );
          final storage = await _storageWithBike();
          await tester.pumpWidget(await _buildFormScreen(storage));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull,
              reason: 'overflow in the initial booking form viewport');

          // Build every section below the fold too.
          await tester.drag(find.byType(ListView), const Offset(0, -3000));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: 'overflow after scrolling the booking form');
        });
      }
    }

    for (final textScale in [1.0, 1.3, 2.0]) {
      testWidgets('renders on a Pixel 7 Pro (412x915) at ${textScale}x text', (
        tester,
      ) async {
        _setViewport(
          tester,
          width: 412,
          height: 915,
          textScale: textScale,
        );
        final storage = await _storageWithBike();
        await tester.pumpWidget(await _buildFormScreen(storage));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(ListView), const Offset(0, -3000));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Booking success screen never overflows', () {
    final booking = ServiceRequest.fromJson(_createdBooking());

    testWidgets('renders at 320px width, 2.0x text without overflow', (
      tester,
    ) async {
      _setViewport(tester, width: 320, height: 568, textScale: 2.0);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: BookingSuccessScreen(booking: booking),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Booking Confirmed!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders on a Pixel 7 Pro (412x915) at 1.0x text', (
      tester,
    ) async {
      _setViewport(tester, width: 412, height: 915, textScale: 1.0);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: BookingSuccessScreen(booking: booking),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}