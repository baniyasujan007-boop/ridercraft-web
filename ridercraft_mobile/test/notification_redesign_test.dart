import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ridercraft_mobile/routes/app_routes.dart';
import 'package:ridercraft_mobile/screens/notifications/notifications_screen.dart';
import 'package:ridercraft_mobile/services/api_client.dart';
import 'package:ridercraft_mobile/services/notification_service.dart';
import 'package:ridercraft_mobile/services/token_store.dart';
import 'package:ridercraft_mobile/theme/app_theme.dart';
import 'package:ridercraft_mobile/utils/formatters.dart';

ResponseBody _json(String body, int status) => ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

Map<String, dynamic> _notification({
  required String id,
  required String title,
  String body = 'Message body',
  String type = 'order',
  bool isRead = false,
}) {
  return {
    '_id': id,
    'title': title,
    'body': body,
    'type': type,
    'isRead': isRead,
    'createdAt': DateTime.now()
        .subtract(const Duration(minutes: 30))
        .toUtc()
        .toIso8601String(),
  };
}

/// In-memory backend for the existing notification endpoints.
class _Adapter implements HttpClientAdapter {
  List<Map<String, dynamic>> notifications;
  final List<String> readAllCalls = [];
  int getCalls = 0;

  _Adapter(this.notifications);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method == 'GET' && options.path == '/notifications') {
      getCalls++;
      return _json(jsonEncode(notifications), 200);
    }
    if (options.method == 'PUT' && options.path == '/notifications/read-all') {
      readAllCalls.add('read-all');
      notifications = notifications
          .map((n) => {...n, 'isRead': true})
          .toList();
      return _json('{"success":true}', 200);
    }
    final readMatch =
        RegExp(r'^/notifications/([^/]+)/read$').firstMatch(options.path);
    if (options.method == 'PUT' && readMatch != null) {
      notifications = [
        for (final n in notifications)
          if (n['_id'] == readMatch.group(1)) {...n, 'isRead': true} else n,
      ];
      return _json('{"success":true}', 200);
    }
    return _json('{"error":"Not found"}', 404);
  }

  @override
  void close({bool force = false}) {}
}

Future<({Widget app, _Adapter adapter})> _buildApp({
  required List<Map<String, dynamic>> notifications,
}) async {
  final tokenStore = TokenStore()..current = 'test-token';
  final adapter = _Adapter(notifications);
  final api = ApiClient(
    tokenProvider: () => tokenStore.current,
    dio: Dio()..httpClientAdapter = adapter,
  );
  final app = MultiProvider(
    providers: [Provider.value(value: NotificationService(api))],
    child: MaterialApp(
      theme: AppTheme.dark,
      home: const NotificationsScreen(),
      onGenerateRoute: AppRouter.onGenerateRoute,
    ),
  );
  return (app: app, adapter: adapter);
}

void main() {
  setUpAll(Formatters.ensureDateSymbols);

  testWidgets('header surfaces the live unread count', (tester) async {
    final bundle = await _buildApp(
      notifications: [
        _notification(id: 'n_1', title: 'Order shipped'),
        _notification(id: 'n_2', title: 'Payment received', isRead: true),
        _notification(id: 'n_3', title: 'Service booked'),
        _notification(id: 'n_4', title: 'Coupon added', isRead: true),
      ],
    );
    await tester.pumpWidget(bundle.app);
    await tester.pumpAndSettle();

    expect(find.text('4 notifications'), findsOneWidget);
    expect(find.text('2 unread'), findsOneWidget);
    expect(find.text('Mark all'), findsOneWidget);
  });

  testWidgets('unread rows carry an "Unread" semantic label', (tester) async {
    final bundle = await _buildApp(
      notifications: [
        _notification(id: 'n_1', title: 'Order shipped'),
        _notification(id: 'n_2', title: 'Payment received', isRead: true),
      ],
    );
    await tester.pumpWidget(bundle.app);
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel(RegExp('Unread.*Order shipped')),
        findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Unread.*Payment received')),
        findsNothing);
  });

  testWidgets('mark all clears the unread state and chip', (tester) async {
    final bundle = await _buildApp(
      notifications: [
        _notification(id: 'n_1', title: 'Order shipped'),
        _notification(id: 'n_2', title: 'Service booked'),
      ],
    );
    await tester.pumpWidget(bundle.app);
    await tester.pumpAndSettle();

    expect(find.text('2 unread'), findsOneWidget);

    await tester.tap(find.text('Mark all'));
    await tester.pumpAndSettle();

    expect(bundle.adapter.readAllCalls, ['read-all']);
    expect(find.text('2 unread'), findsNothing);
    expect(find.text('Mark all'), findsNothing);
  });

  testWidgets('category types map to distinct icons', (tester) async {
    final bundle = await _buildApp(
      notifications: [
        _notification(id: 'n_1', title: 'Order', type: 'order'),
        _notification(id: 'n_2', title: 'Service', type: 'service'),
        _notification(id: 'n_3', title: 'Payment', type: 'payment'),
        _notification(id: 'n_4', title: 'Coupon', type: 'coupon'),
        _notification(id: 'n_5', title: 'Profile', type: 'profile'),
        _notification(id: 'n_6', title: 'General', type: 'general'),
      ],
    );
    await tester.pumpWidget(bundle.app);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.receipt_long_outlined), findsWidgets);
    expect(find.byIcon(Icons.build_outlined), findsWidgets);
    expect(find.byIcon(Icons.payments_outlined), findsWidgets);
    expect(find.byIcon(Icons.confirmation_number_outlined), findsWidgets);
    expect(find.byIcon(Icons.person_outline_rounded), findsWidgets);
    expect(find.byIcon(Icons.notifications_none_rounded), findsWidgets);
  });

  for (final width in const [320.0, 360.0, 390.0, 430.0]) {
    for (final scale in const [1.0, 1.3, 2.0]) {
      testWidgets(
          'redesigned list no overflow at ${width}px and ${scale}x text',
          (tester) async {
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = Size(width, 844);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final bundle = await _buildApp(
          notifications: [
            for (var i = 0; i < 8; i++)
              _notification(
                id: 'n_$i',
                title: 'Order and service update from RiderCraft #$i',
                body:
                    'A long notification body describing what changed and '
                    'what the rider should know next about their bike.',
                type: i.isEven ? 'service' : 'order',
                isRead: i.isOdd,
              ),
          ],
        );
        await tester.pumpWidget(bundle.app);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull,
            reason: 'overflow at ${width}px / ${scale}x');

        await tester.drag(find.byType(ListView), const Offset(0, -3000));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: 'overflow after scrolling at ${width}px / ${scale}x');
      });
    }
  }
}