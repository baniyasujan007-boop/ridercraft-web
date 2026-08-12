import 'package:flutter_test/flutter_test.dart';

import 'package:ridercraft_mobile/models/service_package.dart';

void main() {
  test('servicePackages exposes exactly the three backend package types',
      () {
    expect(servicePackages, hasLength(3));
    expect(servicePackages.map((p) => p.type), [
      'basic',
      'full',
      'premium',
    ]);
  });

  test('package labels match the RiderCraft web terminology', () {
    expect(servicePackages[0].label, 'Basic Tune-Up');
    expect(servicePackages[1].label, 'Full Service');
    expect(servicePackages[2].label, 'Premium Care');
  });

  test('every package has a summary and included items', () {
    for (final package in servicePackages) {
      expect(package.summary, isNotEmpty);
      expect(package.includes, isNotEmpty);
    }
  });

  test('servicePackageForType resolves known and unknown types', () {
    expect(servicePackageForType('premium').label, 'Premium Care');
    expect(servicePackageForType('full').label, 'Full Service');
    // Unknown types fall back to the first package instead of crashing.
    expect(servicePackageForType('gold').type, 'basic');
  });
}
