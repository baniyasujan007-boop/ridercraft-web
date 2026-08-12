import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../routes/route_names.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/rc_image.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _promo = TextEditingController();
  @override
  void dispose() {
    _promo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: cart.isEmpty
          ? _EmptyCart()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (var i = 0; i < cart.items.length; i++) _CartLine(index: i),
                const SizedBox(height: 14),
                TextField(
                  controller: _promo,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Promo code',
                    suffixIcon: TextButton(
                      onPressed: cart.isApplyingPromo
                          ? null
                          : () async {
                              final ok = await cart.applyPromo(_promo.text);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ok
                                        ? 'Promo applied.'
                                        : (cart.promoError ??
                                              'Invalid promo code.'),
                                  ),
                                ),
                              );
                            },
                      child: cart.isApplyingPromo
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('APPLY'),
                    ),
                  ),
                ),
                if (cart.appliedPromo != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Text(
                          '${cart.appliedPromo!.code} applied',
                          style: const TextStyle(color: AppColors.success),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: cart.removePromo,
                          child: const Text('REMOVE'),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 18),
                _Totals(cart: cart),
                const SizedBox(height: 20),
                CustomButton(
                  label: 'PROCEED TO CHECKOUT',
                  icon: Icons.lock_outline_rounded,
                  onPressed: () {
                    if (!context.read<AuthProvider>().isAuthenticated) {
                      Navigator.pushNamed(context, RouteNames.login);
                      return;
                    }
                    Navigator.pushNamed(context, RouteNames.checkout);
                  },
                ),
              ],
            ),
    );
  }
}

class _CartLine extends StatelessWidget {
  final int index;
  const _CartLine({required this.index});
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final item = cart.items[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            height: 82,
            child: RcImage(item.product.image, fit: BoxFit.contain),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.brand.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  item.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (item.color.isNotEmpty) item.color,
                    if (item.size.isNotEmpty) 'Size ${item.size}',
                    if (item.variantSku.isNotEmpty) item.variantSku,
                  ].join(' · '),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: item.quantity > 1
                          ? () => cart.decrement(index)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '${item.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: item.quantity < 99
                          ? () => cart.increment(index)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                    const Spacer(),
                    Text(
                      Formatters.inr(item.lineTotal),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => cart.removeItem(index),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  final CartProvider cart;
  const _Totals({required this.cart});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      children: [
        _row('Subtotal', cart.subtotal),
        if (cart.discount > 0)
          _row('Discount', -cart.discount, color: AppColors.success),
        const Divider(),
        _row('Estimated total', cart.total, bold: true),
        const SizedBox(height: 4),
        const Text(
          'Final price is confirmed securely at checkout.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
      ],
    ),
  );
  Widget _row(String label, double value, {Color? color, bool bold = false}) =>
      Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color ?? AppColors.textSecondary,
              fontWeight: bold ? FontWeight.w800 : null,
            ),
          ),
          const Spacer(),
          Text(
            Formatters.inr(value),
            style: TextStyle(
              color: color ?? AppColors.textPrimary,
              fontWeight: bold ? FontWeight.w800 : null,
            ),
          ),
        ],
      );
}

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 58,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          const Text(
            'Your cart is empty',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Explore our products and find your next ride essential.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 22),
          CustomButton(
            label: 'SHOP NOW',
            fullWidth: false,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    ),
  );
}
