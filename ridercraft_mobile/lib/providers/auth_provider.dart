import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/google_sign_in.dart';
import '../services/token_store.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

/// Session state: restores the token on launch, keeps the profile current and
/// exposes login (email/password and Google), register / logout.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final TokenStore _tokenStore;
  final GoogleSignInService? _googleSignIn;

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  bool _restoring = false;

  AuthProvider(this._authService, this._tokenStore,
      {GoogleSignInService? googleSignIn})
      : _googleSignIn = googleSignIn;

  AuthStatus get status => _status;
  User? get user => _user;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isRestoring => _restoring;
  String? get token => _tokenStore.current;

  /// True once a `garage`-role profile is loaded. Purely read-only role
  /// detection — it never alters authentication behaviour.
  bool get isGarage => _user?.isGarage ?? false;

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

  /// Completes Google Sign-In: exchanges the Google ID token for a RiderCraft
  /// JWT through the backend (which verifies the token), then restores the
  /// profile like a normal login.
  ///
  /// Returns `true` when the session is established and `false` when the user
  /// dismissed the Google account picker (no session change). Configuration
  /// and backend failures throw an [ApiException].
  Future<bool> loginWithGoogle() async {
    final service = _googleSignIn;
    if (service == null || !service.isConfigured) {
      throw const ApiException(
        message: 'Google sign-in is not configured for this build.',
      );
    }
    final idToken = await service.getIdToken();
    if (idToken == null) {
      // The user cancelled the account-selection flow: do not log in.
      return false;
    }
    await _authService.googleLogin(idToken: idToken);
    final stored = await _authService.storage.readToken();
    _tokenStore.current = stored;
    _user = await _authService.fetchProfile();
    _status = AuthStatus.authenticated;
    notifyListeners();
    return true;
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
  }) =>
      _authService.forgotPassword(
        email: email,
      );

  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) =>
      _authService.resetPassword(
        email: email,
        token: token,
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

  /// Refreshes the profile from `GET /auth/profile` without touching the
  /// session. Errors propagate so callers can surface a retry message.
  Future<User> reloadProfile() async {
    _user = await _authService.fetchProfile();
    notifyListeners();
    return _user!;
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
