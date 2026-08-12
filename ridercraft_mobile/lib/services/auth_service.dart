import '../models/user.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'storage_service.dart';

/// Authentication against the existing RiderCraft backend.
///
/// Endpoints (all under `/auth`):
/// - POST /auth/register   {name, email, password}
/// - POST /auth/login      {email, password} -> {token, role}
/// - POST /auth/forgot-password {email, newPassword}
/// - GET  /auth/profile    (Bearer token)
/// - PUT  /auth/profile    (Bearer token)
class AuthService {
  final ApiClient _api;
  final StorageService _storage;

  AuthService(this._api, this._storage);

  StorageService get storage => _storage;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final data = await _api.post(
      '/auth/login',
      data: {'email': email.trim().toLowerCase(), 'password': password},
    );
    final token = (data['token'] as String?) ?? '';
    if (token.isEmpty) {
      throw const ApiException(message: 'Login failed. Please try again.');
    }
    await _storage.writeToken(token);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _api.post(
      '/auth/register',
      data: {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );
  }

  /// The backend resets the password directly using `newPassword` for the
  /// given email. No OTP is involved.
  Future<void> forgotPassword({
    required String email,
    required String newPassword,
  }) async {
    await _api.post(
      '/auth/forgot-password',
      data: {
        'email': email.trim().toLowerCase(),
        'newPassword': newPassword,
      },
    );
  }

  Future<User> fetchProfile() async {
    final data = await _api.get('/auth/profile');
    return User.fromJson(data as Map<String, dynamic>);
  }

  Future<User> updateProfile({
    String? name,
    String? avatar,
    String? contactNumber,
    String? deliveryAddress,
  }) async {
    final data = await _api.put(
      '/auth/profile',
      data: {
        'name': ?name,
        'avatar': ?avatar,
        'contactNumber': ?contactNumber,
        'deliveryAddress': ?deliveryAddress,
      },
    );
    final user = (data as Map<String, dynamic>)['user'];
    return User.fromJson((user ?? data) as Map<String, dynamic>);
  }

  /// Removes the locally stored token. Server-side there is no logout
  /// endpoint; dropping the JWT is the standard flow.
  Future<void> logout() => _storage.deleteToken();
}
