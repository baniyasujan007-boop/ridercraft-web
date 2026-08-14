import '../models/cart_item.dart';
import '../models/order.dart';
import 'api_client.dart';

/// Order endpoints against the existing backend.
///
/// - POST /orders    (auth) create order
/// - GET  /orders/my (auth) list my orders
///
/// Prices are always derived from server-returned product prices
/// ([CartItem.unitPrice] comes from [Product.displayPrice]). The backend
/// remains the authority; the app only assembles the payload.
class OrderService {
  final ApiClient _api;

  OrderService(this._api);

  Future<List<Order>> listMyOrders() async {
    final data = await _api.get('/orders/my');
    if (data is! List) return <Order>[];
    return data
        .map((item) => Order.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Creates an order. The backend only accepts card/ewallet as explicit
  /// DEMO payments (`isDummy: true`) and never marks them paid — only an
  /// admin can reconcile a payment. COD is the production path.
  Future<Order> createOrder({
    required List<CartItem> items,
    required double subtotal,
    required double tax,
    required double shipping,
    required double discount,
    required double total,
    required String promoCode,
    required String paymentMethod,
    Map<String, dynamic>? paymentDetails,
  }) async {
    final data = await _api.post(
      '/orders',
      data: {
        'items': items
            .map(
              (item) => {
                'productId': item.product.id,
                'variantId': item.variantId,
                'variantSku': item.variantSku,
                'color': item.color,
                'colorHex': item.colorHex,
                'size': item.size,
                'name': item.product.name,
                'price': item.unitPrice,
                'qty': item.quantity,
                'image': item.product.image,
              },
            )
            .toList(),
        'subtotal': subtotal,
        'tax': tax,
        'shipping': shipping,
        'discount': discount,
        'total': total,
        'promoCode': promoCode,
        'paymentMethod': paymentMethod,
        'paymentDetails': paymentDetails ?? {},
      },
    );
    return Order.fromJson(data as Map<String, dynamic>);
  }
}
