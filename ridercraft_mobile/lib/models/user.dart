/// Matches the user document returned by `GET /auth/profile` and the
/// serialized user fields used across the API.
class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String avatar;
  final String contactNumber;
  final String deliveryAddress;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'user',
    this.avatar = '',
    this.contactNumber = '',
    this.deliveryAddress = '',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final id = (json['_id'] ?? json['id'] ?? '') as String;
    return User(
      id: id,
      name: (json['name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      role: (json['role'] ?? 'user') as String,
      avatar: (json['avatar'] ?? '') as String,
      contactNumber: (json['contactNumber'] ?? '') as String,
      deliveryAddress: (json['deliveryAddress'] ?? '') as String,
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
    );
  }
}
