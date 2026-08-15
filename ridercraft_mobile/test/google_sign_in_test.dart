// End-to-end Google Sign-In coverage for the mobile app:
// - the browser-style { credential } payload the backend contract expects,
// - successful exchange -> RiderCraft JWT stored + profile restored,
// - cancellation / missing-token / backend-rejection behaviour,
// - regression checks that the existing email/password flows still work.
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridercraft_mobile/providers/auth_provider.dart';
import 'package:ridercraft_mobile/screens/auth/login_screen.dart';
import 'package:ridercraft_mobile/services/api_client.dart';
import 'package:ridercraft_mobile/services/api_exception.dart';
import 'package:ridercraft_mobile/services/auth_service.dart';
import 'package:ridercraft_mobile/services/google_sign_in.dart';
import 'package:ridercraft_mobile/services/token_store.dart';

import 'support/test_storage.dart';

Map<String, dynamic> _user() => {
      '_id': 'google-u1',
      'name': 'Chandan Chhetry',
      'email': 'chandan@ridercraft.app',
      'role': 'user',
      'avatar': '',
      'contactNumber': '',
      'deliveryAddress': '',
    };

/// Overrides just the Google SDK call; nothing else touches the plugin.
class _FakeGoogleSignIn extends GoogleSignInService {
  _FakeGoogleSignIn({this.idToken})
      : super(serverClientId: 'client.test.apps.googleusercontent.com');

  String? idToken;
  bool configured = true;

  @override
  bool get isConfigured => configured;

  @override
  Future<String?> getIdToken() async => idToken;
}

/// In-memory backend reproducing the server's /auth contract:
///   POST /auth/google { credential } -> { token, role }
///   POST /auth/login   { email, password } -> { token, role }
///   POST /auth/register { name, email, password } -> { token, user }
///   GET  /auth/profile  (Bearer) -> user document
class _AuthAdapter implements HttpClientAdapter {
  final List<({String method, String path, Object? data})> requests = [];

  int? failGoogleWith;
  bool tokenlessGoogle = false;

  _AuthAdapter();

  ResponseBody _json(String body, int status) => ResponseBody.fromString(
        body,
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add((
      method: options.method,
      path: options.path,
      data: options.data,
    ));
    final path = options.path;

    if (path == '/auth/google' && options.method == 'POST') {
      if (failGoogleWith != null) {
        return _json(jsonEncode({'error': 'Invalid ID token.'}), failGoogleWith!);
      }
      final body = Map<String, dynamic>.from(options.data as Map);
      return _json(
        jsonEncode({
          if (!tokenlessGoogle)
            'token': 'ridercraft-jwt-from-google',
          'role': 'user',
          'credentialEcho': body['credential'],
        }),
        200,
      );
    }
    if (path == '/auth/login' && options.method == 'POST') {
      final body = Map<String, dynamic>.from(options.data as Map);
      if (body['password'] != 'correct') {
        return _json(jsonEncode({'error': 'Invalid credentials'}), 401);
      }
      return _json(
        jsonEncode({'token': 'ridercraft-jwt-email', 'role': 'user'}),
        200,
      );
    }
    if (path == '/auth/register' && options.method == 'POST') {
      return _json(
        jsonEncode({
          'token': 'ridercraft-jwt-register',
          'role': 'user',
          'user': _user(),
        }),
        201,
      );
    }
    if (path == '/auth/profile' && options.method == 'GET') {
      return _json(jsonEncode(_user()), 200);
    }
    return _json('[]', 404);
  }

  @override
  void close({bool force = false}) {}
}

Future<({AuthProvider auth, _AuthAdapter adapter, TokenStore tokenStore})>
    _build({
  String? googleIdToken,
  int? failGoogleWith,
  bool tokenlessGoogle = false,
  GoogleSignInService? googleSignIn,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final storage = TestStorageService(prefs);
  final tokenStore = TokenStore();

  final adapter = _AuthAdapter()
    ..failGoogleWith = failGoogleWith
    ..tokenlessGoogle = tokenlessGoogle;
  final dio = Dio()..httpClientAdapter = adapter;
  final api = ApiClient(tokenProvider: () => tokenStore.current, dio: dio);
  final authService = AuthService(api, storage);

  final provider = AuthProvider(
    authService,
    tokenStore,
    googleSignIn: googleSignIn ?? _FakeGoogleSignIn(idToken: googleIdToken),
  );
  return (auth: provider, adapter: adapter, tokenStore: tokenStore);
}

void main() {
  group('AuthService.googleLogin maps the Google ID token to the backend', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('POSTs { credential } exactly as the website does and stores the JWT',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = TestStorageService(prefs);
      final adapter = _AuthAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final service = AuthService(
        ApiClient(tokenProvider: () => null, dio: dio),
        storage,
      );

      await service.googleLogin(idToken: 'google-uuid-token');

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/auth/google');
      expect((request.data as Map)['credential'], 'google-uuid-token');
      expect(await storage.readToken(), 'ridercraft-jwt-from-google');
    });

    test('rejects an empty ID token before hitting the network', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = TestStorageService(prefs);
      final adapter = _AuthAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final service = AuthService(
        ApiClient(tokenProvider: () => null, dio: dio),
        storage,
      );

      await expectLater(
        service.googleLogin(idToken: '   '),
        throwsA(isA<ApiException>()),
      );
      expect(adapter.requests, isEmpty);
      expect(await storage.readToken(), isNull);
    });

    test('an empty token response surfaces a clean ApiException', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = TestStorageService(prefs);
      final adapter = _AuthAdapter()..tokenlessGoogle = true;
      final dio = Dio()..httpClientAdapter = adapter;
      final service = AuthService(
        ApiClient(tokenProvider: () => null, dio: dio),
        storage,
      );

      await expectLater(
        service.googleLogin(idToken: 'tok'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('AuthProvider.loginWithGoogle', () {
    test('stores the JWT and restores the profile on success', () async {
      final bundle = await _build(googleIdToken: 'google.id.token');
      final result = await bundle.auth.loginWithGoogle();

      expect(result, isTrue);
      expect(bundle.auth.isAuthenticated, isTrue);
      expect(bundle.tokenStore.current, 'ridercraft-jwt-from-google');
      expect(bundle.auth.user, isNotNull);
      expect(bundle.auth.user!.name, 'Chandan Chhetry');
      expect(bundle.adapter.requests.first.path, '/auth/google');
      expect(
        bundle.adapter.requests.any((r) => r.path == '/auth/profile'),
        isTrue,
      );
    });

    test('a cancelled picker (null ID token) does not log in', () async {
      final bundle = await _build(googleIdToken: null);

      final result = await bundle.auth.loginWithGoogle();

      expect(result, isFalse);
      expect(bundle.auth.isAuthenticated, isFalse);
      expect(bundle.auth.user, isNull);
      expect(bundle.tokenStore.current, isNull);
      // Nothing reached the backend when the user cancelled.
      expect(
        bundle.adapter.requests.where((r) => r.path == '/auth/google'),
        isEmpty,
      );
    });

    test('a backend rejection surfaces as an ApiException and logs nobody in',
        () async {
      final bundle = await _build(googleIdToken: 'tok', failGoogleWith: 401);

      await expectLater(
        bundle.auth.loginWithGoogle(),
        throwsA(isA<ApiException>()),
      );
      expect(bundle.auth.isAuthenticated, isFalse);
      expect(bundle.auth.user, isNull);
      expect(bundle.tokenStore.current, isNull);
    });

    test('a missing configuration reports a friendly error', () async {
      final fake = _FakeGoogleSignIn(idToken: 'tok')..configured = false;
      final bundle = await _build(googleSignIn: fake);

      await expectLater(
        bundle.auth.loginWithGoogle(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('not configured'),
          ),
        ),
      );
    });
  });

  group('existing email/password flows still work', () {
    test('email login still authenticates and restores the profile', () async {
      final bundle = await _build();
      await bundle.auth.login(
        email: 'chandan@ridercraft.app',
        password: 'correct',
      );

      expect(bundle.auth.isAuthenticated, isTrue);
      expect(bundle.tokenStore.current, 'ridercraft-jwt-email');
      expect(bundle.auth.user!.email, 'chandan@ridercraft.app');
    });

    test('email login still rejects bad credentials', () async {
      final bundle = await _build();
      await expectLater(
        bundle.auth.login(email: 'chandan@ridercraft.app', password: 'wrong'),
        throwsA(isA<ApiException>()),
      );
      expect(bundle.auth.isAuthenticated, isFalse);
    });

    test('registration still reaches the backend with the normal payload',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = TestStorageService(prefs);
      final adapter = _AuthAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final service = AuthService(
        ApiClient(tokenProvider: () => null, dio: dio),
        storage,
      );

      await service.register(
        name: '  Chandan  ',
        email: ' CHANDAN@ridercraft.app ',
        password: 'password1',
      );

      final request = adapter.requests.single;
      expect(request.path, '/auth/register');
      expect(
        (request.data as Map),
        {
          'name': 'Chandan',
          'email': 'chandan@ridercraft.app',
          'password': 'password1',
        },
      );
    });
  });

  testWidgets('login screen shows the Google sign-in button', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = TestStorageService(prefs);
    final tokenStore = TokenStore();
    final dio = Dio()..httpClientAdapter = _AuthAdapter();
    final auth = AuthProvider(
      AuthService(
        ApiClient(tokenProvider: () => tokenStore.current, dio: dio),
        storage,
      ),
      tokenStore,
      googleSignIn: _FakeGoogleSignIn(idToken: 'tok'),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: ChangeNotifierProvider.value(
          value: auth,
          child: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('OR'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('login screen with Google button fits small screens', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(320, 568);
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = TestStorageService(prefs);
    final tokenStore = TokenStore();
    final dio = Dio()..httpClientAdapter = _AuthAdapter();
    final auth = AuthProvider(
      AuthService(
        ApiClient(tokenProvider: () => tokenStore.current, dio: dio),
        storage,
      ),
      tokenStore,
      googleSignIn: _FakeGoogleSignIn(idToken: 'tok'),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: ChangeNotifierProvider.value(
          value: auth,
          child: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull,
        reason: 'login screen must not overflow with the Google button at 320px/2.0x');
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
