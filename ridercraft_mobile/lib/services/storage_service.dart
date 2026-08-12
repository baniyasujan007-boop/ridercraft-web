import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent storage abstraction.
///
/// The JWT token is stored with `flutter_secure_storage` on mobile (Keychain /
/// Keystore). On the web the secure storage backend is limited, so it falls
/// back to `shared_preferences` there. Non-sensitive data (cart, recent
/// searches) uses `shared_preferences`.
class StorageService {
  static const String _tokenKey = 'ridercraft_auth_token';
  static const String _cartKey = 'ridercraft_cart_v1';
  static const String _recentSearchesKey = 'ridercraft_recent_searches_v1';
  static const String _bikesKey = 'ridercraft_my_bikes_v1';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // --- Secure token ---
  Future<String?> readToken() async {
    if (kIsWeb) return _prefs.getString(_tokenKey);
    try {
      return await _secureStorage.read(key: _tokenKey);
    } catch (_) {
      return _prefs.getString(_tokenKey);
    }
  }

  Future<void> writeToken(String token) async {
    if (kIsWeb) {
      await _prefs.setString(_tokenKey, token);
      return;
    }
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
    } catch (_) {
      await _prefs.setString(_tokenKey, token);
    }
  }

  Future<void> deleteToken() async {
    if (kIsWeb) {
      await _prefs.remove(_tokenKey);
      return;
    }
    try {
      await _secureStorage.delete(key: _tokenKey);
    } catch (_) {
      await _prefs.remove(_tokenKey);
    }
  }

  // --- Cart (JSON) ---
  Future<String?> readCart() async => _prefs.getString(_cartKey);
  Future<void> writeCart(String json) => _prefs.setString(_cartKey, json);
  Future<void> clearCart() => _prefs.remove(_cartKey);

  // --- Recent searches ---
  Future<List<String>> readRecentSearches() async {
    final raw = _prefs.getStringList(_recentSearchesKey) ?? const [];
    return raw;
  }

  Future<void> writeRecentSearches(List<String> searches) =>
      _prefs.setStringList(_recentSearchesKey, searches);

  // --- My Bikes (JSON list, local-only) ---
  Future<String?> readBikes() async => _prefs.getString(_bikesKey);
  Future<void> writeBikes(String json) => _prefs.setString(_bikesKey, json);
}
