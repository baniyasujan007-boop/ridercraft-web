import 'package:flutter/foundation.dart';

import '../models/service_request.dart';
import '../services/booking_service.dart';

/// Service booking state: the user's bookings and booking creation.
class BookingProvider extends ChangeNotifier {
  final BookingService _service;

  List<ServiceRequest> _bookings = [];
  bool _loading = false;
  bool _submitting = false;
  String? _error;

  BookingProvider(this._service);

  List<ServiceRequest> get bookings => List.unmodifiable(_bookings);
  bool get loading => _loading;
  bool get submitting => _submitting;
  String? get error => _error;

  Future<void> loadBookings() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _bookings = await _service.listMyBookings();
    } catch (error) {
      _error = error.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<ServiceRequest> createBooking({
    required String packageType,
    required String bikeModel,
    required String preferredDate,
    required String preferredTime,
    required String pickupAddress,
    required Map<String, dynamic> pickupLocation,
    required String contactNumber,
    String priority = 'normal',
    String breakdownIssue = '',
    String notes = '',
  }) async {
    _submitting = true;
    _error = null;
    notifyListeners();
    try {
      final booking = await _service.createBooking(
        packageType: packageType,
        bikeModel: bikeModel,
        preferredDate: preferredDate,
        preferredTime: preferredTime,
        pickupAddress: pickupAddress,
        pickupLocation: pickupLocation,
        contactNumber: contactNumber,
        priority: priority,
        breakdownIssue: breakdownIssue,
        notes: notes,
      );
      _bookings.insert(0, booking);
      return booking;
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }
}
