/// Line item of a garage-issued service bill.
class ServiceBillingItem {
  final String name;
  final num quantity;
  final num unitPrice;
  final num total;

  const ServiceBillingItem({
    this.name = '',
    this.quantity = 1,
    this.unitPrice = 0,
    this.total = 0,
  });

  factory ServiceBillingItem.fromJson(Map<String, dynamic> json) {
    return ServiceBillingItem(
      name: (json['name'] ?? '') as String,
      quantity: (json['quantity'] ?? 0) as num,
      unitPrice: (json['unitPrice'] ?? 0) as num,
      total: (json['total'] ?? 0) as num,
    );
  }

  num get lineTotal => quantity * unitPrice;
}

/// Billing block of a service request, matching the backend `ServiceRequest`
/// `billing` sub-document. The backend is authoritative on totals; the client
/// only renders what the API returns (and previews while drafting).
class ServiceBilling {
  final num laborCharge;
  final List<ServiceBillingItem> items;
  final num subtotal;
  final num tax;
  final num discount;
  final num total;
  final String status;
  final String notes;
  final String paymentMethod;
  final String paymentReference;
  final DateTime? issuedAt;
  final DateTime? paidAt;

  const ServiceBilling({
    this.laborCharge = 0,
    this.items = const [],
    this.subtotal = 0,
    this.tax = 0,
    this.discount = 0,
    this.total = 0,
    this.status = 'unbilled',
    this.notes = '',
    this.paymentMethod = '',
    this.paymentReference = '',
    this.issuedAt,
    this.paidAt,
  });

  factory ServiceBilling.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return const ServiceBilling();
    final rawItems = json['items'];
    return ServiceBilling(
      laborCharge: (json['laborCharge'] ?? 0) as num,
      items: rawItems is List
          ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(ServiceBillingItem.fromJson)
              .toList()
          : const <ServiceBillingItem>[],
      subtotal: (json['subtotal'] ?? 0) as num,
      tax: (json['tax'] ?? 0) as num,
      discount: (json['discount'] ?? 0) as num,
      total: (json['total'] ?? 0) as num,
      status: (json['status'] ?? 'unbilled') as String,
      notes: (json['notes'] ?? '') as String,
      paymentMethod: (json['paymentMethod'] ?? '') as String,
      paymentReference: (json['paymentReference'] ?? '') as String,
      issuedAt: json['issuedAt'] != null
          ? DateTime.tryParse(json['issuedAt'] as String)
          : null,
      paidAt: json['paidAt'] != null
          ? DateTime.tryParse(json['paidAt'] as String)
          : null,
    );
  }

  bool get isIssued => status == 'issued';
  bool get isPaid => status == 'paid';
  bool get isCancelled => status == 'cancelled';

  String get statusLabel => switch (status) {
        'issued' => 'Issued',
        'paid' => 'Paid',
        'cancelled' => 'Cancelled',
        _ => 'Unbilled',
      };

  /// Display label for the payment method ("" -> "—").
  String get paymentMethodLabel {
    if (paymentMethod.isEmpty) return '—';
    return paymentMethod
        .split('_')
        .map((word) =>
            word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}