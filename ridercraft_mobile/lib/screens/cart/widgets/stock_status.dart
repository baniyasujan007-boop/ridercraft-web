import '../../../models/cart_item.dart';
import '../../../models/product.dart';

/// UI availability of a cart line, derived from the product/variant stock
/// snapshot at render time.
///
/// This is presentation-only. The backend remains the sole authority for
/// stock validation when the order is placed — nothing here changes
/// [CartProvider] or the order payload.
enum CartStockStatus {
  inStock,
  outOfStock,
  exceedsStock,
  unavailable,
}

/// Resolved stock state for a cart line, with the friendly label to show and
/// the maximum quantity the stepper may reach (mirrors the provider's 1..99
/// clamp and never exceeds what is actually available).
class StockResolution {
  final CartStockStatus status;
  final String message;
  final int maxQuantity;

  const StockResolution({
    required this.status,
    required this.message,
    required this.maxQuantity,
  });
}

/// Resolves the current availability of a cart line from its product/variant
/// snapshot. The four states map to the existing stock semantics:
///
/// - in-stock:      quantity fits within available stock;
/// - out-of-stock:  the selected unit has zero stock;
/// - exceeds-stock: ordered more than is currently available;
/// - unavailable:   the selected variant/option no longer exists.
StockResolution resolveCartStock(CartItem item) {
  ProductVariant? variant;
  if (item.variantId.isNotEmpty) {
    for (final v in item.product.variants) {
      if (v.id == item.variantId) {
        variant = v;
        break;
      }
    }
    if (variant == null) {
      return const StockResolution(
        status: CartStockStatus.unavailable,
        message: 'This option is no longer available',
        maxQuantity: 0,
      );
    }
  }

  final stock = variant?.stock ?? item.product.stock;
  if (stock <= 0) {
    return const StockResolution(
      status: CartStockStatus.outOfStock,
      message: 'Out of stock',
      maxQuantity: 0,
    );
  }

  if (item.quantity > stock) {
    return StockResolution(
      status: CartStockStatus.exceedsStock,
      message: 'Only $stock available — reduce quantity',
      maxQuantity: stock > 99 ? 99 : stock,
    );
  }

  return StockResolution(
    status: CartStockStatus.inStock,
    message: stock == 1
        ? '1 in stock'
        : 'In stock · ${stock > 99 ? '99+' : stock} available',
    maxQuantity: stock > 99 ? 99 : stock,
  );
}