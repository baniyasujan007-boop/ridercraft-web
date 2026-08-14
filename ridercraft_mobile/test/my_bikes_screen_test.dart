import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridercraft_mobile/models/bike.dart';
import 'package:ridercraft_mobile/models/service_package.dart';
import 'package:ridercraft_mobile/providers/bike_provider.dart';
import 'package:ridercraft_mobile/screens/bikes/my_bikes_screen.dart';
import 'package:ridercraft_mobile/screens/bookings/service_booking_screen.dart';
import 'package:ridercraft_mobile/services/storage_service.dart';
import 'package:ridercraft_mobile/theme/app_theme.dart';

import 'support/test_storage.dart';

const _bikesKey = 'ridercraft_my_bikes_v1';
const _testToken = 'test-token';

String _bikesJson(
  List<Map<String, dynamic>> bikes, {
  String? selectedId,
}) =>
    jsonEncode({'bikes': bikes, 'selectedId': selectedId});

Map<String, dynamic> _bike({
  String id = 'b_1',
  String brand = 'Honda',
  String model = 'SP 125',
  String reg = '',
  String year = '',
  String cc = '',
}) {
  return {
    'id': id,
    'brand': brand,
    'model': model,
    'registrationNumber': reg,
    'year': year,
    'engineCapacity': cc,
    'image': '',
  };
}

Future<({Widget app, BikeProvider provider})> _buildApp({
  List<Map<String, dynamic>> bikes = const [],
  String? selectedId,
  StorageService? storageOverride,
}) async {
  SharedPreferences.setMockInitialValues(
    bikes.isEmpty && selectedId == null
        ? {}
        : {_bikesKey: _bikesJson(bikes, selectedId: selectedId)},
  );
  final prefs = await SharedPreferences.getInstance();
  final storage = storageOverride ?? TestStorageService(prefs);
  final provider = BikeProvider(storage);
  final app = MultiProvider(
    providers: [ChangeNotifierProvider.value(value: provider)],
    child: MaterialApp(theme: AppTheme.dark, home: const MyBikesScreen()),
  );
  return (app: app, provider: provider);
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

Future<void> _openAddSheet(WidgetTester tester) async {
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
}

Future<void> _fillForm(
  WidgetTester tester, {
  String brand = 'Honda',
  String model = 'SP 125',
  String reg = 'MH-12-AB-1234',
  String year = '2021',
  String cc = '125',
}) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'Brand'), brand);
  await tester.enterText(find.widgetWithText(TextFormField, 'Model'), model);
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Registration No.'),
    reg,
  );
  await tester.enterText(find.widgetWithText(TextFormField, 'Year'), year);
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Engine capacity (cc)'),
    cc,
  );
}

class _GatedStorage extends StorageService {
  final Completer<String?> bikes = Completer<String?>();

  _GatedStorage(super.prefs);

  @override
  Future<String?> readBikes() => bikes.future;
}

void main() {
  group('BikeProvider local persistence', () {
    test('loads bikes and defaults the selected bike to the first', () async {
      SharedPreferences.setMockInitialValues({
        _bikesKey: _bikesJson([
          _bike(id: 'b_1', model: 'SP 125'),
          _bike(id: 'b_2', model: 'CB Shine'),
        ]),
      });
      final prefs = await SharedPreferences.getInstance();
      final provider = BikeProvider(TestStorageService(prefs))..load();
      await provider.load();

      expect(provider.bikes.length, 2);
      expect(provider.selectedBike?.id, 'b_1');
      expect(provider.loaded, isTrue);
    });

    test('a persisted selected bike wins over the first', () async {
      SharedPreferences.setMockInitialValues({
        _bikesKey: _bikesJson(
          [
            _bike(id: 'b_1', model: 'SP 125'),
            _bike(id: 'b_2', model: 'CB Shine'),
          ],
          selectedId: 'b_2',
        ),
      });
      final prefs = await SharedPreferences.getInstance();
      final provider = BikeProvider(TestStorageService(prefs))..load();
      await provider.load();

      expect(provider.selectedBike?.id, 'b_2');
    });

    test('add defaults the first saved bike to be selected', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final provider = BikeProvider(TestStorageService(prefs))..load();
      await provider.load();

      await provider.addBike(
        const Bike(id: 'b_1', brand: 'Yamaha', model: 'R15 V4'),
      );
      expect(provider.selectedBike?.id, 'b_1');

      final raw = prefs.getString(_bikesKey)!;
      expect(jsonDecode(raw)['selectedId'], 'b_1');
    });

    test('updating a bike keeps its id and selection', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final provider = BikeProvider(TestStorageService(prefs))..load();
      await provider.load();
      await provider.addBike(
        const Bike(id: 'b_1', brand: 'Honda', model: 'SP 125'),
      );

      await provider.updateBike(
        const Bike(id: 'b_1', brand: 'Honda', model: 'CB Shine'),
      );

      expect(provider.bikes.single.displayName, 'Honda CB Shine');
      expect(provider.selectedBike?.id, 'b_1');
    });

    test('deleting the selected bike clears the selection', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final provider = BikeProvider(TestStorageService(prefs))..load();
      await provider.load();
      await provider.addBike(
        const Bike(id: 'b_1', brand: 'Honda', model: 'SP 125'),
      );
      await provider.addBike(
        const Bike(id: 'b_2', brand: 'Yamaha', model: 'R15'),
      );
      await provider.selectBike('b_2');

      await provider.deleteBike('b_2');

      expect(provider.bikes.length, 1);
      expect(provider.selectedBike?.id, 'b_1');
    });

    test('select persists the chosen id to local storage', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final provider = BikeProvider(TestStorageService(prefs))..load();
      await provider.load();
      await provider.addBike(
        const Bike(id: 'b_1', brand: 'Honda', model: 'SP 125'),
      );
      await provider.addBike(
        const Bike(id: 'b_2', brand: 'Yamaha', model: 'R15'),
      );

      await provider.selectBike('b_2');

      final raw = prefs.getString(_bikesKey)!;
      expect(jsonDecode(raw)['selectedId'], 'b_2');

      // A fresh provider reloads the same selection.
      final fresh = BikeProvider(TestStorageService(prefs))..load();
      await fresh.load();
      expect(fresh.bikes.length, 2);
      expect(fresh.selectedBike?.id, 'b_2');
    });

    test('corrupt local JSON degrades to an empty garage', () async {
      SharedPreferences.setMockInitialValues({_bikesKey: '{not json'});
      final prefs = await SharedPreferences.getInstance();
      final provider = BikeProvider(TestStorageService(prefs))..load();
      await provider.load();

      expect(provider.bikes, isEmpty);
      expect(provider.loaded, isTrue);
    });
  });

  testWidgets('shows a loading state, then the empty state with no bikes', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final storage = _GatedStorage(prefs);
    final bundle = await _buildApp(storageOverride: storage);
    await tester.pumpWidget(bundle.app);
    await tester.pump();

    expect(find.text('Loading bikes…'), findsOneWidget);

    storage.bikes.complete(null);
    await tester.pumpAndSettle();

    expect(find.text('Loading bikes…'), findsNothing);
    expect(find.text('No bikes added yet.'), findsOneWidget);
    expect(find.text('Add your bike to book services faster.'), findsOneWidget);
  });

  testWidgets('adds a bike through the form and persists it', (tester) async {
    final bundle = await _buildApp();
    await tester.pumpWidget(bundle.app);
    await tester.pumpAndSettle();

    await _openAddSheet(tester);
    expect(find.text('Add your bike'), findsOneWidget);

    await _fillForm(tester);
    await tester.ensureVisible(find.text('Save Bike'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Bike'));
    await tester.pumpAndSettle();

    expect(find.text('Add your bike'), findsNothing);
    expect(find.text('Honda SP 125'), findsOneWidget);
    expect(find.text('2021 • 125 cc • MH-12-AB-1234'), findsOneWidget);

    expect(bundle.provider.bikes.single.brand, 'Honda');
    expect(bundle.provider.selectedBike?.displayName, 'Honda SP 125');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_bikesKey), contains('"brand":"Honda"'));
  });

  testWidgets('validates required brand and model fields', (tester) async {
    final bundle = await _buildApp();
    await tester.pumpWidget(bundle.app);
    await tester.pumpAndSettle();

    await _openAddSheet(tester);
    await tester.ensureVisible(find.text('Save Bike'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Bike'));
    await tester.pumpAndSettle();

    expect(find.text('Brand is required'), findsOneWidget);
    expect(find.text('Model is required'), findsOneWidget);
    expect(find.text('Add your bike'), findsOneWidget);
    expect(bundle.provider.bikes, isEmpty);
  });

  testWidgets('edits an existing bike', (tester) async {
    final bundle = await _buildApp(
      bikes: [
        _bike(id: 'b_1', model: 'SP 125', reg: 'MH-12-AB-1234'),
      ],
    );
    await tester.pumpWidget(bundle.app);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    expect(find.text('Edit bike'), findsOneWidget);

    // Brand/Model are pre-filled.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Model'),
      'CB Shine',
    );
    await tester.ensureVisible(find.text('Update Bike'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Update Bike'));
    await tester.pumpAndSettle();

    expect(find.text('Honda CB Shine'), findsOneWidget);
    expect(find.text('Honda SP 125'), findsNothing);
    expect(bundle.provider.bikes.single.id, 'b_1');
  });

  testWidgets('deletion asks for confirmation and cancel keeps the bike', (
    tester,
  ) async {
    final bundle = await _buildApp(
      bikes: [_bike(id: 'b_1'), _bike(id: 'b_2', model: 'CB Shine')],
    );
    await tester.pumpWidget(bundle.app);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete').first);
    await tester.pumpAndSettle();
    expect(find.text('Remove bike?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(bundle.provider.bikes.length, 2);
    expect(find.text('Honda SP 125'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(bundle.provider.bikes.length, 1);
    expect(find.text('Honda SP 125'), findsNothing);
    expect(find.text('Honda CB Shine'), findsOneWidget);
  });

  testWidgets('tapping a bike makes it the default/selected bike', (
    tester,
  ) async {
    final bundle = await _buildApp(
      bikes: [_bike(id: 'b_1'), _bike(id: 'b_2', model: 'CB Shine')],
    );
    await tester.pumpWidget(bundle.app);
    await tester.pumpAndSettle();

    // First bike is the implicit default.
    expect(bundle.provider.selectedBike?.id, 'b_1');
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    await tester.tap(find.text('Honda CB Shine'));
    await tester.pumpAndSettle();

    expect(bundle.provider.selectedBike?.id, 'b_2');
    // Only one selected badge, now on the second bike.
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString(_bikesKey)!), containsPair('selectedId', 'b_2'));
  });

  testWidgets('a saved bike appears in the booking form and populates selection', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      _bikesKey: _bikesJson(
        [_bike(id: 'b_1', brand: 'Yamaha', model: 'R15 V4')],
        selectedId: 'b_1',
      ),
      'ridercraft_auth_token': _testToken,
    });
    final prefs = await SharedPreferences.getInstance();
    final provider = BikeProvider(TestStorageService(prefs))..load();
    await provider.load();

    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider.value(value: provider)],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: ServiceBookingScreen(package: servicePackages.first),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The saved bike renders as a selectable option in the booking form.
    expect(find.text('Yamaha R15 V4'), findsOneWidget);

    await tester.tap(find.text('Yamaha R15 V4'));
    await tester.pumpAndSettle();
    // Selection indicator flips to "checked".
    expect(find.byIcon(Icons.radio_button_checked_rounded), findsOneWidget);
    // The booking screen will send displayName as the backend bikeModel.
    expect(provider.selectedBike?.displayName, 'Yamaha R15 V4');
  });

  group('responsive My Bikes never overflows', () {
    for (final width in [320.0, 360.0, 390.0, 430.0]) {
      for (final textScale in [1.0, 1.3, 2.0]) {
        testWidgets(
            'bike list at ${width}px width, ${textScale}x text without overflow',
            (tester) async {
          _setViewport(
            tester,
            width: width,
            height: 844,
            textScale: textScale,
          );
          final bundle = await _buildApp(
            bikes: [
              _bike(
                id: 'b_1',
                brand: 'Royal Enfield',
                model: 'Classic 350 Dual Channel ABS',
                reg: 'MH-12-AB-1234',
                year: '2022',
                cc: '350',
              ),
              _bike(
                id: 'b_2',
                brand: 'Yamaha',
                model: 'MT-15 V2',
                reg: 'KA-01-EF-5678',
                year: '2023',
                cc: '155',
              ),
              _bike(
                id: 'b_3',
                brand: 'Honda',
                model: 'Activa 6G',
                reg: 'DL-8C-2468',
                year: '2021',
                cc: '110',
              ),
            ],
          );
          await tester.pumpWidget(bundle.app);
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull,
              reason: 'overflow in the initial bikes viewport');

          await tester.drag(find.byType(ListView), const Offset(0, -2000));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: 'overflow after scrolling the bikes list');
        });
      }
    }

    for (final textScale in [1.0, 1.3, 2.0]) {
      testWidgets('bike list on a Pixel 7 Pro at ${textScale}x text', (
        tester,
      ) async {
        _setViewport(
          tester,
          width: 412,
          height: 915,
          textScale: textScale,
        );
        final bundle = await _buildApp(
          bikes: [
            _bike(id: 'b_1', brand: 'Honda', model: 'SP 125'),
            _bike(id: 'b_2', brand: 'Yamaha', model: 'R15 V4'),
          ],
        );
        await tester.pumpWidget(bundle.app);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(ListView), const Offset(0, -800));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('empty state at 320px width, 2.0x text', (tester) async {
      _setViewport(tester, width: 320, height: 568, textScale: 2.0);
      final bundle = await _buildApp();
      await tester.pumpWidget(bundle.app);
      await tester.pumpAndSettle();

      expect(find.text('No bikes added yet.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('add-bike form at 320px width, 2.0x text', (tester) async {
      _setViewport(tester, width: 320, height: 568, textScale: 2.0);
      final bundle = await _buildApp();
      await tester.pumpWidget(bundle.app);
      await tester.pumpAndSettle();

      await _openAddSheet(tester);
      await tester.pumpAndSettle();
      expect(find.text('Add your bike'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('delete dialog at 320px width, 2.0x text', (tester) async {
      _setViewport(tester, width: 320, height: 568, textScale: 2.0);
      final bundle = await _buildApp(bikes: [_bike(id: 'b_1')]);
      await tester.pumpWidget(bundle.app);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Remove bike?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}