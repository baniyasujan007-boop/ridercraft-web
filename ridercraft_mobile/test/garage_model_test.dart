// Garage model parsing + the billing arithmetic shared with the billing sheet.
import 'package:flutter_test/flutter_test.dart';

import 'package:ridercraft_mobile/models/service_request.dart';
import 'package:ridercraft_mobile/models/user.dart';
import 'package:ridercraft_mobile/utils/billing_calc.dart';

void main() {
  group('GarageProfile parsing', () {
    test('parses a full garage profile from GET /auth/profile', () {
      final user = User.fromJson({
        '_id': 'g1',
        'name': 'Speed Motors',
        'email': 'speed@garage.in',
        'role': 'garage',
        'garageProfile': {
          'garageName': 'Speed Motors Workshop',
          'garageAddress': '44 Ring Road',
          'location': {'latitude': 12.9716, 'longitude': 77.5946},
          'serviceRadiusKm': 20,
          'isAvailable': false,
        },
      });

      expect(user.isGarage, isTrue);
      expect(user.role, 'garage');
      final profile = user.garageProfile!;
      expect(profile.garageName, 'Speed Motors Workshop');
      expect(profile.garageAddress, '44 Ring Road');
      expect(profile.latitude, 12.9716);
      expect(profile.longitude, 77.5946);
      expect(profile.serviceRadiusKm, 20);
      expect(profile.isAvailable, isFalse);
      expect(profile.hasLocation, isTrue);
    });

    test('defaults apply when garageProfile is absent', () {
      final user = User.fromJson({
        '_id': 'g1',
        'name': 'Rider',
        'email': 'r@x.in',
        'role': 'user',
      });

      expect(user.isGarage, isFalse);
      expect(user.garageProfile, isNull);
    });

    test('garageProfile defaults are safe on partial payloads', () {
      final profile = GarageProfile.fromJson({
        'garageName': 'Solo Garage',
        'isAvailable': false,
      });
      expect(profile.garageAddress, '');
      expect(profile.latitude, isNull);
      expect(profile.locationLabel, 'Location not set');
      expect(profile.isAvailable, isFalse);
      expect(profile.serviceRadiusKm, 15);
    });
  });

  group('ServiceRequest garage-list parsing', () {
    test('parses customer info, billing and garage fields', () {
      final request = ServiceRequest.fromJson({
        '_id': 'r1',
        'packageType': 'basic',
        'bikeModel': 'Honda SP 125',
        'preferredDate': '2026-08-25',
        'preferredTime': '10:30',
        'pickupAddress': '12 MG Road',
        'pickupLocation': {
          'latitude': 12.97,
          'longitude': 77.59,
          'accuracyMeters': 8,
          'capturedAt': '2026-08-19T05:00:00.000Z',
        },
        'contactNumber': '9876543210',
        'priority': 'emergency',
        'breakdownIssue': 'Bike won\'t start',
        'notes': 'Please check',
        'garageNote': '',
        'assignedGarage': 'gg1',
        'assignedGarageDistanceKm': 3.4,
        'status': 'requested',
        'createdAt': '2026-08-19T05:00:00.000Z',
        'user': {
          '_id': 'u1',
          'name': 'Aarav',
          'email': 'aarav@x.in',
          'avatar': '',
          'contactNumber': '9876543210',
          'deliveryAddress': '12 MG Road',
        },
        'billing': {
          'laborCharge': 300,
          'items': [
            {'name': 'Engine Oil', 'quantity': 1, 'unitPrice': 350, 'total': 350},
          ],
          'subtotal': 650,
          'tax': 52,
          'discount': 0,
          'total': 702,
          'status': 'issued',
          'notes': '',
          'paymentMethod': '',
          'paymentReference': '',
          'issuedAt': '2026-08-19T06:00:00.000Z',
          'paidAt': null,
        },
      });

      expect(request.customerName, 'Aarav');
      expect(request.customerEmail, 'aarav@x.in');
      expect(request.customerContact, '9876543210');
      expect(request.isEmergency, isTrue);
      expect(request.billing.isIssued, isTrue);
      expect(request.billing.laborCharge, 300);
      expect(request.billing.items, hasLength(1));
      expect(request.billing.items.first.name, 'Engine Oil');
      expect(request.billing.total, 702);
      expect(request.billing.subtotal, 650);
    });

    test('empty billing parses as unbilled', () {
      final request = ServiceRequest.fromJson({
        '_id': 'r2',
        'packageType': 'full',
        'bikeModel': 'Yamaha R15',
        'preferredDate': '2026-08-26',
        'preferredTime': '11:00',
        'pickupAddress': 'Road',
        'pickupLocation': {'latitude': 12.0, 'longitude': 77.0},
        'contactNumber': '1234567890',
      });
      expect(request.billing.status, 'unbilled');
      expect(request.billing.total, 0);
      expect(request.billing.isIssued, isFalse);
    });
  });

  group('Billing arithmetic (backend formula)', () {
    test('computes parts, subtotal, tax and total', () {
      final totals = computeBillingTotals(
        laborCharge: 300,
        tax: 52,
        discount: 0,
        items: const [
          BillingLineDraft(name: 'Engine Oil', quantity: 1, unitPrice: 350),
        ],
      );
      expect(totals.partsTotal, 350);
      expect(totals.subtotal, 650);
      expect(totals.totalBeforeDiscount, 702);
      expect(totals.total, 702);
    });

    test('applies quantity multiples and discount', () {
      final totals = computeBillingTotals(
        laborCharge: 100,
        tax: 10,
        discount: 20,
        items: const [
          BillingLineDraft(name: 'Filter', quantity: 2, unitPrice: 25),
        ],
      );
      expect(totals.partsTotal, 50);
      expect(totals.subtotal, 150);
      expect(totals.total, 140);
    });

    test('coerces negative and junk inputs to zero', () {
      final totals = computeBillingTotals(
        laborCharge: -5,
        tax: 10,
        discount: 999,
        items: const [
          BillingLineDraft(name: 'x', quantity: -2, unitPrice: 0),
        ],
      );
      expect(totals.subtotal, 0);
      expect(totals.total, 0);
    });
  });
}