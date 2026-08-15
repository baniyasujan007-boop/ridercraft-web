// AuthProvider session/profile behaviour around the avatar field:
// restoreSession, reloadProfile and updateProfile must all keep the profile
// image intact.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridercraft_mobile/models/user.dart';
import 'package:ridercraft_mobile/providers/auth_provider.dart';
import 'package:ridercraft_mobile/services/api_client.dart';
import 'package:ridercraft_mobile/services/auth_service.dart';
import 'package:ridercraft_mobile/services/token_store.dart';

import 'support/test_storage.dart';

class _FakeAuthService extends AuthService {
  _FakeAuthService(super.api, super.storage, {required User initial})
      : profile = initial;

  User profile;

  @override
  Future<User> fetchProfile() async => profile;

  @override
  Future<User> updateProfile({
    String? name,
    String? avatar,
    String? contactNumber,
    String? deliveryAddress,
  }) async {
    profile = User(
      id: profile.id,
      name: name ?? profile.name,
      email: profile.email,
      role: profile.role,
      avatar: avatar ?? profile.avatar,
      contactNumber: contactNumber ?? profile.contactNumber,
      deliveryAddress: deliveryAddress ?? profile.deliveryAddress,
    );
    return profile;
  }
}

void main() {
  const avatarA = 'data:image/png;base64,AAAA';
  const avatarB = 'https://example.com/b.png';

  Future<({AuthProvider auth, _FakeAuthService service})> build({
    required String token,
    required User user,
  }) async {
    SharedPreferences.setMockInitialValues(
      token.isEmpty ? {} : {'ridercraft_auth_token': token},
    );
    final prefs = await SharedPreferences.getInstance();
    final storage = TestStorageService(prefs);
    final api = ApiClient(tokenProvider: () => null, dio: Dio());
    final service = _FakeAuthService(api, storage, initial: user);
    return (auth: AuthProvider(service, TokenStore()), service: service);
  }

  test('restoreSession loads the profile including the avatar', () async {
    final bundle = await build(
      token: 'tok',
      user: User(
        id: 'u1',
        name: 'Aarav',
        email: 'aarav@ridercraft.app',
        avatar: avatarA,
      ),
    );
    await bundle.auth.restoreSession();

    expect(bundle.auth.isAuthenticated, isTrue);
    expect(bundle.auth.user!.avatar, avatarA);
  });

  test('restoreSession without a token stays unauthenticated', () async {
    final bundle = await build(
      token: '',
      user: User(id: 'u1', name: 'Aarav', email: 'aarav@ridercraft.app'),
    );
    await bundle.auth.restoreSession();

    expect(bundle.auth.isAuthenticated, isFalse);
    expect(bundle.auth.user, isNull);
  });

  test('reloadProfile refreshes the avatar from the server', () async {
    final bundle = await build(
      token: 'tok',
      user: User(
        id: 'u1',
        name: 'Aarav',
        email: 'aarav@ridercraft.app',
        avatar: avatarA,
      ),
    );
    await bundle.auth.restoreSession();
    expect(bundle.auth.user!.avatar, avatarA);

    bundle.service.profile = bundle.service.profile.copyWith(avatar: avatarB);
    await bundle.auth.reloadProfile();

    expect(bundle.auth.user!.avatar, avatarB);
  });

  test('updateProfile preserves the avatar when it is not edited', () async {
    final bundle = await build(
      token: 'tok',
      user: User(
        id: 'u1',
        name: 'Aarav',
        email: 'aarav@ridercraft.app',
        avatar: avatarA,
      ),
    );
    await bundle.auth.restoreSession();

    await bundle.auth.updateProfile(name: 'New Name');

    expect(bundle.auth.user!.name, 'New Name');
    expect(bundle.auth.user!.avatar, avatarA);
  });

  test('logout clears the profile image', () async {
    final bundle = await build(
      token: 'tok',
      user: User(
        id: 'u1',
        name: 'Aarav',
        email: 'aarav@ridercraft.app',
        avatar: avatarA,
      ),
    );
    await bundle.auth.restoreSession();
    await bundle.auth.logout();

    expect(bundle.auth.isAuthenticated, isFalse);
    expect(bundle.auth.user, isNull);
  });
}