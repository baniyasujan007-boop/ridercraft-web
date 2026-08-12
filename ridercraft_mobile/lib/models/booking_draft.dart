import 'package:flutter/material.dart';

/// Form state carried from the booking form to the review screen.
///
/// Fields map 1:1 to what `POST /service-requests` accepts. No prices or
/// coupons are included — the backend does not support them for services.
class BookingDraft {
  final String packageType;
  final String packageLabel;
  final String bikeModel;
  final DateTime? preferredDate;
  final TimeOfDay? preferredTime;
  final String pickupAddress;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
  final DateTime? capturedAt;
  final String contactNumber;
  final String priority;
  final String breakdownIssue;
  final String notes;

  const BookingDraft({
    required this.packageType,
    required this.packageLabel,
    required this.bikeModel,
    required this.preferredDate,
    required this.preferredTime,
    required this.pickupAddress,
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
    this.capturedAt,
    required this.contactNumber,
    this.priority = 'normal',
    this.breakdownIssue = '',
    this.notes = '',
  });

  /// Backend-compatible `preferredDate` value, e.g. `2026-08-15`.
  String? get dateValue {
    final date = preferredDate;
    if (date == null) return null;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  /// Backend-compatible `preferredTime` value, e.g. `10:30`.
  String? get timeValue {
    final time = preferredTime;
    if (time == null) return null;
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool get isEmergency => priority == 'emergency';

  Map<String, dynamic> toPickupLocation() => {
        'latitude': latitude,
        'longitude': longitude,
        if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
        if (capturedAt != null) 'capturedAt': capturedAt!.toIso8601String(),
      };
}
