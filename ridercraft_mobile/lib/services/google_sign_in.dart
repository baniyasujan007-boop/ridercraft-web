import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/app_config.dart';
import 'api_exception.dart';

/// Thin wrapper around the `google_sign_in` plugin (v7 Credential Manager API).
///
/// On Android the plugin requires the app's *Web* OAuth client ID as the
/// `serverClientId`: the returned Google ID token is minted with that client
/// as its audience, which is exactly the audience the backend
/// (`GOOGLE_CLIENT_ID` in `POST /auth/google`) verifies. The Android app
/// identity itself (package + signing SHA-1) is provided out-of-band by the
/// Google Cloud Android OAuth client.
///
/// Cancellation surfaces as `null`; configuration/failure errors surface as a
/// user-friendly [ApiException].
class GoogleSignInService {
  final String _serverClientId;
  final String _clientId;
  bool _initialized = false;

  GoogleSignInService({
    String serverClientId = AppConfig.googleWebClientId,
    String? clientId,
  }) : _serverClientId = serverClientId,
       _clientId = clientId ?? (kIsWeb ? serverClientId : '');

  /// Whether the backend audience (web OAuth client ID) has been provided.
  bool get isConfigured => _serverClientId.trim().isNotEmpty;

  /// Returns a Google ID token for the signed-in account, or null when the
  /// user dismisses the account picker without completing sign-in.
  Future<String?> getIdToken() async {
    if (!isConfigured) {
      throw const ApiException(
        message:
            'Google sign-in is not configured for this build. Provide '
            'GOOGLE_WEB_CLIENT_ID when building the app.',
      );
    }
    final signIn = GoogleSignIn.instance;
    if (!_initialized) {
      await signIn.initialize(
        clientId: _clientId.trim().isEmpty ? null : _clientId.trim(),
        serverClientId: _serverClientId.trim(),
      );
      _initialized = true;
    }
    try {
      final account = await signIn.authenticate();
      debugPrint('google-auth: authenticate returned account=true '
          'idToken=${account.authentication.idToken != null}');
      return account.authentication.idToken;
    } on GoogleSignInException catch (error) {
      // SAFE diagnostic only: code + provider message, never the client ID,
      // JWT or any token. Allows on-device triage of the Google layer.
      debugPrint(
        'google-auth: GoogleSignInException code=${error.code} '
        'description=${error.description} silent=${_isSilent(error.code)}',
      );
      if (_isSilent(error.code)) return null;
      return _asApiException(error);
    }
  }

  /// Sign out of the Google account on this device.
  Future<void> signOut() async {
    if (!_initialized) return;
    await GoogleSignIn.instance.signOut();
  }

  /// Cancellation/interruption and "UI unavailable" are normal outcomes (the
  /// user declined), not errors.
  bool _isSilent(GoogleSignInExceptionCode code) {
    switch (code) {
      case GoogleSignInExceptionCode.canceled:
      case GoogleSignInExceptionCode.interrupted:
      case GoogleSignInExceptionCode.uiUnavailable:
        return true;
      default:
        return false;
    }
  }

  Never _asApiException(GoogleSignInException error) {
    switch (error.code) {
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        throw const ApiException(
          message:
              'Google sign-in is not configured for this build. Verify the '
              'Android package name and signing SHA-1 on the Google Cloud '
              'project.',
        );
      default:
        throw const ApiException(
          message: 'Google sign-in failed. Please try again.',
        );
    }
  }
}