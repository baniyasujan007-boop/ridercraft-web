import 'package:flutter/foundation.dart';

import '../models/featured_section.dart';
import '../models/hero_offer.dart';
import '../models/product.dart';
import '../models/wishlist_entry.dart';
import '../services/product_service.dart';

/// Catalogue state: products, featured sections, hero offers and wishlist.
/// Search is a client-side filter over the already-loaded catalogue (the
/// backend has no search endpoint yet).
class ProductProvider extends ChangeNotifier {
  final ProductService _service;

  List<Product> _products = [];
  List<FeaturedSection> _featuredSections = [];
  List<HeroOffer> _heroOffers = [];
  List<WishlistEntry> _wishlist = [];

  bool _loadingProducts = false;
  bool _loadingHome = false;
  bool _loadingWishlist = false;
  String? _error;

  ProductProvider(this._service);

  List<Product> get products => List.unmodifiable(_products);
  List<FeaturedSection> get featuredSections =>
      List.unmodifiable(_featuredSections);
  List<HeroOffer> get heroOffers => List.unmodifiable(_heroOffers);
  List<WishlistEntry> get wishlist => List.unmodifiable(_wishlist);

  bool get loadingProducts => _loadingProducts;
  bool get loadingHome => _loadingHome;
  bool get loadingWishlist => _loadingWishlist;
  String? get error => _error;

  Set<String> get wishlistProductIds =>
      _wishlist.map((e) => e.productId).toSet();

  bool isInWishlist(String productId) => wishlistProductIds.contains(productId);

  Future<void> loadHome() async {
    _loadingHome = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.listHeroOffers(),
        _service.listFeaturedSections(),
      ]);
      _heroOffers = results[0] as List<HeroOffer>;
      _featuredSections = results[1] as List<FeaturedSection>;
    } catch (error) {
      _error = error.toString();
    } finally {
      _loadingHome = false;
      notifyListeners();
    }
  }

  Future<void> loadProducts() async {
    _loadingProducts = true;
    _error = null;
    notifyListeners();
    try {
      _products = _dedupeById(await _service.listProducts());
    } catch (error) {
      _error = error.toString();
    } finally {
      _loadingProducts = false;
      notifyListeners();
    }
  }

  Future<void> loadWishlist() async {
    _loadingWishlist = true;
    notifyListeners();
    try {
      _wishlist = await _service.listWishlist();
    } catch (_) {
      // Wishlist is optional; keep whatever we have.
    } finally {
      _loadingWishlist = false;
      notifyListeners();
    }
  }

  /// Toggles a product in the wishlist.
  ///
  /// Returns the new state (true = added). Errors are NOT swallowed so the UI
  /// can distinguish an auth failure (401) from a network failure.
  Future<bool> toggleWishlist(Product product) async {
    if (isInWishlist(product.id)) {
      final entry = _wishlist.firstWhere((e) => e.productId == product.id);
      await _service.removeFromWishlist(entry.id);
      _wishlist.removeWhere((e) => e.productId == product.id);
      notifyListeners();
      return false;
    }
    final added = await _service.addToWishlist(product.id);
    _wishlist.insert(0, added);
    notifyListeners();
    return true;
  }

  /// Client-side search across the loaded catalogue.
  List<Product> search(String query) {
    final term = query.trim().toLowerCase();
    if (term.isEmpty) return [];
    return _products
        .where((product) =>
            product.name.toLowerCase().contains(term) ||
            product.tag.toLowerCase().contains(term) ||
            product.brand.toLowerCase().contains(term) ||
            product.colorFamily.toLowerCase().contains(term))
        .toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Collapses duplicate product ids so the same product can never render
  /// twice in one subtree (two [Hero] widgets with an identical tag would
  /// throw "multiple heroes that share the same tag within a subtree").
  static List<Product> _dedupeById(List<Product> products) {
    final seen = <String>{};
    final result = <Product>[];
    for (final product in products) {
      if (seen.add(product.id)) result.add(product);
    }
    return result;
  }
}
