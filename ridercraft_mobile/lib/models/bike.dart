/// A rider's motorcycle, stored locally on the device.
///
/// The backend has no Bike model/CRUD endpoints, so bikes live in local
/// storage. The selected bike's model string is sent as `bikeModel` when
/// creating a service booking against the real API.
class Bike {
  final String id;
  final String brand;
  final String model;
  final String registrationNumber;
  final String year;
  final String engineCapacity;
  final String image;

  const Bike({
    required this.id,
    required this.brand,
    required this.model,
    this.registrationNumber = '',
    this.year = '',
    this.engineCapacity = '',
    this.image = '',
  });

  factory Bike.fromJson(Map<String, dynamic> json) => Bike(
        id: (json['id'] ?? '') as String,
        brand: (json['brand'] ?? '') as String,
        model: (json['model'] ?? '') as String,
        registrationNumber: (json['registrationNumber'] ?? '') as String,
        year: (json['year'] ?? '') as String,
        engineCapacity: (json['engineCapacity'] ?? '') as String,
        image: (json['image'] ?? '') as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'brand': brand,
        'model': model,
        'registrationNumber': registrationNumber,
        'year': year,
        'engineCapacity': engineCapacity,
        'image': image,
      };

  /// A short label like "Honda SP 125".
  String get displayName {
    final parts = [brand, model].where((e) => e.trim().isNotEmpty).join(' ');
    return parts.isEmpty ? 'My Bike' : parts;
  }

  /// "2019 • 125cc • AB-1234"
  String get subtitle => [
        if (year.isNotEmpty) year,
        if (engineCapacity.isNotEmpty) '$engineCapacity cc',
        if (registrationNumber.isNotEmpty) registrationNumber,
      ].join(' • ');
}
