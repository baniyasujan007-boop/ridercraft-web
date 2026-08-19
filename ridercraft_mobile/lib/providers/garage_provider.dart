import 'package:flutter/foundation.dart';

import '../models/service_request.dart';
import '../services/garage_service.dart';

/// Garage-partner state: the bookings assigned to the garage account, plus
/// the status/billing/payment actions that mutate them. All screens of the
/// GarageScaffold share this one provider so a single load powers the
/// dashboard, the bookings list and the booking detail.
class GarageProvider extends ChangeNotifier {
  final GarageService _service;

  List<ServiceRequest> _bookings = [];
  bool _loading = false;
  bool _refreshing = false;
  String? _error;
  String? _lastMessage;

  bool _responding = false;
  String? _responseError;

  bool _billingSaving = false;
  String? _billingError;

  bool _paymentSaving = false;
  String? _paymentError;

  GarageProvider(this._service);

  List<ServiceRequest> get bookings => List.unmodifiable(_bookings);
  bool get loading => _loading;
  bool get refreshing => _refreshing;
  String? get error => _error;
  String? get lastMessage => _lastMessage;

  bool get responding => _responding;
  String? get responseError => _responseError;

  bool get billingSaving => _billingSaving;
  String? get billingError => _billingError;

  bool get paymentSaving => _paymentSaving;
  String? get paymentError => _paymentError;

  /// Finds a booking by id, or null once it leaves the assigned list.
  ServiceRequest? bookingById(String id) {
    for (final booking in _bookings) {
      if (booking.id == id) return booking;
    }
    return null;
  }

  // --- Derived counts for the dashboard summary ---

  /// Count of bookings that still need attention (requested + confirmed).
  int get pendingCount =>
      _bookings.where((b) => b.status == 'requested' || b.status == 'confirmed').length;

  /// Count of bookings currently being serviced.
  int get activeCount => _bookings.where((b) => b.status == 'in_progress').length;

  /// Count of completed bookings.
  int get completedCount => _bookings.where((b) => b.status == 'completed').length;

  /// Emergency bookings anywhere in the list (dashboard highlights them).
  List<ServiceRequest> get emergencyBookings =>
      _bookings.where((b) => b.isEmergency).toList(growable: false);

  /// Dashboard "recent" list: emergencies first, then newest first (matches
  /// the backend sort).
  List<ServiceRequest> get recentBookings {
    final list = [..._bookings];
    list.sort((a, b) {
      if (a.isEmergency != b.isEmergency) return a.isEmergency ? -1 : 1;
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return list;
  }

  /// Loads (or refreshes) the assigned bookings list.
  Future<void> loadBookings({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) {
      _refreshing = true;
    } else {
      _loading = true;
    }
    _error = null;
    notifyListeners();
    try {
      _bookings = await _service.listGarageBookings();
    } catch (error) {
      _error = error.toString();
    } finally {
      _loading = false;
      _refreshing = false;
      notifyListeners();
    }
  }

  /// Updates booking status + note. Returns true on success so the caller can
  /// confirm the transition. Guards against duplicate submissions.
  Future<bool> respondToBooking({
    required String id,
    required String status,
    String garageNote = '',
    void Function(String message)? onSuccess,
  }) async {
    if (_responding) return false;
    _responding = true;
    _responseError = null;
    notifyListeners();
    try {
      await _service.respondToBooking(id: id, status: status, garageNote: garageNote);
      _lastMessage = 'Booking updated to ${_statusLabel(status)}.';
      onSuccess?.call(_lastMessage!);
      await loadBookings();
      return true;
    } catch (error) {
      _responseError = error.toString();
      return false;
    } finally {
      _responding = false;
      notifyListeners();
    }
  }

  /// Creates/replaces the service bill. Returns true on success.
  Future<bool> saveBilling({
    required String id,
    required num laborCharge,
    required num tax,
    required num discount,
    required List<Map<String, dynamic>> items,
    String notes = '',
    void Function(String message)? onSuccess,
  }) async {
    if (_billingSaving) return false;
    _billingSaving = true;
    _billingError = null;
    notifyListeners();
    try {
      await _service.saveBilling(
        id: id,
        laborCharge: laborCharge,
        tax: tax,
        discount: discount,
        items: items,
        notes: notes,
      );
      _lastMessage = 'Service bill issued.';
      onSuccess?.call(_lastMessage!);
      await loadBookings();
      return true;
    } catch (error) {
      _billingError = error.toString();
      return false;
    } finally {
      _billingSaving = false;
      notifyListeners();
    }
  }

  /// Updates the bill payment state. Returns true on success.
  Future<bool> updateBillingPayment({
    required String id,
    required String billingStatus,
    required String paymentMethod,
    String paymentReference = '',
    void Function(String message)? onSuccess,
  }) async {
    if (_paymentSaving) return false;
    _paymentSaving = true;
    _paymentError = null;
    notifyListeners();
    try {
      await _service.updatePayment(
        id: id,
        billingStatus: billingStatus,
        paymentMethod: paymentMethod,
        paymentReference: paymentReference,
      );
      _lastMessage = billingStatus == 'paid'
          ? 'Payment marked as received.'
          : 'Bill payment cancelled.';
      onSuccess?.call(_lastMessage!);
      await loadBookings();
      return true;
    } catch (error) {
      _paymentError = error.toString();
      return false;
    } finally {
      _paymentSaving = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _lastMessage = null;
    _responseError = null;
    _billingError = null;
    _paymentError = null;
    notifyListeners();
  }

  static String _statusLabel(String status) => switch (status) {
        'confirmed' => 'Confirmed',
        'in_progress' => 'In Progress',
        'completed' => 'Completed',
        'cancelled' => 'Cancelled',
        _ => 'Requested',
      };
}