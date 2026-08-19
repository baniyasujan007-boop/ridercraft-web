// Garage partner screens: dashboard states, bookings filter, the booking
// detail actions (status, billing, payment) and a small-device / large-text
// responsive smoke test of the whole GarageScaffold.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridercraft_mobile/models/service_request.dart';
import 'package:ridercraft_mobile/models/user.dart';
import 'package:ridercraft_mobile/providers/auth_provider.dart';
import 'package:ridercraft_mobile/providers/garage_provider.dart';
import 'package:ridercraft_mobile/screens/garage/garage_booking_detail_screen.dart';
import 'package:ridercraft_mobile/screens/garage/garage_bookings_screen.dart';
import 'package:ridercraft_mobile/screens/garage/garage_scaffold.dart';
import 'package:ridercraft_mobile/services/api_client.dart';
import 'package:ridercraft_mobile/services/auth_service.dart';
import 'package:ridercraft_mobile/services/garage_service.dart';
import 'package:ridercraft_mobile/services/token_store.dart';
import 'package:ridercraft_mobile/theme/app_theme.dart';
import 'package:ridercraft_mobile/utils/formatters.dart';
import 'package:ridercraft_mobile/widgets/error_view.dart';
import 'package:ridercraft_mobile/widgets/rc_chip.dart';

import 'support/test_storage.dart';

class _FakeAuthService extends AuthService {
  _FakeAuthService(super.api, super.storage, {required User initial})
      : profile = initial;

  User profile;

  @override
  Future<User> fetchProfile() async => profile;
}

class _FakeGarageService extends GarageService {
  _FakeGarageService(List<Map<String, dynamic>> seed) : super(ApiClient()) {
    _list = seed;
  }

  late List<Map<String, dynamic>> _list;
  bool failList = false;

  int respondCalls = 0;
  int billingCalls = 0;
  int paymentCalls = 0;
  String? lastStatus;
  List<Map<String, dynamic>>? lastItems;
  String? lastBillingStatus;
  String? lastPaymentMethod;

  @override
  Future<List<ServiceRequest>> listGarageBookings() async {
    if (failList) throw Exception('network down');
    return _list.map(ServiceRequest.fromJson).toList();
  }

  @override
  Future<void> respondToBooking({
    required String id,
    required String status,
    String garageNote = '',
  }) async {
    respondCalls++;
    lastStatus = status;
    _mutate(id, {'status': status, 'garageNote': garageNote});
  }

  @override
  Future<void> saveBilling({
    required String id,
    required num laborCharge,
    required num tax,
    required num discount,
    required List<Map<String, dynamic>> items,
    String notes = '',
  }) async {
    billingCalls++;
    lastItems = items;
    _mutate(id, {
      'billing': {
        'laborCharge': laborCharge,
        'items': items,
        'subtotal': laborCharge + 10,
        'tax': tax,
        'discount': discount,
        'total': laborCharge + 10 + tax - discount,
        'status': 'issued',
        'notes': notes,
        'paymentMethod': '',
        'paymentReference': '',
        'issuedAt': '2026-08-19T07:05:00.000Z',
        'paidAt': null,
      }
    });
  }

  @override
  Future<void> updatePayment({
    required String id,
    required String billingStatus,
    required String paymentMethod,
    String paymentReference = '',
  }) async {
    paymentCalls++;
    lastBillingStatus = billingStatus;
    lastPaymentMethod = paymentMethod;
    _mutate(id, {'billing.status': billingStatus, 'billing.paymentMethod': paymentMethod});
  }

  void _mutate(String id, Map<String, dynamic> patch) {
    for (final item in _list) {
      if (item['_id'] != id) continue;
      for (final entry in patch.entries) {
        if (entry.key.contains('.')) {
          final parts = entry.key.split('.');
          final parent = item.putIfAbsent(parts[0], () => <String, dynamic>{})
              as Map<String, dynamic>;
          parent[parts[1]] = entry.value;
        } else {
          item[entry.key] = entry.value;
        }
      }
    }
  }
}

Map<String, dynamic> _booking(
  String id, {
  String status = 'requested',
  bool emergency = false,
}) =>
    {
      '_id': id,
      'packageType': 'basic',
      'bikeModel': 'Honda SP 125',
      'preferredDate': '2026-08-25',
      'preferredTime': '10:30',
      'pickupAddress': '12 MG Road',
      'contactNumber': '9876543210',
      'priority': emergency ? 'emergency' : 'normal',
      'status': status,
      'createdAt': '2026-08-19T05:00:00.000Z',
      'user': {'_id': 'u1', 'name': 'Aarav', 'email': 'a@x.in'},
    };

User _garageUser() => User(
      id: 'g1',
      name: 'Speed Motors',
      email: 'speed@garage.in',
      role: 'garage',
      garageProfile: GarageProfile.fromJson({
        'garageName': 'Speed Motors Workshop',
        'isAvailable': false,
      }),
    );

class _Harness {
  _Harness(this.auth, this.garage, this.service);

  final AuthProvider auth;
  final GarageProvider garage;
  final _FakeGarageService service;

  static Future<_Harness> build(List<Map<String, dynamic>> seed) async {
    SharedPreferences.setMockInitialValues(
      const {'ridercraft_auth_token': 'stored-token'},
    );
    final prefs = await SharedPreferences.getInstance();
    final storage = TestStorageService(prefs);
    final service = _FakeGarageService(seed);
    final authService = _FakeAuthService(
      ApiClient(),
      storage,
      initial: _garageUser(),
    );
    final auth = AuthProvider(authService, TokenStore());
    await auth.restoreSession();
    return _Harness(auth, GarageProvider(service), service);
  }

  Widget app({Widget? home}) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: garage),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: home ?? const GarageScaffold(),
        ),
      );
}

void main() {
  setUpAll(() async {
    await Formatters.ensureDateSymbols();
  });

  group('GarageDashboardScreen', () {
    testWidgets('renders garage header, counts and recent bookings',
        (tester) async {
      final harness = await _Harness.build([
        _booking('a', status: 'requested', emergency: true),
        _booking('b', status: 'confirmed'),
        _booking('c', status: 'in_progress'),
        _booking('d', status: 'completed'),
      ]);
      await tester.pumpWidget(harness.app());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Garage Partner'), findsOneWidget);
      expect(find.text('Speed Motors Workshop'), findsOneWidget);
      expect(find.text('UNAVAILABLE'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('EMERGENCY'), findsOneWidget);
      expect(find.text('Honda SP 125'), findsWidgets);
    });

    testWidgets('shows the empty state when nothing is assigned',
        (tester) async {
      final harness = await _Harness.build([]);
      await tester.pumpWidget(harness.app());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('No bookings assigned yet.'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('shows an error state with a working retry', (tester) async {
      final harness = await _Harness.build([_booking('a')]);
      harness.service.failList = true;
      await tester.pumpWidget(harness.app());
      await tester.pumpAndSettle();

      expect(find.byType(ErrorView), findsOneWidget);

      harness.service.failList = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorView), findsNothing);
      expect(find.text('Honda SP 125'), findsOneWidget);
    });
  });

  group('GarageBookingsScreen', () {
    testWidgets('filters by status chip', (tester) async {
      final harness = await _Harness.build([
        _booking('a', status: 'requested'),
        _booking('b', status: 'completed'),
      ]);
      await harness.garage.loadBookings();
      await tester.pumpWidget(
        harness.app(home: const Scaffold(body: GarageBookingsScreen())),
      );
      await tester.pumpAndSettle();

      // All bookings on screen before filtering (2 cards).
      expect(find.text('Honda SP 125'), findsNWidgets(2));

      await tester.tap(find.widgetWithText(RcChip, 'Completed'));
      await tester.pumpAndSettle();

      expect(find.text('Honda SP 125'), findsOneWidget);

      await tester.tap(find.widgetWithText(RcChip, 'Requested'));
      await tester.pumpAndSettle();

      expect(find.text('Honda SP 125'), findsOneWidget);
    });
  });

  group('GarageBookingDetailScreen', () {
    testWidgets('confirms a booking from the status stepper', (tester) async {
      final harness = await _Harness.build([_booking('a')]);
      await harness.garage.loadBookings();
      await tester.pumpWidget(
        harness.app(home: const GarageBookingDetailScreen(bookingId: 'a')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Booking Detail'), findsOneWidget);

      await tester.tap(find.text('Confirmed'));
      await tester.pumpAndSettle();

      expect(harness.service.respondCalls, 1);
      expect(harness.service.lastStatus, 'confirmed');
      expect(find.text('Booking updated to Confirmed.'), findsOneWidget);
    });

    testWidgets('issues a bill then marks it paid', (tester) async {
      final harness = await _Harness.build([_booking('a')]);
      await harness.garage.loadBookings();
      await tester.pumpWidget(
        harness.app(home: const GarageBookingDetailScreen(bookingId: 'a')),
      );
      await tester.pumpAndSettle();

      // Open the billing sheet (it sits below the fold on a 800x600 viewport).
      await tester.scrollUntilVisible(
        find.text('Create Bill'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Create Bill'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create Bill'));
      await tester.pumpAndSettle();
      expect(find.text('Service Bill'), findsOneWidget);

      // Fill in the bill.
      await tester.enterText(
        find.widgetWithText(TextField, 'Labor Charge (₹)'),
        '300',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Tax (₹)'),
        '24',
      );
      await tester.enterText(find.widgetWithText(TextField, 'Item name'), 'Oil');
      await tester.enterText(
        find.widgetWithText(TextField, 'Unit price (₹)'),
        '350',
      );

      await tester.tap(find.text('Save Bill'));
      await tester.pumpAndSettle();

      expect(harness.service.billingCalls, 1);
      expect(harness.service.lastItems, hasLength(1));
      expect(harness.service.lastItems!.first['name'], 'Oil');
      // Sheet closed and the bill is now visible.
      expect(find.text('Service Bill'), findsNothing);
      expect(find.text('Edit Bill'), findsOneWidget);

      // Payment now unlocks.
      await tester.scrollUntilVisible(
        find.text('Payment'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Payment'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Payment'));
      await tester.pumpAndSettle();
      expect(find.text('Mark Paid'), findsOneWidget);

      await tester.tap(find.text('Mark Paid'));
      await tester.pump(); // start success animation + 900ms pop timer
      await tester.pump(const Duration(milliseconds: 950)); // fire the pop
      await tester.pumpAndSettle();

      expect(harness.service.paymentCalls, 1);
      expect(harness.service.lastBillingStatus, 'paid');
      expect(find.text('Paid via'), findsOneWidget);
    });
  });

  group('GarageScaffold responsive', () {
    testWidgets('small phone + 2x text renders every tab without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(320 * 2.0, 568 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final harness = await _Harness.build([
        _booking('a', status: 'in_progress', emergency: true),
        _booking('b', status: 'completed'),
      ]);
      await tester.pumpWidget(harness.app());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Bookings'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Back to the dashboard tab.
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}