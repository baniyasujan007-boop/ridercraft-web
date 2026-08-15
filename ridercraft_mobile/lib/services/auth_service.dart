import '../models/user.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'storage_service.dart';

/// Authentication against the existing RiderCraft backend.
///
/// Endpoints (all under `/auth`):
/// - POST /auth/register   {name, email, password}
/// - POST /auth/login      {email, password} -> {token, role}
/// - POST /auth/forgot-password {email}
/// - POST /auth/reset-password  {email, token, newPassword}
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

  /// Requests a password-reset link for the given email. The backend sends a
  /// reset token by email; it is never returned to the client.
  Future<void> forgotPassword({
    required String email,
  }) async {
    await _api.post(
      '/auth/forgot-password',
      data: {'email': email.trim().toLowerCase()},
    );
  }

  /// Exchanges a Google ID token (the `credential` from Google Sign-In) for a
  /// RiderCraft JWT. The backend verifies the token's audience before issuing
  /// a session token, exactly like the website.
  Future<void> googleLogin({required String idToken}) async {
    if (idToken.trim().isEmpty) {
      throw const ApiException(
        message: 'Google sign-in returned no ID token. Please try again.',
      );
    }
    final data = await _api.post(
      '/auth/google',
      data: {'credential': idToken},
    );
    final token = (data['token'] as String?) ?? '';
    if (token.isEmpty) {
      throw const ApiException(
        message: 'Google sign-in failed. Please try again.',
      );
    }
    await _storage.writeToken(token);
  }

  /// Completes a password reset using the token delivered by email.
  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    await _api.post(
      '/auth/reset-password',
      data: {
        'email': email.trim().toLowerCase(),
        'token': token,
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
