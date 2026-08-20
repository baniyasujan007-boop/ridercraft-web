import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../routes/route_names.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/rc_button.dart';
import '../../widgets/rc_entrance.dart';
import 'widgets/cart_item_card.dart';
import 'widgets/checkout_bar.dart';
import 'widgets/order_summary_card.dart';
import 'widgets/promo_section.dart';

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

  void _goToCheckout() {
    if (!context.read<AuthProvider>().isAuthenticated) {
      Navigator.pushNamed(context, RouteNames.login);
      return;
    }
    Navigator.pushNamed(context, RouteNames.checkout);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: cart.isEmpty
          ? const _EmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.only(
                      top: AppSpacing.sm,
                      bottom: AppSpacing.xl,
                    ),
                    children: [
                      _CartHeader(count: cart.count),
                      const SizedBox(height: AppSpacing.sm),
                      for (var i = 0; i < cart.items.length; i++) ...[
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.xs,
                          ),
                          child: CartItemCard(
                            key: ValueKey<String>(
                              CartItemCard.identityOf(cart.items[i]),
                            ),
                            item: cart.items[i],
                            onIncrement: () => cart.increment(i),
                            onDecrement: () => cart.decrement(i),
                            onRemove: () => cart.removeItem(i),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: PromoSection(controller: _promo),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: OrderSummaryCard(
                          subtotal: cart.subtotal,
                          discount: cart.discount,
                          total: cart.total,
                        ),
                      ),
                    ],
                  ),
                ),
                CheckoutBar(
                  total: cart.total,
                  onCheckout: _goToCheckout,
                ),
              ],
            ),
    );
  }
}

class _CartHeader extends StatelessWidget {
  final int count;
  const _CartHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return RcEntrance(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CART',
                    style: TextStyle(
                      fontSize: 24,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Review your ride essentials',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                count == 1 ? '1 item' : '$count items',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: RcEntrance(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.hero),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.sports_motorsports_rounded,
                  size: 42,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'Your cart is ready for its next ride.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Explore premium gear and find everything your ride needs.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xxl),
              RcButton(
                label: 'Explore Shop',
                icon: Icons.storefront_rounded,
                fullWidth: false,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}