import 'product.dart';

/// A product in the local shopping cart.
///
/// The cart lives on the device only (the backend has no cart endpoint);
/// prices always come from the product fetched from the API so the client
/// never dictates amounts.
class CartItem {
  final Product product;
  final String variantId;
  final String variantSku;
  final String color;
  final String colorHex;
  final String size;
  final int quantity;

  const CartItem({
    required this.product,
    this.variantId = '',
    this.variantSku = '',
    this.color = '',
    this.colorHex = '',
    this.size = '',
    this.quantity = 1,
  });

  /// Unit price at the moment it was added, from the server-returned
  /// display price.
  double get unitPrice => product.displayPrice;

  double get lineTotal => unitPrice * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
        product: product,
        variantId: variantId,
        variantSku: variantSku,
        color: color,
        colorHex: colorHex,
        size: size,
        quantity: quantity ?? this.quantity,
      );
}
