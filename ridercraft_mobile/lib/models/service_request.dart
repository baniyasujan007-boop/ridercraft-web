import 'service_billing.dart';

/// Service booking created against `POST /service-requests`.
///
/// The backend exposes three fixed packages: `basic`, `full` and `premium`.
///
/// This model parses both the customer view (`GET /service-requests/my`,
/// which populates `assignedGarage`) and the garage view
/// (`GET /service-requests/garage`, which populates the customer `user` and
/// the `billing` block).
class ServiceRequest {
  final String id;
  final String packageType;
  final String bikeModel;
  final String preferredDate;
  final String preferredTime;
  final String pickupAddress;
  final double pickupLatitude;
  final double pickupLongitude;
  final double? pickupAccuracyMeters;
  final DateTime? pickupCapturedAt;
  final String contactNumber;
  final String priority;
  final String breakdownIssue;
  final String notes;
  final String adminNote;
  final String garageNote;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String customerContact;
  final String customerAvatar;
  final String assignedGarageId;
  final String assignedGarageName;
  final String assignedGarageContact;
  final String assignedGarageEmail;
  final double? assignedGarageDistanceKm;
  final ServiceBilling billing;
  final String status;
  final DateTime? createdAt;

  const ServiceRequest({
    required this.id,
    required this.packageType,
    required this.bikeModel,
    required this.preferredDate,
    required this.preferredTime,
    this.pickupAddress = '',
    this.pickupLatitude = 0,
    this.pickupLongitude = 0,
    this.pickupAccuracyMeters,
    this.pickupCapturedAt,
    this.contactNumber = '',
    this.priority = 'normal',
    this.breakdownIssue = '',
    this.notes = '',
    this.adminNote = '',
    this.garageNote = '',
    this.customerId = '',
    this.customerName = '',
    this.customerEmail = '',
    this.customerContact = '',
    this.customerAvatar = '',
    this.assignedGarageId = '',
    this.assignedGarageName = '',
    this.assignedGarageContact = '',
    this.assignedGarageEmail = '',
    this.assignedGarageDistanceKm,
    this.billing = const ServiceBilling(),
    this.status = 'requested',
    this.createdAt,
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    final pickupLocation = json['pickupLocation'] as Map<String, dynamic>? ?? {};
    final assignedGarage = json['assignedGarage'];
    final garage = assignedGarage is Map<String, dynamic>
        ? assignedGarage
        : <String, dynamic>{};
    final garageName = (garage['name'] ?? '').toString().trim();
    final garageProfileName =
        (garage['garageProfile']?['garageName'] ?? '').toString().trim();

    final rawCustomer = json['user'];
    final customer = rawCustomer is Map<String, dynamic>
        ? rawCustomer
        : <String, dynamic>{};

    return ServiceRequest(
      id: (json['_id'] ?? json['id'] ?? '') as String,
      packageType: (json['packageType'] ?? 'basic') as String,
      bikeModel: (json['bikeModel'] ?? '') as String,
      preferredDate: (json['preferredDate'] ?? '') as String,
      preferredTime: (json['preferredTime'] ?? '') as String,
      pickupAddress: (json['pickupAddress'] ?? '') as String,
      pickupLatitude: ((pickupLocation['latitude'] ?? 0) as num).toDouble(),
      pickupLongitude: ((pickupLocation['longitude'] ?? 0) as num).toDouble(),
      pickupAccuracyMeters: (pickupLocation['accuracyMeters'] as num?)?.toDouble(),
      pickupCapturedAt: pickupLocation['capturedAt'] != null
          ? DateTime.tryParse(pickupLocation['capturedAt'] as String)
          : null,
      contactNumber: (json['contactNumber'] ?? '') as String,
      priority: (json['priority'] ?? 'normal') as String,
      breakdownIssue: (json['breakdownIssue'] ?? '') as String,
      notes: (json['notes'] ?? '') as String,
      adminNote: (json['adminNote'] ?? '') as String,
      garageNote: (json['garageNote'] ?? '') as String,
      customerId: (customer['_id'] ?? customer['id'] ?? '') as String,
      customerName: ((customer['name'] ?? '') as String?) ?? '',
      customerEmail: (customer['email'] ?? '') as String,
      customerContact: (customer['contactNumber'] ?? '') as String,
      customerAvatar: (customer['avatar'] ?? '') as String,
      assignedGarageId: (garage['_id'] ?? garage['id'] ?? '') as String,
      assignedGarageName: garageName.isNotEmpty ? garageName : garageProfileName,
      assignedGarageContact: (garage['contactNumber'] ?? '') as String,
      assignedGarageEmail: (garage['email'] ?? '') as String,
      assignedGarageDistanceKm:
          (json['assignedGarageDistanceKm'] as num?)?.toDouble(),
      billing: ServiceBilling.fromJson(
        json['billing'] is Map<String, dynamic>
            ? json['billing'] as Map<String, dynamic>
            : null,
      ),
      status: (json['status'] ?? 'requested') as String,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  ServiceRequest copyWith({String? status, String? garageNote}) {
    return ServiceRequest(
      id: id,
      packageType: packageType,
      bikeModel: bikeModel,
      preferredDate: preferredDate,
      preferredTime: preferredTime,
      pickupAddress: pickupAddress,
      pickupLatitude: pickupLatitude,
      pickupLongitude: pickupLongitude,
      pickupAccuracyMeters: pickupAccuracyMeters,
      pickupCapturedAt: pickupCapturedAt,
      contactNumber: contactNumber,
      priority: priority,
      breakdownIssue: breakdownIssue,
      notes: notes,
      adminNote: adminNote,
      garageNote: garageNote ?? this.garageNote,
      customerId: customerId,
      customerName: customerName,
      customerEmail: customerEmail,
      customerContact: customerContact,
      customerAvatar: customerAvatar,
      assignedGarageId: assignedGarageId,
      assignedGarageName: assignedGarageName,
      assignedGarageContact: assignedGarageContact,
      assignedGarageEmail: assignedGarageEmail,
      assignedGarageDistanceKm: assignedGarageDistanceKm,
      billing: billing,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  /// Backend service statuses: requested, confirmed, in_progress,
  /// completed, cancelled.
  String get statusLabel => switch (status) {
        'confirmed' => 'Confirmed',
        'in_progress' => 'In Progress',
        'completed' => 'Completed',
        'cancelled' => 'Cancelled',
        _ => 'Requested',
      };

  String get packageLabel => switch (packageType) {
        'full' => 'Full Service',
        'premium' => 'Premium Service',
        _ => 'Basic Service',
      };

  String get priorityLabel => priority == 'emergency' ? 'Emergency' : 'Normal';

  bool get isEmergency => priority == 'emergency';
}