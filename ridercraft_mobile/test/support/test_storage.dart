import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridercraft_mobile/services/storage_service.dart';

/// Test double for [StorageService] whose token read/write/delete ONLY uses
/// shared preferences.
///
/// [StorageService.readToken] falls back to `FlutterSecureStorage` on
/// non-web platforms, and that platform channel never completes inside a
/// `testWidgets` fake-async zone, so widget tests deadlock. Tests that need to
/// resolve a session (e.g. `AuthProvider.restoreSession`) must build the
/// `AuthService` with this storage so the token round-trips through the mocked
/// `SharedPreferences` instead.
class TestStorageService extends StorageService {
  TestStorageService(super.prefs);

  static const String _tokenKey = 'ridercraft_auth_token';

  @override
  Future<String?> readToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  @override
  Future<void> writeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  @override
  Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}