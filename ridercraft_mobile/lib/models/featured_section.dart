import 'product.dart';

/// Featured product section from `GET /featured-sections`.
///
/// Keys: flash-sale, trending, new-arrivals, best-sellers, recommended.
class FeaturedSection {
  final String id;
  final String key;
  final String title;
  final List<Product> products;
  final DateTime? countdownStartsAt;
  final DateTime? countdownEndsAt;
  final bool isActive;

  const FeaturedSection({
    required this.id,
    required this.key,
    required this.title,
    this.products = const [],
    this.countdownStartsAt,
    this.countdownEndsAt,
    this.isActive = true,
  });

  factory FeaturedSection.fromJson(Map<String, dynamic> json) =>
      FeaturedSection(
        id: (json['_id'] ?? '') as String,
        key: (json['key'] ?? '') as String,
        title: (json['title'] ?? '') as String,
        products: (json['products'] as List?)
                ?.map((e) => Product.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        countdownStartsAt: json['countdownStartsAt'] != null
            ? DateTime.tryParse(json['countdownStartsAt'] as String)
            : null,
        countdownEndsAt: json['countdownEndsAt'] != null
            ? DateTime.tryParse(json['countdownEndsAt'] as String)
            : null,
        isActive: (json['isActive'] ?? true) as bool,
      );
}
