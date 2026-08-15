// User model parsing of the profile image (`avatar`) field returned by
// `GET /auth/profile`.
import 'package:flutter_test/flutter_test.dart';

import 'package:ridercraft_mobile/models/user.dart';

void main() {
  const httpsUrl = 'https://lh3.googleusercontent.com/photo.png';
  const dataUri = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAAB';

  Map<String, dynamic> baseJson({Object? avatar = httpsUrl}) => {
        '_id': 'u1',
        'name': 'Aarav Sharma',
        'email': 'aarav@ridercraft.app',
        'role': 'user',
        'avatar': avatar,
        'contactNumber': '+919811223344',
        'deliveryAddress': 'MG Marg, Gangtok',
      };

  group('User.fromJson', () {
    test('parses the avatar field from /auth/profile', () {
      final user = User.fromJson(baseJson());
      expect(user.avatar, httpsUrl);
    });

    test('parses a base64 data URI avatar', () {
      final user = User.fromJson(baseJson(avatar: dataUri));
      expect(user.avatar, dataUri);
    });

    test('null avatar falls back to empty string without crashing', () {
      final user = User.fromJson(baseJson(avatar: null));
      expect(user.avatar, '');
    });

    test('missing avatar key falls back to empty string', () {
      final json = baseJson()..remove('avatar');
      final user = User.fromJson(json);
      expect(user.avatar, '');
    });
  });
}