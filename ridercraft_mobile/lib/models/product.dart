/// Product variant (colour option with its own images and stock).
class ProductVariant {
  final String id;
  final String color;
  final String colorHex;
  final List<String> images;
  final int stock;
  final String sku;

  const ProductVariant({
    this.id = '',
    this.color = '',
    this.colorHex = '#111827',
    this.images = const [],
    this.stock = 0,
    this.sku = '',
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
        id: (json['_id'] ?? '') as String,
        color: (json['color'] ?? '') as String,
        colorHex: (json['colorHex'] ?? '#111827') as String,
        images: (json['images'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
        stock: ((json['stock'] ?? 0) as num).toInt(),
        sku: (json['sku'] ?? '') as String,
      );
}

/// Product serialized by the backend through `productToClient`.
///
/// The API always returns `displayPrice`, `originalPrice` and
/// `discountPercent` computed server-side, so the app never trusts the client
/// for pricing.
class Product {
  final String id;
  final String name;
  final String tag;
  final String brand;
  final String colorFamily;
  final int stock;
  final String image;
  final String description;
  final List<String> sizes;
  final List<String> colors;
  final List<ProductVariant> variants;

  final double price;
  final double displayPrice;
  final double originalPrice;
  final int discountPercent;

  final bool isFlashSale;
  final bool isFlashSaleActive;
  final double flashSalePrice;
  final String? flashSaleEndsAt;
  final bool isFeatured;
  final bool isFeaturedActive;

  final double ratingAverage;
  final int ratingCount;

  const Product({
    required this.id,
    required this.name,
    this.tag = 'General',
    this.brand = 'Generic',
    this.colorFamily = 'Neutral',
    this.stock = 0,
    this.image = '',
    this.description = '',
    this.sizes = const [],
    this.colors = const [],
    this.variants = const [],
    this.price = 0,
    this.displayPrice = 0,
    this.originalPrice = 0,
    this.discountPercent = 0,
    this.isFlashSale = false,
    this.isFlashSaleActive = false,
    this.flashSalePrice = 0,
    this.flashSaleEndsAt,
    this.isFeatured = false,
    this.isFeaturedActive = false,
    this.ratingAverage = 0,
    this.ratingCount = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final displayPrice =
        ((json['displayPrice'] ?? json['price'] ?? 0) as num).toDouble();
    final originalPrice =
        ((json['originalPrice'] ?? json['price'] ?? displayPrice) as num)
            .toDouble();

    return Product(
      id: (json['_id'] ?? json['id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      tag: (json['tag'] ?? 'General') as String,
      brand: (json['brand'] ?? 'Generic') as String,
      colorFamily: (json['colorFamily'] ?? 'Neutral') as String,
      stock: ((json['stock'] ?? 0) as num).toInt(),
      image: (json['image'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      sizes: (json['sizes'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      colors: (json['colors'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      variants: (json['variants'] as List?)
              ?.map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      price: ((json['price'] ?? 0) as num).toDouble(),
      displayPrice: displayPrice,
      originalPrice: originalPrice,
      discountPercent: ((json['discountPercent'] ?? 0) as num).toInt(),
      isFlashSale: (json['isFlashSale'] ?? false) as bool,
      isFlashSaleActive: (json['isFlashSaleActive'] ?? false) as bool,
      flashSalePrice: ((json['flashSalePrice'] ?? 0) as num).toDouble(),
      flashSaleEndsAt: json['flashSaleEndsAt'] as String?,
      isFeatured: (json['isFeatured'] ?? false) as bool,
      isFeaturedActive: (json['isFeaturedActive'] ?? false) as bool,
      ratingAverage: ((json['ratingAverage'] ?? 0) as num).toDouble(),
      ratingCount: ((json['ratingCount'] ?? 0) as num).toInt(),
    );
  }

  bool get inStock => stock > 0;

  /// Concatenated gallery: product image first, then variant images.
  List<String> get gallery {
    final images = <String>[];
    if (image.isNotEmpty) images.add(image);
    for (final variant in variants) {
      for (final variantImage in variant.images) {
        if (!images.contains(variantImage)) images.add(variantImage);
      }
    }
    return images;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'displayPrice': displayPrice,
        'stock': stock,
        'image': image,
      };
}
