// Billing arithmetic used by the garage billing sheet.
//
// Mirrors the backend (`server/controllers/serviceRequestController.js`):
//   partsTotal = Σ (quantity × unitPrice)
//   subtotal   = laborCharge + partsTotal
//   totalBefDiscount = subtotal + tax
//   total      = totalBefDiscount - discount
//
// The backend is authoritative for the stored bill; these values are only a
// client-side preview so the garage sees the exact figures before saving.
import 'dart:math' as math;

class BillingTotals {
  final num partsTotal;
  final num subtotal;
  final num tax;
  final num discount;
  final num total;

  const BillingTotals({
    required this.partsTotal,
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.total,
  });

  num get totalBeforeDiscount => subtotal + tax;
}

/// A draft billing line item while editing (names/quantities may be empty).
class BillingLineDraft {
  final String name;
  final num quantity;
  final num unitPrice;

  const BillingLineDraft({
    this.name = '',
    this.quantity = 1,
    this.unitPrice = 0,
  });
}

/// Computes the same totals the backend would, from draft values.
/// Non-finite or negative inputs are coerced to 0.
BillingTotals computeBillingTotals({
  required num laborCharge,
  required num tax,
  required num discount,
  required List<BillingLineDraft> items,
}) {
  final labor = _toAmount(laborCharge);
  final taxAmount = _toAmount(tax);
  final discountAmount = _toAmount(discount);

  final partsTotal = items.fold<num>(
    0,
    (sum, item) => sum + _toAmount(item.quantity) * _toAmount(item.unitPrice),
  );
  final subtotal = labor + partsTotal;
  final totalBeforeDiscount = subtotal + taxAmount;
  final total = math.max(0, totalBeforeDiscount - discountAmount);

  return BillingTotals(
    partsTotal: partsTotal,
    subtotal: subtotal,
    tax: taxAmount,
    discount: discountAmount,
    total: total,
  );
}

num _toAmount(num value) {
  if (!value.isFinite || value < 0) return 0;
  return value;
}