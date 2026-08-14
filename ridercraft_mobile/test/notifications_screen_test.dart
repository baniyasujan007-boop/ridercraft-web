import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ridercraft_mobile/models/notification.dart';
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

/// Backend fixture for the notification endpoints that actually exist:
/// GET /notifications, PUT /notifications/read-all and
/// PUT /notifications/:id/read.
Map<String, dynamic> _notification({
  required String id,
  required String title,
  String body = 'Your service is on the way',
  String type = 'service',
  bool isRead = false,
  DateTime? createdAt,
}) {
  return {
    '_id': id,
    'title': title,
    'body': body,
    'type': type,
    'isRead': isRead,
    'createdAt': (createdAt ??
            DateTime.now().subtract(const Duration(minutes: 5)))
        .toUtc()
        .toIso8601String(),
  };
}

/// In-memory backend for the notification endpoints.
class _NotificationsAdapter implements HttpClientAdapter {
  List<Map<String, dynamic>> notifications;
  int failNext;
  bool forceUnauthorized;
  Duration? responseDelay;
  final List<String> readAllCalls = [];
  final List<String> singleReadCalls = [];
  int getCalls = 0;

  _NotificationsAdapter(
    this.notifications, {
    this.failNext = 0,
    this.forceUnauthorized = false,
    this.responseDelay,
  });

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method == 'GET' && options.path == '/notifications') {
      getCalls++;
      if (forceUnauthorized) {
        return _json('{"error":"Unauthorized"}', 401);
      }
      if (responseDelay != null) {
        await Future<void>.delayed(responseDelay!);
      }
      if (getCalls <= failNext) {
        return _json('{"error":"Failed to load notifications"}', 500);
      }
      return _json(jsonEncode(notifications), 200);
    }

    if (options.method == 'PUT' && options.path == '/notifications/read-all') {
      readAllCalls.add('read-all');
      return _json('{"success":true}', 200);
    }

    final readMatch =
        RegExp(r'^/notifications/([^/]+)/read$').firstMatch(options.path);
    if (options.method == 'PUT' && readMatch != null) {
      singleReadCalls.add(readMatch.group(1)!);
      return _json('{"success":true}', 200);
    }

    return _json('{"error":"Not found"}', 404);
  }

  @override
  void close({bool force = false}) {}
}

Future<({Widget app, _NotificationsAdapter adapter})> _buildApp({
  required bool authenticated,
  List<Map<String, dynamic>> notifications = const [],
  int failNext = 0,
  Duration? responseDelay,
}) async {
  final tokenStore = TokenStore()
    ..current = authenticated ? 'test-token' : null;
  final adapter = _NotificationsAdapter(
    notifications,
    failNext: failNext,
    forceUnauthorized: !authenticated,
    responseDelay: responseDelay,
  );
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

void main() {
  setUpAll(Formatters.ensureDateSymbols);

  group('AppNotification parsing', () {
    test('parses a full document', () {
      final item = AppNotification.fromJson({
        '_id': 'n_1',
        'title': 'Booking confirmed',
        'body': 'Your slot is locked in',
        'type': 'service',
        'isRead': true,
        'createdAt': '2026-08-11T09:00:00.000Z',
      });
      expect(item.id, 'n_1');
      expect(item.title, 'Booking confirmed');
      expect(item.body, 'Your slot is locked in');
      expect(item.type, 'service');
      expect(item.isRead, isTrue);
      expect(item.createdAt, isNotNull);
    });

    test('defaults unread/type when the backend omits them', () {
      final item = AppNotification.fromJson({
        '_id': 'n_2',
        'title': 'Hi',
        'body': 'Body',
      });
      expect(item.type, 'general');
      expect(item.isRead, isFalse);
      expect(item.createdAt, isNull);
    });
  });

  group('Formatters.timeAgoLabel', () {
    final now = DateTime(2026, 8, 13, 12, 0, 0);

    test('renders relative labels and falls back to dates', () {
      expect(
        Formatters.timeAgoLabel(now.subtract(const Duration(seconds: 20)),
            now: now),
        'Just now',
      );
      expect(
        Formatters.timeAgoLabel(now.subtract(const Duration(minutes: 12)),
            now: now),
        '12m ago',
      );
      expect(
        Formatters.timeAgoLabel(now.subtract(const Duration(hours: 3)),
            now: now),
        '3h ago',
      );
      expect(
        Formatters.timeAgoLabel(now.subtract(const Duration(days: 1)),
            now: now),
        'Yesterday',
      );
      expect(
        Formatters.timeAgoLabel(now.subtract(const Duration(days: 3)),
            now: now),
        '3d ago',
      );
      expect(
        Formatters.timeAgoLabel(DateTime(2026, 8, 1, 9, 0), now: now),
        '1 Aug',
      );
      expect(
        Formatters.timeAgoLabel(DateTime(2025, 12, 25, 9, 0), now: now),
        '25 Dec 2025',
      );
    });
  });

  testWidgets('guests see the sign-in prompt', (tester) async {
    final bundle = await _buildApp(authenticated: false);
    await tester.pumpWidget(bundle.app);
    await tester.pumpAndSettle();

    expect(bundle.adapter.getCalls, 1);
    expect(find.text('Sign in to see your notifications.'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('shows the loading state while the request is in flight', (
    tester,
  ) async {
    final bundle = await _buildApp(
      authenticated: true,
      notifications: [_notification(id: 'n_1', title: 'Ready')],
      responseDelay: const Duration(seconds: 2),
    );
    await tester.pumpWidget(bundle.app);
    await tester.pump();

    expect(find.text('Loading notifications…'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Loading notifications…'), findsNothing);
    expect(find.text('Ready'), findsOneWidget);
  });

  testWidgets('API error shows the error state and Retry recovers', (
    tester,
  ) async {
    final bundle = await _buildApp(
      authenticated: true,
      notifications: [
        _notification(id: 'n_1', title: 'Slot confirmed'),
      ],
      failNext: 1,
    );
    await tester.pumpWidget(bundle.app);
    await tester.pumpAndSettle();

    expect(find.text('Failed to load notifications'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Slot confirmed'), findsOneWidget);
  });

  testWidgets('empty inbox shows the empty state', (tester) async {
    final bundle = await _buildApp(authenticated: true);
    await tester.pumpWidget(bundle.app);
    await tester.pumpAndSettle();

    expect(find.text('No notifications yet.'), findsOneWidget);
    expect(find.text('Mark all'), findsNothing);
  });

  testWidgets('renders titles, bodies, relative time and read state', (
    tester,
  ) async {
    final bundle = await _buildApp(
      authenticated: true,
      notifications: [
        _notification(id: 'n_1', title: 'Booking confirmed', isRead: false),
        _notification(
          id: 'n_2',
          title: 'Order shipped',
          body: 'Your helmet is on the way to you',
          type: 'order',
          isRead: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ],
    );
    await tester.pumpWidget(bundle.app);
    await tester.pumpAndSettle();

    expect(find.text('Booking confirmed'), findsOneWidget);
    expect(find.text('Order shipped'), findsOneWidget);
    expect(
      find.text('Your helmet is on the way to you'),
      findsOneWidget,
    );
    // Unread rows are bold, read rows are regular.
    final unreadTitle =
        tester.widget<Text>(find.text('Booking confirmed'));
    final readTitle = tester.widget<Text>(find.text('Order shipped'));
    expect(unreadTitle.style?.fontWeight, FontWeight.w700);
    expect(readTitle.style?.fontWeight, FontWeight.w400);
    // Relative timestamps render next to each title.
    expect(find.text('5m ago'), findsOneWidget);
    expect(find.text('2h ago'), findsOneWidget);
  });

  testWidgets('tapping an unread notification marks it read', (tester) async {
    final bundle = await _buildApp(
      authenticated: true,
      notifications: [
        _notification(id: 'n_1', title: 'Booking confirmed'),
        _notification(id: 'n_2', title: 'Coupon added', isRead: true),
      ],
    );
    await tester.pumpWidget(bundle.app);
    await tester.pumpAndSettle();

    expect(find.text('Mark all'), findsOneWidget);

    await tester.tap(find.text('Booking confirmed'));
    await tester.pumpAndSettle();

    expect(bundle.adapter.singleReadCalls, ['n_1']);
    expect(find.text('Close'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    // Everything is now read, so the "Mark all" action disappears and the
    // title loses its bold weight.
    expect(find.text('Mark all'), findsNothing);
    final title = tester.widget<Text>(find.text('Booking confirmed'));
    expect(title.style?.fontWeight, FontWeight.w400);
  });

  testWidgets('mark all read calls the endpoint and clears unread state', (
    tester,
  ) async {
    final bundle = await _buildApp(
      authenticated: true,
      notifications: [
        _notification(id: 'n_1', title: 'Booking confirmed'),
        _notification(id: 'n_2', title: 'Order shipped', isRead: false),
      ],
    );
    await tester.pumpWidget(bundle.app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mark all'));
    await tester.pumpAndSettle();

    expect(bundle.adapter.readAllCalls, ['read-all']);
    expect(find.text('Mark all'), findsNothing);
  });

  testWidgets('pull to refresh reloads the inbox', (tester) async {
    final bundle = await _buildApp(
      authenticated: true,
      notifications: [
        _notification(id: 'n_1', title: 'First update'),
      ],
    );
    await tester.pumpWidget(bundle.app);
    await tester.pumpAndSettle();

    expect(find.text('First update'), findsOneWidget);

    bundle.adapter.notifications = [
      _notification(id: 'n_1', title: 'First update'),
      _notification(id: 'n_2', title: 'Second update'),
    ];
    await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    expect(bundle.adapter.getCalls, 2);
    expect(find.text('Second update'), findsOneWidget);
  });

  group('no overflow', () {
    for (final width in [320.0, 360.0, 390.0, 430.0]) {
      for (final textScale in [1.0, 1.3, 2.0]) {
        testWidgets(
            'notification list at ${width}px width, ${textScale}x text',
            (tester) async {
          _setViewport(
            tester,
            width: width,
            height: 844,
            textScale: textScale,
          );
          final bundle = await _buildApp(
            authenticated: true,
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
              reason: 'overflow in the initial notifications viewport');

          await tester.drag(find.byType(ListView), const Offset(0, -3000));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: 'overflow after scrolling the notifications list');
        });
      }
    }

    for (final textScale in [1.0, 1.3, 2.0]) {
      testWidgets(
          'notification list on a Pixel 7 Pro at ${textScale}x text',
          (tester) async {
        _setViewport(
          tester,
          width: 412,
          height: 915,
          textScale: textScale,
        );
        final bundle = await _buildApp(
          authenticated: true,
          notifications: [
            _notification(
              id: 'n_1',
              title: 'Booking confirmed for Saturday',
              isRead: false,
            ),
            _notification(
              id: 'n_2',
              title: 'Payment received',
              type: 'payment',
              isRead: true,
            ),
          ],
        );
        await tester.pumpWidget(bundle.app);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(ListView), const Offset(0, -1500));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('empty state at 320px width, 2.0x text', (tester) async {
      _setViewport(tester, width: 320, height: 568, textScale: 2.0);
      final bundle = await _buildApp(authenticated: true);
      await tester.pumpWidget(bundle.app);
      await tester.pumpAndSettle();

      expect(find.text('No notifications yet.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('guest state at 320px width, 2.0x text', (tester) async {
      _setViewport(tester, width: 320, height: 568, textScale: 2.0);
      final bundle = await _buildApp(authenticated: false);
      await tester.pumpWidget(bundle.app);
      await tester.pumpAndSettle();

      expect(find.text('Sign in to see your notifications.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('error state at 320px width, 2.0x text', (tester) async {
      _setViewport(tester, width: 320, height: 568, textScale: 2.0);
      final bundle = await _buildApp(authenticated: true, failNext: 1);
      await tester.pumpWidget(bundle.app);
      await tester.pumpAndSettle();

      expect(find.text('Failed to load notifications'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}