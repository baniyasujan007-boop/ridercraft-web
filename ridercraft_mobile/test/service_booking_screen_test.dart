import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridercraft_mobile/models/service_package.dart';
import 'package:ridercraft_mobile/providers/bike_provider.dart';
import 'package:ridercraft_mobile/routes/app_routes.dart';
import 'package:ridercraft_mobile/screens/bookings/service_booking_screen.dart';
import 'package:ridercraft_mobile/services/storage_service.dart';
import 'package:ridercraft_mobile/theme/app_theme.dart';

Future<Widget> _buildScreen(StorageService storage) async {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => BikeProvider(storage)..load()),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: ServiceBookingScreen(package: servicePackages.first),
    ),
  );
}

void main() {
  testWidgets('booking form validates required fields, then demands a bike',
      (tester) async {
    // Use a tall viewport so every field is laid out without scrolling.
    tester.view.physicalSize = const Size(600, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({
      'ridercraft_my_bikes_v1': jsonEncode({
        'bikes': [
          {
            'id': 'b1',
            'brand': 'Yamaha',
            'model': 'R15 V4',
            'registrationNumber': 'MH-12-AB-1234',
          }
        ],
        'selectedId': null,
      }),
    });
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);

    await tester.pumpWidget(await _buildScreen(storage));
    await tester.pumpAndSettle();

    // The saved bike is shown as a selectable option.
    expect(find.text('Yamaha R15 V4'), findsOneWidget);

    // Required fields block submission with inline validation errors.
    await tester.tap(find.text('Continue to Review'));
    await tester.pump();
    expect(find.text('Pickup address is required'), findsOneWidget);

    // Fill every required field, then submission is blocked until a bike is chosen.
    await tester.enterText(find.byType(TextFormField).at(0), 'MG Road, Pune');
    await tester.enterText(find.byType(TextFormField).at(1), '18.5204');
    await tester.enterText(find.byType(TextFormField).at(2), '73.8567');
    await tester.enterText(find.byType(TextFormField).at(3), '9876543210');
    await tester.tap(find.text('Continue to Review'));
    await tester.pump();

    expect(find.text('Select a bike to continue.'), findsOneWidget);
  });
}
