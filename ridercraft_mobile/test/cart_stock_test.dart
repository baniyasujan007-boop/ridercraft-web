import 'package:flutter_test/flutter_test.dart';

import 'package:ridercraft_mobile/models/cart_item.dart';
import 'package:ridercraft_mobile/models/product.dart';
import 'package:ridercraft_mobile/screens/cart/widgets/stock_status.dart';

Product _product({
  int v1Stock = 5,
  int v2Stock = 0,
  int productStock = 10,
}) => Product.fromJson({
      '_id': 'p1',
      'name': 'Riding Jacket',
      'price': 4999,
      'displayPrice': 4999,
      'originalPrice': 4999,
      'stock': productStock,
      'image': '',
      'brand': 'RiderCraft',
      'tag': 'Riding Gear',
      'colorFamily': 'Neutral',
      'colors': ['Black', 'Red'],
      'sizes': ['M', 'L'],
      'variants': [
        {
          '_id': 'v1',
          'color': 'Black',
          'colorHex': '#111827',
          'images': <String>[],
          'stock': v1Stock,
          'sku': 'RC-BLK',
        },
        {
          '_id': 'v2',
          'color': 'Red',
          'colorHex': '#DC2626',
          'images': <String>[],
          'stock': v2Stock,
          'sku': 'RC-RED',
        },
      ],
    });

void main() {
  test('in-stock line resolves to inStock and caps at available stock', () {
    final product = _product(v1Stock: 5);
    final item = CartItem(
      product: product,
      variantId: 'v1',
      quantity: 2,
    );
    final result = resolveCartStock(item);
    expect(result.status, CartStockStatus.inStock);
    expect(result.maxQuantity, 5);
    expect(result.message, contains('In stock'));
  });

  test('line matching a zero-stock variant is out-of-stock and disabled', () {
    final product = _product(v2Stock: 0);
    final result = resolveCartStock(
      CartItem(product: product, variantId: 'v2', quantity: 1),
    );
    expect(result.status, CartStockStatus.outOfStock);
    expect(result.maxQuantity, 0);
    expect(result.message, 'Out of stock');
  });

  test('quantity above available stock is exceeds-stock', () {
    final product = _product(v1Stock: 3);
    final result = resolveCartStock(
      CartItem(product: product, variantId: 'v1', quantity: 5),
    );
    expect(result.status, CartStockStatus.exceedsStock);
    expect(result.maxQuantity, 3);
    expect(result.message, contains('reduce quantity'));
  });

  test('variant that no longer exists is unavailable with quantity blocked', () {
    final product = _product(v1Stock: 5);
    final result = resolveCartStock(
      CartItem(product: product, variantId: 'ghost', quantity: 1),
    );
    expect(result.status, CartStockStatus.unavailable);
    expect(result.maxQuantity, 0);
    expect(result.message, contains('no longer available'));
  });

  test('plain product stock is used when there is no selected variant', () {
    final product = _product(productStock: 0);
    final result = resolveCartStock(CartItem(product: product, quantity: 1));
    expect(result.status, CartStockStatus.outOfStock);
    expect(result.maxQuantity, 0);
  });

  test('stock above the provider ceiling is capped at 99', () {
    final product = _product(v1Stock: 500);
    final result = resolveCartStock(
      CartItem(product: product, variantId: 'v1', quantity: 1),
    );
    expect(result.status, CartStockStatus.inStock);
    expect(result.maxQuantity, 99);
  });
}