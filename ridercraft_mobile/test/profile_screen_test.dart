import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridercraft_mobile/providers/auth_provider.dart';
import 'package:ridercraft_mobile/routes/app_routes.dart';
import 'package:ridercraft_mobile/screens/profile/profile_screen.dart';
import 'package:ridercraft_mobile/services/api_client.dart';
import 'package:ridercraft_mobile/services/auth_service.dart';
import 'package:ridercraft_mobile/services/avatar_image_picker.dart';
import 'package:ridercraft_mobile/services/token_store.dart';
import 'package:ridercraft_mobile/theme/app_theme.dart';

import 'support/test_storage.dart';

Map<String, dynamic> _user({
  String name = 'Chandan Chhetry',
  String email = 'chandan@ridercraft.app',
  String contact = '+15550000000',
  String address = 'River Rd, Gangtok, Sikkim 737101',
  String avatar = '',
}) {
  return {
    '_id': 'abc123',
    'name': name,
    'email': email,
    'role': 'user',
    'avatar': avatar,
    'contactNumber': contact,
    'deliveryAddress': address,
  };
}

/// A real 1x1 transparent PNG so `Image.memory` can decode it in tests.
const tinyPngDataUri =
    'data:image/png;base64,'
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJ'
    'AAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

/// A bigger +Opaque+ PNG (so JPEG re-encoding keeps visible pixels) that the
/// fake picker hands to the processor exactly like the real photo picker does.
Uint8List get tinyPngBytes =>
    base64Decode(tinyPngDataUri.substring(tinyPngDataUri.indexOf(',') + 1));

/// Replaces the platform photo picker so tests control what the user "picks".
class _FakeAvatarPicker extends AvatarImagePicker {
  Uint8List? galleryBytes;
  Object? pickError;
  bool galleryCalled = false;

  _FakeAvatarPicker();

  @override
  Future<Uint8List?> pickGallery() async {
    galleryCalled = true;
    if (pickError != null) throw pickError!;
    return galleryBytes;
  }
}

/// In-memory backend for the two real profile endpoints:
/// - GET /auth/profile  -> the user document directly
/// - PUT /auth/profile  -> {message, user} and merges the request body
class _ProfileAdapter implements HttpClientAdapter {
  Map<String, dynamic> user;
  int? failPutWith;
  final List<Map<String, dynamic>> putBodies = [];

  _ProfileAdapter(this.user);

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
    if (options.path == '/auth/profile' && options.method == 'GET') {
      return _json(jsonEncode(user), 200);
    }
    if (options.path == '/auth/profile' && options.method == 'PUT') {
      final body = Map<String, dynamic>.from(options.data as Map);
      putBodies.add(body);
      if (failPutWith != null) {
        return _json(jsonEncode({'error': 'Failed to update profile'}), failPutWith!);
      }
      final merged = Map<String, dynamic>.from(user);
      body.forEach((key, value) {
        if (value is String) merged[key] = value;
      });
      user = merged;
      return _json(
        jsonEncode({
          'message': 'Profile updated',
          'user': {
            'name': merged['name'],
            'email': merged['email'],
            'role': merged['role'],
            'avatar': merged['avatar'],
            'contactNumber': merged['contactNumber'] ?? '',
            'deliveryAddress': merged['deliveryAddress'] ?? '',
          },
        }),
        200,
      );
    }
    return _json('[]', 200);
  }

  @override
  void close({bool force = false}) {}
}

/// Builds the app and returns it alongside the session provider so tests can
/// resolve the session in real async (see `_restore`).
Future<({Widget app, AuthProvider auth})> _buildApp({
  required bool authenticated,
  Map<String, dynamic>? user,
  int? failPutWith,
  AvatarImagePicker? avatarPicker,
}) async {
  SharedPreferences.setMockInitialValues(
    authenticated ? {'ridercraft_auth_token': 'test-token'} : {},
  );
  final prefs = await SharedPreferences.getInstance();
  final storage = TestStorageService(prefs);
  final tokenStore = TokenStore();

  final adapter = _ProfileAdapter(user ?? _user());
  adapter.failPutWith = failPutWith;
  final dio = Dio()..httpClientAdapter = adapter;
  final api = ApiClient(tokenProvider: () => tokenStore.current, dio: dio);

  final authProvider = AuthProvider(AuthService(api, storage), tokenStore);

  final app = MultiProvider(
    providers: [ChangeNotifierProvider.value(value: authProvider)],
    child: MaterialApp(
      theme: AppTheme.dark,
      home: ProfileScreen(picker: avatarPicker ?? const AvatarImagePicker()),
      onGenerateRoute: AppRouter.onGenerateRoute,
    ),
  );
  return (app: app, auth: authProvider);
}

/// Like [_buildApp] but keeps the adapter and picker so avatar tests can assert
/// on the outgoing payload and the platform-picker interaction.
Future<({AuthProvider auth, _ProfileAdapter adapter, _FakeAvatarPicker picker})>
    _buildAvatarApp(
  WidgetTester tester, {
  Map<String, dynamic>? user,
  int? failPutWith,
  Uint8List? galleryBytes,
  Object? pickError,
}) async {
  SharedPreferences.setMockInitialValues({'ridercraft_auth_token': 'test-token'});
  final prefs = await SharedPreferences.getInstance();
  final storage = TestStorageService(prefs);
  final tokenStore = TokenStore();

  final adapter = _ProfileAdapter(user ?? _user());
  adapter.failPutWith = failPutWith;
  final dio = Dio()..httpClientAdapter = adapter;
  final api = ApiClient(tokenProvider: () => tokenStore.current, dio: dio);
  final authProvider = AuthProvider(AuthService(api, storage), tokenStore);

  final picker = _FakeAvatarPicker()
    ..galleryBytes = galleryBytes
    ..pickError = pickError;

  final app = MultiProvider(
    providers: [ChangeNotifierProvider.value(value: authProvider)],
    child: MaterialApp(
      theme: AppTheme.dark,
      home: ProfileScreen(picker: picker),
      onGenerateRoute: AppRouter.onGenerateRoute,
    ),
  );

  await _restore(tester, authProvider);
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
  return (auth: authProvider, adapter: adapter, picker: picker);
}

/// Opens the change-photo bottom sheet by tapping the avatar.
Future<void> _openAvatarSheet(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Change profile picture'));
  await tester.pumpAndSettle();
}

/// Picks a photo from the gallery through the bottom sheet.
Future<void> _pickFromGallery(WidgetTester tester) async {
  await _openAvatarSheet(tester);
  await tester.tap(find.text('Choose from Gallery'));
  await tester.pumpAndSettle();
}

/// Resolves the session through real async.
///
/// A bare `await AuthProvider.restoreSession()` never completes inside a
/// `testWidgets` fake-async zone once it performs a Dio request through the
/// fake adapter (only the pump loop flushes those futures). `tester.runAsync`
/// escapes the zone so the request can finish.
Future<void> _restore(WidgetTester tester, AuthProvider auth) async {
  await tester.runAsync(() async {
    // Microtask so runAsync can observe the session resolution.
    await auth.restoreSession();
    await Future<void>.delayed(Duration.zero);
  });
}

/// Builds the app, resolves its session and pumps the Profile screen.
Future<void> _pumpProfile(
  WidgetTester tester, {
  required bool authenticated,
  Map<String, dynamic>? user,
  int? failPutWith,
  AvatarImagePicker? avatarPicker,
}) async {
  final bundle = await _buildApp(
    authenticated: authenticated,
    user: user,
    failPutWith: failPutWith,
    avatarPicker: avatarPicker,
  );
  await _restore(tester, bundle.auth);
  await tester.pumpWidget(bundle.app);
  await tester.pumpAndSettle();
}

void _setViewport(
  WidgetTester tester, {
  required double width,
  required double height,
  required double textScale,
}) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(width, height);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

/// The name field is the first editable TextFormField (email is disabled).
Finder _field(String label) => find.widgetWithText(TextFormField, label);

void main() {
  testWidgets('loading gate shows until the session resolves', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = TestStorageService(prefs);
    final tokenStore = TokenStore();
    final dio = Dio()..httpClientAdapter = _ProfileAdapter(_user());
    final api = ApiClient(tokenProvider: () => tokenStore.current, dio: dio);
    // Deliberately NOT restoring: status stays unknown -> loading spinner.
    final authProvider = AuthProvider(AuthService(api, storage), tokenStore);

    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider.value(value: authProvider)],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const ProfileScreen(),
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      ),
    );

    expect(find.text('Loading profile…'), findsOneWidget);
  });

  testWidgets('guest sees the sign-in prompt', (tester) async {
    await _pumpProfile(tester, authenticated: false);

    expect(
      find.text('Sign in to manage your rider profile.'),
      findsOneWidget,
    );
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Logout'), findsNothing);
  });

  group('profile avatar', () {
    testWidgets('renders a data URI avatar from memory and hides the fallback',
        (tester) async {
      await _pumpProfile(
        tester,
        authenticated: true,
        user: _user(avatar: tinyPngDataUri),
      );

      expect(find.byType(Image), findsWidgets);
      expect(find.byIcon(Icons.sports_motorsports_rounded), findsNothing);
      expect(find.text('CC'), findsNothing);
    });

    testWidgets('uses the initials fallback when there is no avatar', (
      tester,
    ) async {
      await _pumpProfile(tester, authenticated: true, user: _user(avatar: ''));

      expect(find.text('CC'), findsOneWidget);
      expect(find.byIcon(Icons.sports_motorsports_rounded), findsNothing);
    });

    testWidgets('null avatar falls back without crashing', (tester) async {
      final nullAvatarUser = _user()..['avatar'] = null;
      await _pumpProfile(
        tester,
        authenticated: true,
        user: nullAvatarUser,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('CC'), findsOneWidget);
    });

    testWidgets('empty avatar falls back without crashing', (tester) async {
      await _pumpProfile(
        tester,
        authenticated: true,
        user: _user(avatar: ' '),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('CC'), findsOneWidget);
    });

    testWidgets('an undecodable data URI reaches the branded fallback', (
      tester,
    ) async {
      await _pumpProfile(
        tester,
        authenticated: true,
        user: _user(avatar: 'data:image/png;base64,!!not-base64!!'),
      );

      expect(find.byIcon(Icons.sports_motorsports_rounded), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('saving profile settings keeps the avatar', (tester) async {
      await _pumpProfile(
        tester,
        authenticated: true,
        user: _user(avatar: tinyPngDataUri),
      );
      expect(find.byType(Image), findsWidgets);

      await tester.enterText(_field('Full Name'), 'Aarav Sharma');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Profile updated successfully'), findsOneWidget);
      expect(find.byType(Image), findsWidgets);
      expect(find.byIcon(Icons.sports_motorsports_rounded), findsNothing);
    });
  });

  testWidgets('authenticated user sees header, settings and account links', (
    tester,
  ) async {
    await _pumpProfile(tester, authenticated: true);

    expect(find.text('Chandan Chhetry'), findsNWidgets(2)); // header + form
    expect(find.text('chandan@ridercraft.app'), findsNWidgets(2)); // header + form
    expect(find.text('Profile Settings'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
    expect(find.text('My Orders'), findsOneWidget);
    expect(find.text('My Bookings'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('My Bikes'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
  });

  testWidgets('saving updates the profile and shows success', (tester) async {
    await _pumpProfile(tester, authenticated: true);

    await tester.enterText(_field('Full Name'), 'Aarav Sharma');
    await tester.enterText(_field('Contact Number'), '+919811223344');
    await tester.enterText(
      _field('Delivery Address'),
      'MG Marg, Gangtok, Sikkim',
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save Changes'));
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Profile updated successfully'), findsOneWidget);
    // Updated name now appears in both the header and the form field.
    expect(find.text('Aarav Sharma'), findsNWidgets(2));
  });

  testWidgets('saving shows the inline error when the API fails', (
    tester,
  ) async {
    await _pumpProfile(tester, authenticated: true, failPutWith: 500);

    await tester.ensureVisible(find.text('Save Changes'));
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Failed to update profile'), findsOneWidget);
    // The original values are kept after a failed save.
    expect(find.text('Chandan Chhetry'), findsNWidgets(2));
  });

  testWidgets('empty name is rejected before reaching the API', (tester) async {
    await _pumpProfile(tester, authenticated: true);

    await tester.enterText(_field('Full Name'), '   ');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save Changes'));
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Name is required.'), findsOneWidget);
  });

  testWidgets('logout confirms then routes to the login screen', (
    tester,
  ) async {
    await _pumpProfile(tester, authenticated: true);

    await tester.ensureVisible(find.text('Logout'));
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    expect(find.text('Sign out?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('WELCOME BACK'), findsOneWidget);
    expect(find.text('Logout'), findsNothing);
  });

  group('responsive Profile never overflows (authenticated)', () {
    for (final width in [320.0, 360.0, 390.0, 430.0, 768.0, 1024.0]) {
      for (final textScale in [1.0, 1.3, 2.0]) {
        testWidgets(
            'renders at ${width}px width, ${textScale}x text without overflow',
            (tester) async {
          _setViewport(
            tester,
            width: width,
            height: 844,
            textScale: textScale,
          );
          await _pumpProfile(tester, authenticated: true);

          expect(tester.takeException(), isNull,
              reason: 'overflow in the initial Profile viewport');

          // Build the off-screen cards (account links + sign out) too.
          await tester.drag(
            find.byType(SingleChildScrollView),
            const Offset(0, -1200),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: 'overflow after scrolling the Profile content');
        });
      }
    }

    for (final textScale in [1.0, 1.3, 2.0]) {
      testWidgets('renders on a Pixel 7 Pro (412x915) at ${textScale}x text', (
        tester,
      ) async {
        _setViewport(
          tester,
          width: 412,
          height: 915,
          textScale: textScale,
        );
        await _pumpProfile(tester, authenticated: true);

        expect(tester.takeException(), isNull);
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -1200),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('responsive Profile never overflows (guest)', () {
    testWidgets('renders at 320px width, 2.0x text without overflow', (
      tester,
    ) async {
      _setViewport(tester, width: 320, height: 568, textScale: 2.0);
      await _pumpProfile(tester, authenticated: false);

      expect(tester.takeException(), isNull,
          reason: 'overflow in the guest Profile viewport');
    });

    testWidgets('renders on a Pixel 7 Pro (412x915) at 1.0x text', (
      tester,
    ) async {
      _setViewport(tester, width: 412, height: 915, textScale: 1.0);
      await _pumpProfile(tester, authenticated: false);

      expect(tester.takeException(), isNull,
          reason: 'overflow in the guest Profile viewport');
    });
  });

  group('profile picture update', () {
    testWidgets('the avatar offers a change-photo action', (tester) async {
      await _buildAvatarApp(tester);

      await _openAvatarSheet(tester);

      expect(find.text('Change profile picture'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('selecting from the gallery uploads the avatar and renders it',
        (tester) async {
      final bundle = await _buildAvatarApp(
        tester,
        galleryBytes: tinyPngBytes,
      );
      expect(find.text('CC'), findsOneWidget);
      expect(find.byIcon(Icons.sports_motorsports_rounded), findsNothing);

      await _pickFromGallery(tester);

      // The update went through the real updateProfile -> PUT /auth/profile.
      expect(bundle.picker.galleryCalled, isTrue);
      expect(bundle.adapter.putBodies, hasLength(1));
      final avatar = bundle.adapter.putBodies.single['avatar'] as String;
      expect(avatar, startsWith('data:image/jpeg;base64,'));
      expect(avatar.length, lessThan(200 * 1024));

      // AuthProvider state reflects the new avatar immediately.
      expect(bundle.auth.user!.avatar, avatar);
      expect(find.text('Profile picture updated'), findsOneWidget);
      expect(find.text('CC'), findsNothing);
      expect(find.byType(Image), findsWidgets);
    });

    testWidgets('a cancelled picker makes no request and keeps the avatar',
        (tester) async {
      final bundle = await _buildAvatarApp(tester, galleryBytes: null);

      await _pickFromGallery(tester);

      expect(bundle.picker.galleryCalled, isTrue);
      expect(bundle.adapter.putBodies, isEmpty);
      expect(bundle.auth.user!.avatar, '');
      expect(find.byType(SnackBar), findsNothing);
      expect(find.text('CC'), findsOneWidget);
    });

    testWidgets('cancelling the sheet (not picking) also does nothing', (
      tester,
    ) async {
      final bundle = await _buildAvatarApp(tester, galleryBytes: tinyPngBytes);

      await _openAvatarSheet(tester);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(bundle.picker.galleryCalled, isFalse);
      expect(bundle.adapter.putBodies, isEmpty);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('an invalid image shows a friendly error and no request', (
      tester,
    ) async {
      final bundle = await _buildAvatarApp(
        tester,
        galleryBytes: Uint8List.fromList([1, 2, 3, 4]),
      );

      await _pickFromGallery(tester);

      expect(bundle.adapter.putBodies, isEmpty);
      expect(bundle.auth.user!.avatar, '');
      expect(
        find.text("Couldn't read that image. Please try another one."),
        findsOneWidget,
      );
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('a picker platform error shows a friendly message', (
      tester,
    ) async {
      final bundle = await _buildAvatarApp(
        tester,
        pickError: PlatformException(code: 'camera_access_denied'),
      );

      await _pickFromGallery(tester);

      expect(bundle.adapter.putBodies, isEmpty);
      expect(bundle.auth.user!.avatar, '');
      expect(
        find.text('Could not open the camera or photo library.'),
        findsOneWidget,
      );
    });

    testWidgets('an API failure shows the clean server message and keeps avatar',
        (tester) async {
      final bundle = await _buildAvatarApp(
        tester,
        galleryBytes: tinyPngBytes,
        failPutWith: 500,
      );

      await _pickFromGallery(tester);

      expect(bundle.adapter.putBodies, hasLength(1));
      expect(bundle.auth.user!.avatar, '');
      expect(find.text('Failed to update profile'), findsOneWidget);
      expect(find.text('CC'), findsOneWidget);
    });

    testWidgets('the change-photo sheet opens at 320px/2.0x without overflow', (
      tester,
    ) async {
      _setViewport(tester, width: 320, height: 568, textScale: 2.0);
      await _buildAvatarApp(tester, galleryBytes: tinyPngBytes);

      await _openAvatarSheet(tester);

      expect(tester.takeException(), isNull,
          reason: 'avatar sheet must not overflow at 320px/2.0x');
      expect(find.text('Choose from Gallery'), findsOneWidget);
    });
  });
}