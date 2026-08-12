import 'product.dart';

/// Wishlist entry from `GET /wishlist`. The backend populates the product.
class WishlistEntry {
  final String id;
  final String productId;
  final Product? product;
  final DateTime? createdAt;

  const WishlistEntry({
    required this.id,
    required this.productId,
    this.product,
    this.createdAt,
  });

  factory WishlistEntry.fromJson(Map<String, dynamic> json) => WishlistEntry(
        id: (json['_id'] ?? '') as String,
        productId: (json['productId'] ?? '') as String,
        product: json['product'] is Map<String, dynamic>
            ? Product.fromJson(json['product'] as Map<String, dynamic>)
            : null,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );
}
