/// Public promo/coupon row returned by `GET /promos/active`.
class Promo {
  final String id;
  final String code;
  final String discountType;
  final double discountValue;
  final DateTime? endsAt;
  final String status;

  const Promo({
    required this.id,
    required this.code,
    this.discountType = 'percent',
    this.discountValue = 0,
    this.endsAt,
    this.status = 'active',
  });

  factory Promo.fromJson(Map<String, dynamic> json) => Promo(
        id: (json['_id'] ?? '') as String,
        code: (json['code'] ?? '') as String,
        discountType: (json['discountType'] ?? 'percent') as String,
        discountValue: ((json['discountValue'] ?? 0) as num).toDouble(),
        endsAt: json['endsAt'] != null
            ? DateTime.tryParse(json['endsAt'] as String)
            : null,
        status: (json['status'] ?? 'active') as String,
      );

  String get offerText => switch (discountType) {
        'flat' => '₹${discountValue.toStringAsFixed(0)} OFF',
        'shipping' => 'FREE SHIPPING',
        _ => '${discountValue.toStringAsFixed(0)}% OFF',
      };
}

/// Result of `POST /promos/validate`.
class PromoValidation {
  final String code;
  final String discountType;
  final double discountValue;
  final double discountAmount;

  const PromoValidation({
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.discountAmount,
  });

  factory PromoValidation.fromJson(Map<String, dynamic> json) {
    final promo = json['promo'] as Map<String, dynamic>? ?? {};
    return PromoValidation(
      code: (promo['code'] ?? json['code'] ?? '') as String,
      discountType: (promo['discountType'] ?? 'percent') as String,
      discountValue: ((promo['discountValue'] ?? 0) as num).toDouble(),
      discountAmount: ((json['discountAmount'] ?? 0) as num).toDouble(),
    );
  }
}
