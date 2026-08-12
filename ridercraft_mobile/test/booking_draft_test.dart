import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ridercraft_mobile/models/booking_draft.dart';

BookingDraft _draft({
  DateTime? date,
  TimeOfDay? time,
  String priority = 'normal',
}) {
  return BookingDraft(
    packageType: 'full',
    packageLabel: 'Full Service',
    bikeModel: 'Yamaha R15 V4',
    preferredDate: date,
    preferredTime: time,
    pickupAddress: '12 Bike Lane, Pune',
    latitude: 18.5204,
    longitude: 73.8567,
    accuracyMeters: 12.5,
    capturedAt: DateTime(2026, 8, 11, 9, 30),
    contactNumber: '9876543210',
    priority: priority,
  );
}

void main() {
  test('preferredDate is formatted as YYYY-MM-DD', () {
    final draft = _draft(date: DateTime(2026, 8, 15));
    expect(draft.dateValue, '2026-08-15');
  });

  test('preferredDate pads single-digit month and day', () {
    final draft = _draft(date: DateTime(2026, 3, 5));
    expect(draft.dateValue, '2026-03-05');
  });

  test('preferredDate is null when no date selected', () {
    expect(_draft().dateValue, isNull);
  });

  test('preferredTime is formatted as HH:MM', () {
    final draft = _draft(time: const TimeOfDay(hour: 10, minute: 30));
    expect(draft.timeValue, '10:30');
  });

  test('preferredTime pads hour and minute', () {
    final draft = _draft(time: const TimeOfDay(hour: 9, minute: 5));
    expect(draft.timeValue, '09:05');
  });

  test('isEmergency reflects the priority field', () {
    expect(_draft(priority: 'normal').isEmergency, isFalse);
    expect(_draft(priority: 'emergency').isEmergency, isTrue);
  });

  test('toPickupLocation includes required and optional location fields', () {
    final location = _draft(
      date: DateTime(2026, 8, 15),
      time: const TimeOfDay(hour: 10, minute: 0),
    ).toPickupLocation();
    expect(location['latitude'], 18.5204);
    expect(location['longitude'], 73.8567);
    expect(location['accuracyMeters'], 12.5);
    expect(location['capturedAt'], isA<String>());
  });
}
