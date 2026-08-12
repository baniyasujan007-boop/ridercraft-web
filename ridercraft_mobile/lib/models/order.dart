/// A single line item inside an order. Matches the backend `orderItemSchema`.
class OrderItem {
  final String productId;
  final String variantId;
  final String variantSku;
  final String color;
  final String colorHex;
  final String size;
  final String name;
  final double price;
  final int qty;
  final String image;

  const OrderItem({
    required this.productId,
    this.variantId = '',
    this.variantSku = '',
    this.color = '',
    this.colorHex = '',
    this.size = '',
    required this.name,
    required this.price,
    required this.qty,
    this.image = '',
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    productId: (json['productId'] ?? '') as String,
    variantId: (json['variantId'] ?? '') as String,
    variantSku: (json['variantSku'] ?? '') as String,
    color: (json['color'] ?? '') as String,
    colorHex: (json['colorHex'] ?? '') as String,
    size: (json['size'] ?? '') as String,
    name: (json['name'] ?? '') as String,
    price: ((json['price'] ?? 0) as num).toDouble(),
    qty: ((json['qty'] ?? 0) as num).toInt(),
    image: (json['image'] ?? '') as String,
  );

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'variantId': variantId,
    'variantSku': variantSku,
    'color': color,
    'colorHex': colorHex,
    'size': size,
    'name': name,
    'price': price,
    'qty': qty,
    'image': image,
  };
}

/// Order document returned by `POST /orders` and `GET /orders/my`.
class Order {
  final String id;
  final List<OrderItem> items;
  final double subtotal;
  final double tax;
  final double shipping;
  final double discount;
  final double total;
  final String promoCode;
  final String paymentMethod;
  final String paymentStatus;
  final String paymentReference;
  final String status;
  final String deliveryAddress;
  final String contactNumber;
  final DateTime? createdAt;

  const Order({
    required this.id,
    this.items = const [],
    this.subtotal = 0,
    this.tax = 0,
    this.shipping = 0,
    this.discount = 0,
    this.total = 0,
    this.promoCode = '',
    this.paymentMethod = 'cod',
    this.paymentStatus = 'pending',
    this.paymentReference = '',
    this.status = 'placed',
    this.deliveryAddress = '',
    this.contactNumber = '',
    this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: (json['_id'] ?? json['id'] ?? '') as String,
    items:
        (json['items'] as List?)
            ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    subtotal: ((json['subtotal'] ?? 0) as num).toDouble(),
    tax: ((json['tax'] ?? 0) as num).toDouble(),
    shipping: ((json['shipping'] ?? 0) as num).toDouble(),
    discount: ((json['discount'] ?? 0) as num).toDouble(),
    total: ((json['total'] ?? 0) as num).toDouble(),
    promoCode: (json['promoCode'] ?? '') as String,
    paymentMethod: (json['paymentMethod'] ?? 'cod') as String,
    paymentStatus: (json['paymentStatus'] ?? 'pending') as String,
    paymentReference: (json['paymentReference'] ?? '') as String,
    status: (json['status'] ?? 'placed') as String,
    deliveryAddress: (json['deliveryAddress'] ?? '') as String,
    contactNumber: (json['contactNumber'] ?? '') as String,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String)
        : null,
  );

  /// Backend order statuses: placed, processing, shipped, delivered.
  String get statusLabel => switch (status) {
    'processing' => 'Processing',
    'shipped' => 'Shipped',
    'delivered' => 'Delivered',
    _ => 'Placed',
  };

  /// Backend payment statuses: pending, paid, refunded.
  String get paymentLabel => switch (paymentStatus) {
    'paid' => 'Paid',
    'refunded' => 'Refunded',
    _ => 'Pending',
  };
}
