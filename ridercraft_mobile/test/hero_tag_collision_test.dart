import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridercraft_mobile/models/featured_section.dart';
import 'package:ridercraft_mobile/models/hero_offer.dart';
import 'package:ridercraft_mobile/models/product.dart';
import 'package:ridercraft_mobile/models/promo.dart';
import 'package:ridercraft_mobile/providers/auth_provider.dart';
import 'package:ridercraft_mobile/providers/cart_provider.dart';
import 'package:ridercraft_mobile/providers/home_provider.dart';
import 'package:ridercraft_mobile/providers/product_provider.dart';
import 'package:ridercraft_mobile/screens/home/home_screen.dart';
import 'package:ridercraft_mobile/screens/shop/shop_screen.dart';
import 'package:ridercraft_mobile/services/api_client.dart';
import 'package:ridercraft_mobile/services/auth_service.dart';
import 'package:ridercraft_mobile/services/product_service.dart';
import 'package:ridercraft_mobile/services/promo_service.dart';
import 'package:ridercraft_mobile/services/storage_service.dart';
import 'package:ridercraft_mobile/services/token_store.dart';
import 'package:ridercraft_mobile/theme/app_theme.dart';

// Every product card and the product detail gallery share the exact same Hero
// tag (`product-hero-<id>`). If the same product is ever rendered twice in one
// route subtree — e.g. placed in two featured sections on Home, or duplicated
// in the catalogue — Flutter throws "There are multiple heroes that share the
// same tag within a subtree". These tests pin the dedupe that prevents that.

Product _product(String id, {String tag = 'Helmets'}) => Product(
      id: id,
      name: 'Helmet $id',
      brand: 'RIDERCRAFT',
      tag: tag,
      displayPrice: 12999,
      originalPrice: 17999,
      discountPercent: 28,
      ratingAverage: 4.6,
      ratingCount: 120,
      stock: 10,
    );

class _FakeProductService extends ProductService {
  _FakeProductService({
    required this.heroOffers,
    required this.sections,
    required this.catalogue,
  }) : super(ApiClient());

  final List<HeroOffer> heroOffers;
  final List<FeaturedSection> sections;
  final List<Product> catalogue;

  @override
  Future<List<HeroOffer>> listHeroOffers() async => heroOffers;

  @override
  Future<List<FeaturedSection>> listFeaturedSections() async => sections;

  @override
  Future<List<Product>> listProducts() async => catalogue;
}

class _FakePromoService extends PromoService {
  _FakePromoService() : super(ApiClient());

  @override
  Future<List<Promo>> listActivePromos() async => const [];
}

void main() {
  group('catalogue dedupe (ProductProvider)', () {
    test('loadProducts drops duplicate product ids', () async {
      final service = _FakeProductService(
        heroOffers: const [],
        sections: const [],
        catalogue: [
          _product('p1'),
          _product('p2'),
          _product('p1'),
          _product('p3'),
          _product('p2'),
        ],
      );
      final provider = ProductProvider(service);
      await provider.loadProducts();

      expect(provider.products.map((p) => p.id).toList(), ['p1', 'p2', 'p3']);
    });
  });

  group('featured-section dedupe (HomeProvider)', () {
    test('a product appearing in two sections is kept only once', () async {
      final shared = _product('p2');
      final service = _FakeProductService(
        heroOffers: const [],
        sections: [
          FeaturedSection(
            id: 's1',
            key: 'trending',
            title: 'Trending',
            products: [_product('p1'), shared],
          ),
          FeaturedSection(
            id: 's2',
            key: 'new-arrivals',
            title: 'New Arrivals',
            products: [shared, _product('p3')],
          ),
        ],
        catalogue: const [],
      );
      final home = HomeProvider(service, _FakePromoService());
      await home.load();

      final ids = home.featuredSections
          .expand((section) => section.products)
          .map((p) => p.id)
          .toList();
      expect(ids.toSet().length, ids.length,
          reason: 'no product id may repeat across featured sections');
      expect(ids, ['p1', 'p2', 'p3']);
    });
  });

  group('render regression (no duplicate-Hero exception)', () {
    Future<void> pumpHome(
      WidgetTester tester, {
      required List<FeaturedSection> sections,
    }) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = _FakeProductService(
        heroOffers: const [],
        sections: sections,
        catalogue: const [],
      );
      final home = HomeProvider(service, _FakePromoService());
      final auth = AuthProvider(
        AuthService(ApiClient(), StorageService(prefs)),
        TokenStore(),
      );
      await home.load();
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(430, 1600),
            textScaler: TextScaler.linear(1.0),
          ),
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => home),
              ChangeNotifierProvider(create: (_) => ProductProvider(service)),
              ChangeNotifierProvider(create: (_) => auth),
            ],
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.dark,
              home: HomeScreen(onNavigateTab: (_) {}),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets(
        'Home renders the same product in two featured sections without a '
        'duplicate-Hero exception', (tester) async {
      final shared = _product('shared');
      await pumpHome(tester, sections: [
        FeaturedSection(
          id: 's1',
          key: 'trending',
          title: 'Trending Now',
          products: [shared, _product('b'), _product('c')],
        ),
        FeaturedSection(
          id: 's2',
          key: 'new-arrivals',
          title: 'New Arrivals',
          products: [
            shared,
            _product('d'),
          ],
        ),
      ]);

      // The shared product is the first card of BOTH rows, so both Hero
      // widgets with `product-hero-shared` must exist in the Home subtree.
      expect(tester.takeException(), isNull,
          reason: 'duplicate Hero tags must not be reported');
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, -900));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull,
          reason: 'no duplicate-Hero exception after scrolling Home');
    });

    testWidgets(
        'Shop renders a catalogue with duplicated ids without a '
        'duplicate-Hero exception', (tester) async {
      Map<String, dynamic> row(String id, String name) => {
            '_id': id,
            'name': name,
            'brand': 'Shoei',
            'tag': 'Helmets',
            'colorFamily': 'Neutral',
            'stock': 12,
            'image': '',
            'sizes': <String>[],
            'colors': <String>[],
            'variants': <Map<String, dynamic>>[],
            'price': 12999,
            'displayPrice': 12999,
            'originalPrice': 16899,
            'discountPercent': 23,
            'ratingAverage': 4.6,
            'ratingCount': 42,
          };

      // The API returns a duplicate `p2` entry; the provider must collapse it
      // so only one `product-hero-p2` card is in the grid subtree.
      final products = [row('p1', 'Helmet One'), row('p2', 'Helmet Two')];

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final tokenStore = TokenStore();
      final dio = Dio()..httpClientAdapter = _DupFakeAdapter(products);
      final api = ApiClient(
        tokenProvider: () => tokenStore.current,
        dio: dio,
      );

      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(430, 900);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => AuthProvider(
                AuthService(api, StorageService(prefs)),
                tokenStore,
              ),
            ),
            ChangeNotifierProvider(
              create: (_) => CartProvider(
                    StorageService(prefs),
                    PromoService(api),
                  )
                ..load(),
            ),
            ChangeNotifierProvider(
              create: (_) => ProductProvider(ProductService(api)),
            ),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            home: const ShopScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull,
          reason: 'duplicate catalogue ids must not produce duplicate Heroes');
      expect(find.text('Helmet One'), findsOneWidget);
      expect(find.text('Helmet Two'), findsOneWidget);
    });
  });
}

class _DupFakeAdapter implements HttpClientAdapter {
  _DupFakeAdapter(this.products);

  final List<Map<String, dynamic>> products;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final isProducts =
        options.path == '/products' || options.path.startsWith('/products?');
    final body = isProducts ? jsonEncode(products) : '[]';
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}