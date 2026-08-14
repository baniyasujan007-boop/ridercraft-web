// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../routes/route_names.dart';
import '../../services/api_exception.dart';
import '../../services/order_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/custom_button.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _address = TextEditingController(),
      _phone = TextEditingController(),
      _wallet = TextEditingController();
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
    for (final c in [_address, _phone, _wallet]) {
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
      return const Scaffold(body: Center(child: Text('Your cart is empty.')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _Heading('Delivery information'),
          TextField(
            controller: _address,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Delivery Address'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Contact Number'),
          ),
          const SizedBox(height: 24),
          const _Heading('Payment method'),
          for (final option in const [
            ('cod', 'Cash on Delivery'),
            ('ewallet', 'E-Wallet (Demo)'),
          ])
          RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              value: option.$1,
              groupValue: _method,
              onChanged: (v) => setState(() => _method = v!),
              title: Text(option.$2),
            ),
          const Text(
            'Card payments are not available yet. E-wallet is demo/test only '
            'and no real payment is processed.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          if (_method == 'ewallet') _field(_wallet, 'Wallet number or email (demo)'),
          const SizedBox(height: 20),
          const _Heading('Order review'),
          ...cart.items.map(
            (i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${i.product.name} × ${i.quantity}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(Formatters.inr(i.lineTotal)),
                ],
              ),
            ),
          ),
          const Divider(),
          _line('Subtotal', cart.subtotal),
          if (cart.discount > 0)
            _line('Discount', -cart.discount, color: AppColors.success),
          const Text(
            'Final subtotal, tax and shipping are calculated by RiderCraft when the order is placed.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 18),
          CustomButton(
            label: 'PLACE ORDER',
            loading: _saving,
            onPressed: _saving ? null : _place,
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    TextInputType? keyboard,
  }) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: TextField(
      controller: c,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label),
    ),
  );
  Widget _line(String label, double value, {Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Text(label),
        const Spacer(),
        Text(Formatters.inr(value), style: TextStyle(color: color)),
      ],
    ),
  );
}

class _Heading extends StatelessWidget {
  final String text;
  const _Heading(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    ),
  );
}
