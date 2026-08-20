// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cart_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../routes/route_names.dart';
import '../../services/api_exception.dart';
import '../../services/order_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../utils/formatters.dart';
import '../../widgets/rc_button.dart';
import '../../widgets/rc_card.dart';
import '../../widgets/rc_entrance.dart';
import '../../widgets/rc_image.dart';
import 'widgets/checkout_bar.dart';
import 'widgets/order_summary_card.dart';
import 'widgets/promo_section.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _address = TextEditingController(),
      _phone = TextEditingController(),
      _wallet = TextEditingController(),
      _promo = TextEditingController();
  String _method = 'cod';
  bool _saving = false;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      final u = context.read<AuthProvider>().user;
      _address.text = u?.deliveryAddress ?? '';
      _phone.text = u?.contactNumber ?? '';
    }
  }

  @override
  void dispose() {
    for (final c in [_address, _phone, _wallet, _promo]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _place() async {
    final cart = context.read<CartProvider>();
    if (_address.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      _message('Enter a delivery address and contact number.');
      return;
    }
    if (_method == 'ewallet' && _wallet.text.trim().isEmpty) {
      _message('Enter your wallet provider and ID.');
      return;
    }
    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    final orderService = context.read<OrderService>();
    try {
      await auth.updateProfile(
        deliveryAddress: _address.text.trim(),
        contactNumber: _phone.text.trim(),
      );
      final order = await orderService.createOrder(
        items: cart.items,
        subtotal: cart.subtotal,
        tax: 0,
        shipping: 0,
        discount: cart.discount,
        total: cart.total,
        promoCode: cart.appliedPromo?.code ?? '',
        paymentMethod: _method,
        paymentDetails: _method == 'ewallet'
            ? {
                'walletProvider': 'eWallet',
                'walletId': _wallet.text,
                'isDummy': true,
              }
            : {},
      );
      await cart.clear();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        RouteNames.orderSuccess,
        (r) => r.settings.name == RouteNames.main,
        arguments: order,
      );
    } on ApiException catch (e) {
      _message(
        e.isNetworkError || e.isTimeout
            ? 'Unable to connect to RiderCraft. Please check your internet connection and try again.'
            : e.message,
      );
    } catch (_) {
      _message('Unable to place your order. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const _EmptyCheckout(),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                RcEntrance(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionHeader(
                        title: 'Delivery address',
                        icon: Icons.location_on_outlined,
                      ),
                      RcCard(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          children: [
                            TextField(
                              controller: _address,
                              key: const ValueKey('checkout-address'),
                              maxLines: 3,
                              minLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Delivery Address',
                                hintText: 'Street, area, city, PIN code',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextField(
                              controller: _phone,
                              key: const ValueKey('checkout-phone'),
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Contact Number',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const _SectionHeader(
                        title: 'Order items',
                        icon: Icons.shopping_bag_outlined,
                      ),
                      RcCard(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          children: [
                            for (var i = 0; i < cart.items.length; i++) ...[
                              _OrderLine(item: cart.items[i]),
                              if (i != cart.items.length - 1)
                                const Divider(height: AppSpacing.xl),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const _SectionHeader(
                        title: 'Coupon',
                        icon: Icons.local_offer_outlined,
                      ),
                      PromoSection(controller: _promo),
                      const SizedBox(height: AppSpacing.xl),
                      const _SectionHeader(
                        title: 'Payment method',
                        icon: Icons.credit_card_rounded,
                      ),
                      _PaymentCard(
                        method: _method,
                        walletController: _wallet,
                        onChanged: (value) => setState(() => _method = value),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      OrderSummaryCard(
                        subtotal: cart.subtotal,
                        discount: cart.discount,
                        total: cart.total,
                        footNote:
                            'Final subtotal, tax and shipping are calculated '
                            'by RiderCraft when the order is placed.',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ),
                ),
              ],
            ),
          ),
          CheckoutBar(
            total: cart.total,
            label: 'PLACE ORDER',
            icon: Icons.shield_outlined,
            loading: _saving,
            onCheckout: _saving ? null : () => _place(),
          ),
        ],
      ),
    );
  }
}

class _EmptyCheckout extends StatelessWidget {
  const _EmptyCheckout();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.remove_shopping_cart_outlined,
              size: 52,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Nothing to check out.',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Your cart is empty.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            RcButton(
              label: 'Back to Cart',
              icon: Icons.arrow_back_rounded,
              fullWidth: false,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderLine extends StatelessWidget {
  final CartItem item;
  const _OrderLine({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: RcImage(
            item.product.image,
            width: 46,
            height: 46,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                [
                  if (item.color.isNotEmpty) item.color,
                  if (item.size.isNotEmpty) 'Size ${item.size}',
                  'Qty ${item.quantity}',
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          Formatters.inr(item.lineTotal),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ],
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final String method;
  final TextEditingController walletController;
  final ValueChanged<String> onChanged;

  const _PaymentCard({
    required this.method,
    required this.walletController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RcCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        children: [
          RadioListTile<String>(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
            ),
            activeColor: AppColors.primary,
            value: 'cod',
            groupValue: method,
            onChanged: (v) => onChanged(v!),
            title: const Text(
              'Cash on Delivery',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            subtitle: const Text(
              'Pay when your order arrives.',
              style: TextStyle(fontSize: 12),
            ),
          ),
          RadioListTile<String>(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
            ),
            activeColor: AppColors.primary,
            value: 'ewallet',
            groupValue: method,
            onChanged: (v) => onChanged(v!),
            title: const Text(
              'E-Wallet (Demo)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            subtitle: const Text(
              'Test mode — no real payment is processed.',
              style: TextStyle(fontSize: 12),
            ),
          ),
          if (method == 'ewallet')
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: TextField(
                controller: walletController,
                key: const ValueKey('checkout-wallet'),
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Wallet number or email (demo)',
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Card payments are not available yet. E-wallet is '
                    'test/demo only, no real payment is processed and no '
                    'payment details are saved.',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}