/// App-wide configuration.
///
/// The RiderCraft Flutter app talks to the existing Express REST API.
/// The production backend is the deployed Render API. To switch to a local
/// development server, run with:
///
///   flutter run --dart-define=ENV=dev --dart-define=API_BASE_URL=http://10.0.2.2:5001
///
/// - Android emulator hits the host machine via http://10.0.2.2:5001
/// - A physical device uses your machine's LAN IP, e.g. http://192.168.1.10:5001
/// - The server's default port is 5001 (see server/server.js).
abstract final class AppConfig {
  /// Build environment: `dev` or `prod` (defaults to `prod`).
  static const String env = String.fromEnvironment(
    'ENV',
    defaultValue: 'prod',
  );

  static const String _prodBaseUrl = 'https://ridercraft-api.onrender.com';

  /// Overridable via --dart-define=API_BASE_URL=...
  static const String _devBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5001',
  );

  static const String _prodAssetsUrl =
      'https://ridercraft-api.onrender.com';

  static bool get isDev => env == 'dev';

  /// The Express server mounts routes WITHOUT an `/api` prefix.
  static String get apiBaseUrl => isDev ? _devBaseUrl : _prodBaseUrl;

  /// Serves as a stable prefix for any static/media URLs returned by the API.
  static String get assetsBaseUrl => _prodAssetsUrl;

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// The Web OAuth client ID used as the Google ID-token audience for the
  /// backend (`GOOGLE_CLIENT_ID` on the server / `REACT_APP_GOOGLE_CLIENT_ID`
  /// on the website). Required for Google Sign-In; on Android the plugin mints
  /// the ID token with this value as its audience so the backend can verify it.
  ///
  /// Provide at build time with:
  ///   flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=your-web-oauth-client-id
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  static const String appName = 'RiderCraft';
}
