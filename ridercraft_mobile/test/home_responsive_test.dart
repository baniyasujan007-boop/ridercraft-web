// Renders the Home dashboard at several phone widths and text-scaler values
// with realistic (long) API payloads, and verifies no RenderFlex / pixel
// overflow is reported — including while scrolling to the bottom of the feed.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ridercraft_mobile/models/featured_section.dart';
import 'package:ridercraft_mobile/models/hero_offer.dart';
import 'package:ridercraft_mobile/models/product.dart';
import 'package:ridercraft_mobile/models/promo.dart';
import 'package:ridercraft_mobile/providers/auth_provider.dart';
import 'package:ridercraft_mobile/providers/home_provider.dart';
import 'package:ridercraft_mobile/providers/product_provider.dart';
import 'package:ridercraft_mobile/screens/home/home_screen.dart';
import 'package:ridercraft_mobile/services/api_client.dart';
import 'package:ridercraft_mobile/services/auth_service.dart';
import 'package:ridercraft_mobile/services/product_service.dart';
import 'package:ridercraft_mobile/services/promo_service.dart';
import 'package:ridercraft_mobile/services/storage_service.dart';
import 'package:ridercraft_mobile/services/token_store.dart';
import 'package:ridercraft_mobile/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeProductService extends ProductService {
  _FakeProductService({required this.heroOffers, required this.sections})
      : super(ApiClient());

  final List<HeroOffer> heroOffers;
  final List<FeaturedSection> sections;

  @override
  Future<List<HeroOffer>> listHeroOffers() async => heroOffers;

  @override
  Future<List<FeaturedSection>> listFeaturedSections() async => sections;
}

class _FakePromoService extends PromoService {
  _FakePromoService({required this.promos}) : super(ApiClient());

  final List<Promo> promos;

  @override
  Future<List<Promo>> listActivePromos() async => promos;
}

HeroOffer _offer(String id, String title, String type) => HeroOffer(
      id: id,
      title: title,
      offerType: type,
      ctaQuery: 'Helmet + gloves bundle across all riding gear',
      remainingSeconds: 3600,
    );

Product _product(int i) => Product(
      id: 'p$i',
      name:
          'Premium Full-Face Motorcycle Helmet with Bluetooth Module and Sun Visor $i',
      brand: 'RIDERCRAFT',
      tag: 'Helmet',
      displayPrice: 12499 + i * 1000,
      originalPrice: 18999 + i * 1000,
      discountPercent: 34,
      ratingAverage: 4.7,
      ratingCount: 1234,
      stock: 10,
    );

Future<void> _pumpHome(
  WidgetTester tester, {
  required double width,
  required double textScale,
  required List<HeroOffer> offers,
  required List<FeaturedSection> sections,
  required List<Promo> promos,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final authProvider = AuthProvider(
    AuthService(ApiClient(), StorageService(prefs)),
    TokenStore(),
  );
  final productService =
      _FakeProductService(heroOffers: offers, sections: sections);
  final homeProvider =
      HomeProvider(productService, _FakePromoService(promos: promos));
  // Load before mounting so `HomeProvider.load()` early-returns from
  // `didChangeDependencies` instead of notifying during the build phase.
  await homeProvider.load();
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: Size(width, 844),
        textScaler: TextScaler.linear(textScale),
      ),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => homeProvider),
          ChangeNotifierProvider(create: (_) => ProductProvider(productService)),
          ChangeNotifierProvider(create: (_) => authProvider),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          home: HomeScreen(onNavigateTab: (_) {}),
        ),
      ),
    ),
  );
  // Let the async home load finish and the real content replace the skeleton.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _expectNoOverflow(WidgetTester tester) async {
  // Initial viewport.
  expect(tester.takeException(), isNull,
      reason: 'overflow in the initial viewport');
  // Scroll to the bottom of the feed so every row is laid out.
  await tester.drag(find.byType(RefreshIndicator), const Offset(0, -900));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  expect(tester.takeException(), isNull,
      reason: 'overflow after scrolling to the bottom');
}

void main() {
  final sections = [
    FeaturedSection(
      id: 's1',
      key: 'trending',
      title: 'Trending Now',
      products: [_product(1), _product(2), _product(3)],
    ),
  ];
  final promos = [Promo(id: 'pr1', code: 'MONSOON25', discountValue: 25)];

  for (final width in [320.0, 360.0, 390.0, 430.0]) {
    for (final textScale in [1.0, 1.3, 2.0]) {
      testWidgets(
          'Home renders offers at ${width}px, ${textScale}x text without overflow',
          (tester) async {
        await _pumpHome(
          tester,
          width: width,
          textScale: textScale,
          offers: [
            _offer('h1', 'Flash Sale: Get the season\'s best riding gear', 'flash'),
            _offer('h2', 'Extended monsoon service camp', 'sale'),
          ],
          sections: sections,
          promos: promos,
        );
        await _expectNoOverflow(tester);
      });
    }
  }

  for (final width in [320.0, 390.0, 430.0]) {
    for (final textScale in [1.0, 2.0]) {
      testWidgets(
          'Home branded hero (no offers) renders at ${width}px, ${textScale}x text',
          (tester) async {
        await _pumpHome(
          tester,
          width: width,
          textScale: textScale,
          offers: const [],
          sections: sections,
          promos: promos,
        );
        await _expectNoOverflow(tester);
      });
    }
  }
}
