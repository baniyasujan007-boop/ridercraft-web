import '../models/featured_section.dart';
import '../models/hero_offer.dart';
import '../models/product.dart';
import '../models/wishlist_entry.dart';
import 'api_client.dart';

/// Product, catalogue, hero-offer and wishlist endpoints.
///
/// Endpoints:
/// - GET  /products
/// - GET  /products/:id
/// - POST /products/:id/rate  {rating, comment?}
/// - GET  /hero-offers
/// - GET  /featured-sections
/// - GET  /wishlist
/// - POST /wishlist/add
/// - DELETE /wishlist/remove/:id
class ProductService {
  final ApiClient _api;

  ProductService(this._api);

  Future<List<Product>> listProducts() async {
    final data = await _api.get('/products');
    return _parseList(data, Product.fromJson);
  }

  Future<Product> getProduct(String id) async {
    final data = await _api.get('/products/$id');
    return Product.fromJson(data as Map<String, dynamic>);
  }

  Future<Product> rateProduct({
    required String id,
    required double rating,
    String comment = '',
  }) async {
    final data = await _api.post(
      '/products/$id/rate',
      data: {'rating': rating, 'comment': comment},
    );
    final product = (data as Map<String, dynamic>)['product'] ?? data;
    return Product.fromJson(product as Map<String, dynamic>);
  }

  Future<List<HeroOffer>> listHeroOffers() async {
    final data = await _api.get('/hero-offers');
    return _parseList(data, HeroOffer.fromJson);
  }

  Future<List<FeaturedSection>> listFeaturedSections() async {
    final data = await _api.get('/featured-sections');
    return _parseList(data, FeaturedSection.fromJson);
  }

  Future<List<WishlistEntry>> listWishlist() async {
    final data = await _api.get('/wishlist');
    return _parseList(data, WishlistEntry.fromJson);
  }

  Future<WishlistEntry> addToWishlist(String productId) async {
    final data = await _api.post('/wishlist/add', data: {'productId': productId});
    return WishlistEntry.fromJson(data as Map<String, dynamic>);
  }

  Future<void> removeFromWishlist(String id) async {
    await _api.delete('/wishlist/remove/$id');
  }

  static List<T> _parseList<T>(
    dynamic data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (data is! List) return <T>[];
    return data
        .map((item) => fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
