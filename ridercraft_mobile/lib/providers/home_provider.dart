import 'package:flutter/foundation.dart';

import '../models/featured_section.dart';
import '../models/hero_offer.dart';
import '../models/promo.dart';
import '../services/product_service.dart';
import '../services/promo_service.dart';

/// Home dashboard state: hero offers, featured sections and active promos.
///
/// Each dataset loads independently so a single failing API does not break the
/// rest of the screen (per-section error/retry).
class HomeProvider extends ChangeNotifier {
  final ProductService _productService;
  final PromoService _promoService;

  List<HeroOffer> _heroOffers = [];
  List<FeaturedSection> _featuredSections = [];
  List<Promo> _activePromos = [];

  bool _loadedOnce = false;
  bool _loadingAll = false;
  bool _loadingHero = false;
  bool _loadingFeatured = false;
  bool _loadingPromos = false;
  String? _heroError;
  String? _featuredError;
  String? _promoError;

  HomeProvider(this._productService, this._promoService);

  List<HeroOffer> get heroOffers => List.unmodifiable(_heroOffers);
  List<FeaturedSection> get featuredSections =>
      List.unmodifiable(_featuredSections);
  List<Promo> get activePromos => List.unmodifiable(_activePromos);

  /// True after the first full load attempt (success or failure).
  bool get loadedOnce => _loadedOnce;

  bool get loadingHero => _loadingHero;
  bool get loadingFeatured => _loadingFeatured;
  bool get loadingPromos => _loadingPromos;
  String? get heroError => _heroError;
  String? get featuredError => _featuredError;
  String? get promoError => _promoError;

  /// First load: shows the skeleton until all three sections resolve.
  ///
  /// Idempotent — the Home screen calls it defensively; concurrent or repeated
  /// calls while a load is already running are ignored.
  Future<void> load() async {
    if (_loadingAll || _loadedOnce) return;
    _loadingAll = true;
    _loadedOnce = false;
    await Future.wait([
      _loadHero(),
      _loadFeatured(),
      _loadPromos(),
    ]);
    _loadedOnce = true;
    _loadingAll = false;
    notifyListeners();
  }

  /// Pull-to-refresh: reloads all three sections in place.
  Future<void> refresh() async {
    await Future.wait([
      _loadHero(),
      _loadFeatured(),
      _loadPromos(),
    ]);
  }

  Future<void> retryHero() => _loadHero();
  Future<void> retryFeatured() => _loadFeatured();
  Future<void> retryPromos() => _loadPromos();

  Future<void> _loadHero() async {
    _loadingHero = true;
    _heroError = null;
    notifyListeners();
    try {
      _heroOffers = await _productService.listHeroOffers();
    } catch (error) {
      _heroError = error.toString();
    } finally {
      _loadingHero = false;
      notifyListeners();
    }
  }

  Future<void> _loadFeatured() async {
    _loadingFeatured = true;
    _featuredError = null;
    notifyListeners();
    try {
      _featuredSections = _dedupeAcrossSections(
        await _productService.listFeaturedSections(),
      );
    } catch (error) {
      _featuredError = error.toString();
    } finally {
      _loadingFeatured = false;
      notifyListeners();
    }
  }

  Future<void> _loadPromos() async {
    _loadingPromos = true;
    _promoError = null;
    notifyListeners();
    try {
      _activePromos = await _promoService.listActivePromos();
    } catch (error) {
      _promoError = error.toString();
    } finally {
      _loadingPromos = false;
      notifyListeners();
    }
  }

  /// A product may legitimately be placed in several featured sections
  /// (admin-curated content). Rendering it twice in one Home subtree would
  /// give two [Hero] widgets the same tag, which Flutter rejects. Keep the
  /// first occurrence of each product id across all sections.
  static List<FeaturedSection> _dedupeAcrossSections(
    List<FeaturedSection> sections,
  ) {
    final seen = <String>{};
    return [
      for (final section in sections)
        FeaturedSection(
          id: section.id,
          key: section.key,
          title: section.title,
          products: [
            for (final product in section.products)
              if (seen.add(product.id)) product,
          ],
          countdownStartsAt: section.countdownStartsAt,
          countdownEndsAt: section.countdownEndsAt,
          isActive: section.isActive,
        ),
    ];
  }
}
