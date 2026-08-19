/// Matches the user document returned by `GET /auth/profile` and the
/// serialized user fields used across the API.
///
/// Garage accounts will additionally carry a [garageProfile] from the
/// backend. Authentication semantics are unchanged.
class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String avatar;
  final String contactNumber;
  final String deliveryAddress;
  final GarageProfile? garageProfile;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'user',
    this.avatar = '',
    this.contactNumber = '',
    this.deliveryAddress = '',
    this.garageProfile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final id = (json['_id'] ?? json['id'] ?? '') as String;
    final rawProfile = json['garageProfile'];
    return User(
      id: id,
      name: (json['name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      role: (json['role'] ?? 'user') as String,
      avatar: (json['avatar'] ?? '') as String,
      contactNumber: (json['contactNumber'] ?? '') as String,
      deliveryAddress: (json['deliveryAddress'] ?? '') as String,
      garageProfile: rawProfile is Map<String, dynamic>
          ? GarageProfile.fromJson(rawProfile)
          : null,
    );
  }

  User copyWith({
    String? name,
    String? avatar,
    String? contactNumber,
    String? deliveryAddress,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email,
      role: role,
      avatar: avatar ?? this.avatar,
      contactNumber: contactNumber ?? this.contactNumber,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      garageProfile: garageProfile,
    );
  }

  /// True when the account is a service-provider/business garage account
  /// (`role == "garage"`), as opposed to a customer account. This is a
  /// read-only role check; it never changes authentication behaviour.
  bool get isGarage => role == 'garage';

  bool get isAdmin => role == 'admin';
}

/// The garage business profile returned inside `garageProfile` by
/// `GET /auth/profile`. Rendered read-only (the backend has no garage-profile
/// editing endpoint).
class GarageProfile {
  final String garageName;
  final String garageAddress;
  final double? latitude;
  final double? longitude;
  final double serviceRadiusKm;
  final bool isAvailable;

  const GarageProfile({
    this.garageName = '',
    this.garageAddress = '',
    this.latitude,
    this.longitude,
    this.serviceRadiusKm = 15,
    this.isAvailable = true,
  });

  factory GarageProfile.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>? ?? {};
    return GarageProfile(
      garageName: (json['garageName'] ?? '') as String,
      garageAddress: (json['garageAddress'] ?? '') as String,
      latitude: (location['latitude'] as num?)?.toDouble(),
      longitude: (location['longitude'] as num?)?.toDouble(),
      serviceRadiusKm:
          ((json['serviceRadiusKm'] ?? 15) as num).toDouble(),
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  bool get hasLocation => latitude != null && longitude != null;

  String get locationLabel {
    final lat = latitude;
    final lng = longitude;
    if (lat == null || lng == null) return 'Location not set';
    return '$lat, $lng';
  }
}