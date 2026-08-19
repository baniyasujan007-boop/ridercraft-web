import '../models/service_request.dart';
import 'api_client.dart';

/// Garage-partner endpoints against the existing backend. Every call is made
/// with the authenticated garage token via the shared [ApiClient], so token
/// handling stays centralized (the client attaches `Authorization: Bearer`).
///
/// Endpoints:
/// - GET  /service-requests/garage              -> assigned bookings
/// - PUT  /service-requests/:id/garage-response {status, garageNote}
/// - PUT  /service-requests/:id/billing         {laborCharge, tax, discount,
///                                                notes, items[]}
/// - PUT  /service-requests/:id/billing/payment {billingStatus, paymentMethod,
///                                                paymentReference}
class GarageService {
  final ApiClient _api;

  GarageService(this._api);

  /// All bookings assigned to this garage role account.
  Future<List<ServiceRequest>> listGarageBookings() async {
    final data = await _api.get('/service-requests/garage');
    if (data is! List) return <ServiceRequest>[];
    return data
        .map((item) => ServiceRequest.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Updates the booking status and optional note through the garage-response
  /// endpoint. Statuses: requested, confirmed, in_progress, completed,
  /// cancelled.
  Future<void> respondToBooking({
    required String id,
    required String status,
    String garageNote = '',
  }) async {
    await _api.put(
      '/service-requests/$id/garage-response',
      data: {'status': status, 'garageNote': garageNote.trim()},
    );
  }

  /// Creates/replaces the service bill. [items] are serialized as
  /// {name, quantity, unitPrice}. The backend recomputes and stores the
  /// authoritative totals.
  Future<void> saveBilling({
    required String id,
    required num laborCharge,
    required num tax,
    required num discount,
    required List<Map<String, dynamic>> items,
    String notes = '',
  }) async {
    await _api.put(
      '/service-requests/$id/billing',
      data: {
        'laborCharge': laborCharge,
        'tax': tax,
        'discount': discount,
        'notes': notes.trim(),
        'items': items,
      },
    );
  }

  /// Updates the bill payment state. [billingStatus] is one of
  /// issued/paid/cancelled; [paymentMethod] is one of
  /// cash/card/upi/ewallet/bank_transfer/other.
  Future<void> updatePayment({
    required String id,
    required String billingStatus,
    required String paymentMethod,
    String paymentReference = '',
  }) async {
    await _api.put(
      '/service-requests/$id/billing/payment',
      data: {
        'billingStatus': billingStatus,
        'paymentMethod': paymentMethod,
        'paymentReference': paymentReference.trim(),
      },
    );
  }
}