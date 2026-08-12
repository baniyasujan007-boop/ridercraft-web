import '../models/service_request.dart';
import 'api_client.dart';

/// Service booking endpoints against the existing backend.
///
/// - POST /service-requests (auth) create booking
/// - GET  /service-requests/my (auth) list my bookings
///
/// The backend auto-assigns the nearest available garage based on the pickup
/// location.
class BookingService {
  final ApiClient _api;

  BookingService(this._api);

  Future<List<ServiceRequest>> listMyBookings() async {
    final data = await _api.get('/service-requests/my');
    if (data is! List) return <ServiceRequest>[];
    return data
        .map((item) => ServiceRequest.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Creates a service booking. [pickupLocation] must include a valid
  /// latitude/longitude; the backend rejects bookings without them.
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
    final data = await _api.post(
      '/service-requests',
      data: {
        'packageType': packageType,
        'bikeModel': bikeModel,
        'preferredDate': preferredDate,
        'preferredTime': preferredTime,
        'pickupAddress': pickupAddress,
        'pickupLocation': pickupLocation,
        'contactNumber': contactNumber,
        'priority': priority,
        if (breakdownIssue.isNotEmpty) 'breakdownIssue': breakdownIssue,
        if (notes.isNotEmpty) 'notes': notes,
      },
    );
    final body = data as Map<String, dynamic>;
    final request = body['request'] ?? body;
    return ServiceRequest.fromJson(request as Map<String, dynamic>);
  }
}
