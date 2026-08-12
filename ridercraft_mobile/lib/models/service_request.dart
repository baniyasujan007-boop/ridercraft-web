/// Service booking created against `POST /service-requests`.
///
/// The backend exposes three fixed packages: `basic`, `full` and `premium`.
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
  final String assignedGarageId;
  final String assignedGarageName;
  final double? assignedGarageDistanceKm;
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
    this.assignedGarageId = '',
    this.assignedGarageName = '',
    this.assignedGarageDistanceKm,
    this.status = 'requested',
    this.createdAt,
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    final pickupLocation = json['pickupLocation'] as Map<String, dynamic>? ?? {};
    final assignedGarage = json['assignedGarage'];
    final garage = assignedGarage is Map<String, dynamic>
        ? assignedGarage
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
      assignedGarageId: (garage['_id'] ?? '') as String,
      assignedGarageName: (garage['name'] ??
              garage['garageProfile']?['garageName'] ??
              '') as String,
      assignedGarageDistanceKm:
          (json['assignedGarageDistanceKm'] as num?)?.toDouble(),
      status: (json['status'] ?? 'requested') as String,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
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
}
