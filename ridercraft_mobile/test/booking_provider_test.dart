import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ridercraft_mobile/providers/booking_provider.dart';
import 'package:ridercraft_mobile/services/api_client.dart';
import 'package:ridercraft_mobile/services/api_exception.dart';
import 'package:ridercraft_mobile/services/booking_service.dart';
import 'package:ridercraft_mobile/services/token_store.dart';

/// Returns a canned body per (method, path).
class _FakeAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;

  _FakeAdapter(this.handler);

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

ResponseBody _json(String body, int status) => ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

const _createdBooking = {
  '_id': 'sr_12345',
  'packageType': 'full',
  'bikeModel': 'Yamaha R15 V4',
  'preferredDate': '2026-08-15',
  'preferredTime': '10:30',
  'pickupAddress': '12 Bike Lane, Pune',
  'contactNumber': '9876543210',
  'status': 'requested',
  'createdAt': '2026-08-11T09:00:00.000Z',
};

void main() {
  late TokenStore tokenStore;

  setUp(() {
    tokenStore = TokenStore();
  });

  BookingProvider buildProvider(
    Future<ResponseBody> Function(RequestOptions) handler,
  ) {
    final adapter = _FakeAdapter(handler);
    final api = ApiClient(
      tokenProvider: () => tokenStore.current,
      dio: Dio()..httpClientAdapter = adapter,
    );
    return BookingProvider(BookingService(api));
  }

  group('loadBookings', () {
    test('populates bookings on a successful response', () async {
      final provider = buildProvider(
        (options) async => _json(jsonEncode([_createdBooking]), 200),
      );

      await provider.loadBookings();

      expect(provider.loading, isFalse);
      expect(provider.error, isNull);
      expect(provider.bookings, hasLength(1));
      expect(provider.bookings.first.id, 'sr_12345');
      expect(provider.bookings.first.statusLabel, 'Requested');
    });

    test('sets an error and keeps the list empty on API failure', () async {
      final provider = buildProvider(
        (options) async => _json('{"error":"Something broke"}', 500),
      );

      await provider.loadBookings();

      expect(provider.loading, isFalse);
      expect(provider.error, isNotNull);
      expect(provider.bookings, isEmpty);
    });

    test('parses pickup location and the auto-assigned garage', () async {
      final provider = buildProvider(
        (options) async => _json(
          jsonEncode([
            {
              ..._createdBooking,
              'pickupLocation': {
                'latitude': 18.5204,
                'longitude': 73.8567,
                'accuracyMeters': 12.5,
                'capturedAt': '2026-08-11T09:00:00.000Z',
              },
              'priority': 'emergency',
              'breakdownIssue': 'Bike won\'t start',
              'assignedGarage': {
                '_id': 'g_1',
                'name': 'Rider Garage',
                'email': 'garage@ridercraft.app',
                'contactNumber': '9876500112',
                'garageProfile': {'garageName': 'Rider Garage'},
              },
              'assignedGarageDistanceKm': 2.4,
            },
          ]),
          200,
        ),
      );

      await provider.loadBookings();

      final booking = provider.bookings.single;
      expect(booking.pickupLatitude, 18.5204);
      expect(booking.pickupLongitude, 73.8567);
      expect(booking.pickupAccuracyMeters, 12.5);
      expect(booking.pickupCapturedAt, isNotNull);
      expect(booking.isEmergency, isTrue);
      expect(booking.priorityLabel, 'Emergency');
      expect(booking.assignedGarageId, 'g_1');
      expect(booking.assignedGarageName, 'Rider Garage');
      expect(booking.assignedGarageContact, '9876500112');
      expect(booking.assignedGarageEmail, 'garage@ridercraft.app');
      expect(booking.assignedGarageDistanceKm, 2.4);
      expect(booking.statusLabel, 'Requested');
    });

    test('parses nested garageProfile.garageName and a cancelled status', () async {
      final provider = buildProvider(
        (options) async => _json(
          jsonEncode([
            {
              ..._createdBooking,
              'status': 'cancelled',
              'assignedGarage': {
                'name': '',
                'garageProfile': {'garageName': 'Speedy Bikes'},
              },
              'assignedGarageDistanceKm': 7.25,
            },
          ]),
          200,
        ),
      );

      await provider.loadBookings();

      final booking = provider.bookings.single;
      expect(booking.assignedGarageName, 'Speedy Bikes');
      expect(booking.statusLabel, 'Cancelled');
    });
  });

  group('createBooking', () {
    test('returns the created booking and inserts it at the front', () async {
      final provider = buildProvider((options) async {
        if (options.method == 'GET') {
          return _json('[]', 200);
        }
        expect(options.method, 'POST');
        expect(options.path, '/service-requests');
        final body = options.data as Map<String, dynamic>;
        expect(body['packageType'], 'full');
        expect(body['bikeModel'], 'Yamaha R15 V4');
        expect(body['preferredDate'], '2026-08-15');
        expect(body['preferredTime'], '10:30');
        expect(body['priority'], 'normal');
        return _json(
          jsonEncode({'message': 'ok', 'request': _createdBooking}),
          201,
        );
      });

      await provider.loadBookings();
      final booking = await provider.createBooking(
        packageType: 'full',
        bikeModel: 'Yamaha R15 V4',
        preferredDate: '2026-08-15',
        preferredTime: '10:30',
        pickupAddress: '12 Bike Lane, Pune',
        pickupLocation: {
          'latitude': 18.5204,
          'longitude': 73.8567,
        },
        contactNumber: '9876543210',
      );

      expect(booking.id, 'sr_12345');
      expect(provider.bookings.first.id, 'sr_12345');
      expect(provider.submitting, isFalse);
    });

    test('rethrows the error and sets it on the provider on failure', () async {
      final provider = buildProvider(
        (options) async => _json('{"error":"Invalid service package"}', 400),
      );

      await expectLater(
        provider.createBooking(
          packageType: 'gold',
          bikeModel: 'Yamaha R15 V4',
          preferredDate: '2026-08-15',
          preferredTime: '10:30',
          pickupAddress: '12 Bike Lane, Pune',
          pickupLocation: {
            'latitude': 18.5204,
            'longitude': 73.8567,
          },
          contactNumber: '9876543210',
        ),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Invalid service package')),
      );
      expect(provider.error, 'Invalid service package');
    });
  });
}
