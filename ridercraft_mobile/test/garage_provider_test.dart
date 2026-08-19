// GarageProvider behavior: load, status response, billing and payment flows.
import 'package:flutter_test/flutter_test.dart';

import 'package:ridercraft_mobile/models/service_request.dart';
import 'package:ridercraft_mobile/providers/garage_provider.dart';
import 'package:ridercraft_mobile/services/api_client.dart';
import 'package:ridercraft_mobile/services/garage_service.dart';

class _FakeGarageService extends GarageService {
  _FakeGarageService(List<Map<String, dynamic>> seed) : super(ApiClient()) {
    _list = seed;
  }

  late List<Map<String, dynamic>> _list;
  bool failList = false;
  bool failRespond = false;
  bool failBilling = false;
  bool failPayment = false;

  int respondCalls = 0;
  int billingCalls = 0;
  int paymentCalls = 0;
  String? lastStatus;
  String? lastNote;
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
    lastNote = garageNote;
    if (failRespond) throw Exception('respond failed');
    _mutate(id, {
      'status': status,
      'garageNote': garageNote,
      'garageRespondedAt': '2026-08-19T07:00:00.000Z',
    });
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
    if (failBilling) throw Exception('billing failed');
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
    if (failPayment) throw Exception('payment failed');
    _mutate(id, {'billing.status': billingStatus, 'paymentMethod': paymentMethod});
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

Map<String, dynamic> _booking(String id, {String status = 'requested', bool emergency = false}) => {
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

void main() {
  group('GarageProvider.loadBookings', () {
    test('loads and derives counts', () async {
      final service = _FakeGarageService([
        _booking('a', status: 'requested', emergency: true),
        _booking('b', status: 'confirmed'),
        _booking('c', status: 'in_progress'),
        _booking('d', status: 'completed'),
      ]);
      final provider = GarageProvider(service);

      await provider.loadBookings();

      expect(provider.bookings, hasLength(4));
      expect(provider.loading, isFalse);
      expect(provider.error, isNull);
      expect(provider.pendingCount, 2);
      expect(provider.activeCount, 1);
      expect(provider.completedCount, 1);
      expect(provider.emergencyBookings.map((b) => b.id), ['a']);
      expect(provider.recentBookings.first.id, 'a');
    });

    test('surfaces errors without crashing', () async {
      final service = _FakeGarageService([])..failList = true;
      final provider = GarageProvider(service);

      await provider.loadBookings();

      expect(provider.error, isNotNull);
      expect(provider.bookings, isEmpty);
    });

    test('ignores a second load while already loading', () async {
      final service = _FakeGarageService([_booking('a')]);
      final provider = GarageProvider(service);
      final first = provider.loadBookings();
      await provider.loadBookings();
      await first;
      expect(provider.bookings, hasLength(1));
    });
  });

  group('GarageProvider.respondToBooking', () {
    test('updates status and reloads', () async {
      final service = _FakeGarageService([_booking('a')]);
      final provider = GarageProvider(service);
      String? message;
      await provider.loadBookings();

      final ok = await provider.respondToBooking(
        id: 'a',
        status: 'confirmed',
        garageNote: 'ok',
        onSuccess: (m) => message = m,
      );

      expect(ok, isTrue);
      expect(service.respondCalls, 1);
      expect(service.lastStatus, 'confirmed');
      expect(service.lastNote, 'ok');
      expect(message, isNotNull);
      expect(provider.bookingById('a')!.status, 'confirmed');
      expect(provider.bookingById('a')!.garageNote, 'ok');
    });

    test('guards against a concurrent second call', () async {
      final service = _FakeGarageService([_booking('a')]);
      final provider = GarageProvider(service);
      await provider.loadBookings();

      final first = provider.respondToBooking(id: 'a', status: 'confirmed');
      final second = provider.respondToBooking(id: 'a', status: 'completed');
      final results = await Future.wait([first, second]);

      expect(results, contains(true));
      expect(results, contains(false));
      expect(service.respondCalls, 1);
    });

    test('reports failure', () async {
      final service = _FakeGarageService([_booking('a')])..failRespond = true;
      final provider = GarageProvider(service);
      await provider.loadBookings();

      final ok = await provider.respondToBooking(id: 'a', status: 'confirmed');

      expect(ok, isFalse);
      expect(provider.responseError, isNotNull);
    });
  });

  group('GarageProvider billing + payment', () {
    test('saveBilling posts items and reloads', () async {
      final service = _FakeGarageService([_booking('a')]);
      final provider = GarageProvider(service);
      await provider.loadBookings();

      final ok = await provider.saveBilling(
        id: 'a',
        laborCharge: 300,
        tax: 24,
        discount: 0,
        items: [
          {'name': 'Oil', 'quantity': 1, 'unitPrice': 350},
        ],
        notes: 'Synthetic',
      );

      expect(ok, isTrue);
      expect(service.billingCalls, 1);
      expect(service.lastItems, hasLength(1));
      expect(provider.bookingById('a')!.billing.isIssued, isTrue);
      expect(provider.bookingById('a')!.billing.items.first.name, 'Oil');
    });

    test('updatePayment marks paid', () async {
      final service = _FakeGarageService([_booking('a')]);
      final provider = GarageProvider(service);
      await provider.loadBookings();

      final ok = await provider.updateBillingPayment(
        id: 'a',
        billingStatus: 'paid',
        paymentMethod: 'cash',
      );

      expect(ok, isTrue);
      expect(service.paymentCalls, 1);
      expect(service.lastBillingStatus, 'paid');
      expect(service.lastPaymentMethod, 'cash');
      expect(provider.bookingById('a')!.billing.status, 'paid');
    });

    test('billing failure sets error', () async {
      final service = _FakeGarageService([_booking('a')])..failBilling = true;
      final provider = GarageProvider(service);

      final ok = await provider.saveBilling(
        id: 'a',
        laborCharge: 300,
        tax: 24,
        discount: 0,
        items: const [],
      );

      expect(ok, isFalse);
      expect(provider.billingError, isNotNull);
    });
  });

  test('clearMessages resets transient errors', () async {
    final service = _FakeGarageService([_booking('a')])..failBilling = true;
    final provider = GarageProvider(service);

    await provider.saveBilling(
      id: 'a',
      laborCharge: 300,
      tax: 24,
      discount: 0,
      items: const [],
    );
    expect(provider.billingError, isNotNull);

    provider.clearMessages();
    expect(provider.billingError, isNull);
    expect(provider.lastMessage, isNull);
  });
}