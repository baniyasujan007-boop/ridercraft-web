import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/garage_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../utils/billing_calc.dart';
import '../../utils/formatters.dart';
import '../../widgets/rc_button.dart';

/// Opens the reusable garage billing sheet for a booking. Resolves `true`
/// when the bill was saved. The sheet pre-fills from the existing bill and
/// shows a live backend-matching total preview; the backend remains
/// authoritative for the stored values.
Future<bool?> showBillingSheet(
  BuildContext context, {
  required String bookingId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _BillingSheet(bookingId: bookingId),
  );
}

class _BillingSheet extends StatefulWidget {
  final String bookingId;

  const _BillingSheet({required this.bookingId});

  @override
  State<_BillingSheet> createState() => _BillingSheetState();
}

class _LineController {
  final TextEditingController name = TextEditingController();
  final TextEditingController quantity = TextEditingController(text: '1');
  final TextEditingController unitPrice = TextEditingController();
  bool used = false;
}

class _BillingSheetState extends State<_BillingSheet> {
  final TextEditingController _labor = TextEditingController();
  final TextEditingController _tax = TextEditingController();
  final TextEditingController _discount = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  final List<_LineController> _lines = [];
  String? _error;
  bool _initialized = false;

  @override
  void dispose() {
    _labor.dispose();
    _tax.dispose();
    _discount.dispose();
    _notes.dispose();
    for (final line in _lines) {
      line.name.dispose();
      line.quantity.dispose();
      line.unitPrice.dispose();
    }
    super.dispose();
  }

  void _init() {
    if (_initialized) return;
    _initialized = true;
    final garage = context.read<GarageProvider>();
    final billing = garage.bookingById(widget.bookingId)?.billing;
    _labor.text = _text(billing?.laborCharge);
    _tax.text = _text(billing?.tax);
    _discount.text = _text(billing?.discount);
    _notes.text = billing?.notes ?? '';

    final existingItems = billing?.items ?? const [];
    if (existingItems.isEmpty) {
      _lines.add(_LineController());
      _lines.first.used = true;
    } else {
      for (final item in existingItems) {
        final line = _LineController()
          ..name.text = item.name
          ..quantity.text = _text(item.quantity)
          ..unitPrice.text = _text(item.unitPrice);
        line.used = true;
        _lines.add(line);
      }
    }
  }

  static String _text(num? value) {
    if (value == null) return '';
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  void _addLine() => setState(() => _lines.add(_LineController()));

  void _removeLine(int index) {
    if (_lines.length <= 1) return;
    final line = _lines.removeAt(index);
    setState(() {});
    line.name.dispose();
    line.quantity.dispose();
    line.unitPrice.dispose();
  }

  BillingTotals get _totals => computeBillingTotals(
        laborCharge: _num(_labor.text),
        tax: _num(_tax.text),
        discount: _num(_discount.text),
        items: [
          for (final line in _lines)
            BillingLineDraft(
              name: line.name.text,
              quantity: _num(line.quantity.text, fallback: 1),
              unitPrice: _num(line.unitPrice.text),
            ),
        ],
      );

  String? _validate() {
    if (_num(_labor.text) < 0) return 'Labor charge cannot be negative.';
    if (_num(_tax.text) < 0) return 'Tax cannot be negative.';
    if (_num(_discount.text) < 0) return 'Discount cannot be negative.';
    for (final line in _lines) {
      final name = line.name.text.trim();
      if (name.isEmpty) continue;
      final qty = _num(line.quantity.text, fallback: 1);
      final price = _num(line.unitPrice.text);
      if (qty < 1) return 'Line "$name" needs a quantity of at least 1.';
      if (price < 0) return 'Line "$name" needs a valid price.';
    }
    return null;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final validationError = _validate();
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    final items = [
      for (final line in _lines)
        if (line.name.text.trim().isNotEmpty)
          {
            'name': line.name.text.trim(),
            'quantity': _safeInt(_num(line.quantity.text, fallback: 1)),
            'unitPrice': _num(line.unitPrice.text),
          },
    ];

    final garage = context.read<GarageProvider>();
    final ok = await garage.saveBilling(
      id: widget.bookingId,
      laborCharge: _num(_labor.text),
      tax: _num(_tax.text),
      discount: _num(_discount.text),
      items: items,
      notes: _notes.text,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = garage.billingError ?? 'Failed to save the bill.');
    }
  }

  static num _num(String text, {num fallback = 0}) =>
      num.tryParse(text.trim()) ?? fallback;

  static int _safeInt(num value) => value is int ? value : value.toInt();

  @override
  Widget build(BuildContext context) {
    _init();
    final garage = context.watch<GarageProvider>();
    final saving = garage.billingSaving;
    final totals = _totals;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.hero)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            top: AppSpacing.md,
            bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Service Bill',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Item totals are previews — the server stores the final amounts.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _field(
                        controller: _labor,
                        label: 'Labor Charge (₹)',
                        icon: Icons.build_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              controller: _tax,
                              label: 'Tax (₹)',
                              icon: Icons.calculate_outlined,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _field(
                              controller: _discount,
                              label: 'Discount (₹)',
                              icon: Icons.percent_rounded,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Text(
                        'ITEMS',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      for (var i = 0; i < _lines.length; i++) ...[
                        _itemRow(i: i),
                        if (i < _lines.length - 1) const SizedBox(height: AppSpacing.sm),
                      ],
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _addLine,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add item'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _field(
                        controller: _notes,
                        label: 'Notes',
                        icon: Icons.notes_rounded,
                        maxLines: 2,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _TotalsPreview(totals: totals),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              RcButton(
                label: saving ? 'Saving…' : 'Save Bill',
                icon: Icons.save_outlined,
                loading: saving,
                onPressed: saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLines,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: maxLines == null ? 1 : null,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 19),
        filled: true,
        fillColor: AppColors.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _itemRow({required int i}) {
    final line = _lines[i];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: line.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Item name',
                    isDense: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (_lines.length > 1)
                IconButton(
                  tooltip: 'Remove item',
                  onPressed: () => _removeLine(i),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.remove_circle_outline_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: line.quantity,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Qty',
                    isDense: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: line.unitPrice,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Unit price (₹)',
                    isDense: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalsPreview extends StatelessWidget {
  final BillingTotals totals;

  const _TotalsPreview({required this.totals});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          _row('Parts', Formatters.inr(totals.partsTotal)),
          _row('Subtotal', Formatters.inr(totals.subtotal)),
          _row('Tax', Formatters.inr(totals.tax)),
          _row('Discount', '-${Formatters.inr(totals.discount)}'),
          const Divider(height: 16, color: AppColors.border),
          _row(
            'Total',
            Formatters.inr(totals.total),
            emphasized: true,
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool emphasized = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: emphasized ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: emphasized ? AppColors.primaryLight : AppColors.textPrimary,
              fontSize: 13,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}