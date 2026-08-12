import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/token_store.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

/// Session state: restores the token on launch, keeps the profile current and
/// exposes login / register / logout.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final TokenStore _tokenStore;

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  bool _restoring = false;

  AuthProvider(this._authService, this._tokenStore);

  AuthStatus get status => _status;
  User? get user => _user;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isRestoring => _restoring;
  String? get token => _tokenStore.current;

  /// Called on app launch. If a token exists, tries to load the profile so
  /// the session is restored; otherwise goes to the login/home flow.
  Future<void> restoreSession() async {
    _status = AuthStatus.unknown;
    _restoring = true;
    notifyListeners();

    final stored = await _authService.storage.readToken();
    if (stored == null || stored.isEmpty) {
      _tokenStore.current = null;
      _status = AuthStatus.unauthenticated;
      _restoring = false;
      notifyListeners();
      return;
    }

    _tokenStore.current = stored;
    try {
      _user = await _authService.fetchProfile();
      _status = AuthStatus.authenticated;
    } on ApiException catch (error) {
      // Invalid / expired token: drop it silently.
      if (error.isUnauthorized) {
        _tokenStore.current = null;
        await _authService.storage.deleteToken();
        _status = AuthStatus.unauthenticated;
      } else {
        // Network issue: keep the token so we retry, but show login as
        // fallback. The user can log in again; token stays valid.
        _status = AuthStatus.unauthenticated;
      }
    }
    _restoring = false;
    notifyListeners();
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    await _authService.login(email: email, password: password);
    final stored = await _authService.storage.readToken();
    _tokenStore.current = stored;
    _user = await _authService.fetchProfile();
    _status = AuthStatus.authenticated;
    notifyListeners();
    return stored;
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) =>
      _authService.register(
        name: name,
        email: email,
        password: password,
      );

  Future<void> forgotPassword({
    required String email,
    required String newPassword,
  }) =>
      _authService.forgotPassword(
        email: email,
        newPassword: newPassword,
      );

  Future<void> updateProfile({
    String? name,
    String? avatar,
    String? contactNumber,
    String? deliveryAddress,
  }) async {
    _user = await _authService.updateProfile(
      name: name,
      avatar: avatar,
      contactNumber: contactNumber,
      deliveryAddress: deliveryAddress,
    );
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _tokenStore.current = null;
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Fired by the API client when the backend rejects the token mid-session.
  Future<void> handleUnauthorized() async {
    await _authService.logout();
    _tokenStore.current = null;
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
