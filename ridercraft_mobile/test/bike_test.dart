import 'package:flutter_test/flutter_test.dart';

import 'package:ridercraft_mobile/models/bike.dart';

void main() {
  test('displayName combines brand and model as the booking bikeModel', () {
    const bike = Bike(
      id: '1',
      brand: 'Yamaha',
      model: 'R15 V4',
    );
    // The booking flow sends displayName as the backend `bikeModel` field.
    expect(bike.displayName, 'Yamaha R15 V4');
  });

  test('displayName falls back gracefully for empty parts', () {
    const bike = Bike(id: '1', brand: '', model: 'R15');
    expect(bike.displayName, 'R15');

    const empty = Bike(id: '1', brand: '', model: '');
    expect(empty.displayName, 'My Bike');
  });

  test('subtitle combines year, capacity and registration', () {
    const bike = Bike(
      id: '1',
      brand: 'Honda',
      model: 'SP 125',
      registrationNumber: 'MH-12-AB-1234',
      year: '2021',
      engineCapacity: '125',
    );
    expect(bike.subtitle, '2021 • 125 cc • MH-12-AB-1234');
  });

  test('round-trips through JSON for local persistence', () {
    const bike = Bike(
      id: '2',
      brand: 'TVS',
      model: 'Apache',
      registrationNumber: 'KA-01-EF-5678',
    );
    final restored = Bike.fromJson(bike.toJson());
    expect(restored.id, '2');
    expect(restored.displayName, 'TVS Apache');
    expect(restored.registrationNumber, 'KA-01-EF-5678');
  });
}
