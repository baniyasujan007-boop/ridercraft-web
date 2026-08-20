import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../routes/route_names.dart';
import '../../services/order_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../utils/formatters.dart';
import '../../widgets/rc_button.dart';
import '../cart/widgets/order_summary_card.dart';

/// Premium order-confirmation state: animated success mark, the order number
/// and a clean totals summary with the existing View Order / Continue
/// Shopping actions.
class OrderSuccessScreen extends StatefulWidget {
  final Order order;
  const OrderSuccessScreen({super.key, required this.order});
  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _check;
  late final Animation<double> _content;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    _check = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0,
          0.55,
          curve: Curves.easeOutBack,
        ),
      ),
    );
    _content = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 1, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final shortId = order.id.length > 8
        ? order.id.substring(order.id.length - 8).toUpperCase()
        : order.id;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    ScaleTransition(
                      scale: _check,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.success.withValues(alpha: 0.22),
                              blurRadius: 34,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: AppColors.success,
                          size: 54,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FadeTransition(
                      opacity: _content,
                      child: Column(
                        children: [
                          const Text(
                            'ORDER CONFIRMED',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.6,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          const Text(
                            'Your ride essentials are on the way.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              'Order #$shortId',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          OrderSummaryCard(
                            subtotal: order.subtotal,
                            discount: order.discount,
                            shipping: order.shipping,
                            total: order.total,
                            footNote:
                                '${order.items.length} item(s) · '
                                'Payment ${order.paymentLabel}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RcButton(
                    label: 'VIEW ORDER',
                    icon: Icons.receipt_long_rounded,
                    onPressed: () => Navigator.pushReplacementNamed(
                      context,
                      RouteNames.orderDetail,
                      arguments: order,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm + 2),
                  RcSecondaryButton(
                    label: 'CONTINUE SHOPPING',
                    icon: Icons.storefront_rounded,
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      RouteNames.main,
                      (r) => false,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My Orders')),
    body: FutureBuilder<List<Order>>(
      future: context.read<OrderService>().listMyOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load your orders.'));
        }
        final orders = snapshot.data ?? [];
        if (orders.isEmpty) return const Center(child: Text('No orders yet.'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Card(
              child: ListTile(
                onTap: () => Navigator.pushNamed(
                  context,
                  RouteNames.orderDetail,
                  arguments: order,
                ),
                title: Text(
                  'Order #${order.id.length > 8 ? order.id.substring(order.id.length - 8) : order.id}',
                ),
                subtitle: Text(
                  '${order.items.length} products · ${order.statusLabel} · ${order.paymentLabel}',
                ),
                trailing: Text(
                  Formatters.inr(order.total),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            );
          },
        );
      },
    ),
  );
}

class OrderDetailScreen extends StatelessWidget {
  final Order order;
  const OrderDetailScreen({super.key, required this.order});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Order #${order.id}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          ...order.items.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.name),
              subtitle: Text(
                [
                  if (item.color.isNotEmpty) item.color,
                  if (item.size.isNotEmpty) 'Size ${item.size}',
                  if (item.variantSku.isNotEmpty) item.variantSku,
                  'Qty ${item.qty}',
                ].join(' · '),
              ),
              trailing: Text(Formatters.inr(item.price * item.qty)),
            ),
          ),
          const Divider(),
          _total('Subtotal', order.subtotal),
          _total('Discount', -order.discount),
          _total('Shipping', order.shipping),
          _total('Tax', order.tax),
          _total('Total', order.total, bold: true),
          const SizedBox(height: 16),
          Text('Status: ${order.statusLabel} · Payment: ${order.paymentLabel}'),
          if (order.deliveryAddress.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'DELIVERY INFORMATION',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(order.deliveryAddress),
            Text(order.contactNumber),
          ],
        ],
      ),
    );
  }

  Widget _total(String label, double value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: bold ? FontWeight.w800 : null),
        ),
        const Spacer(),
        Text(
          Formatters.inr(value),
          style: TextStyle(fontWeight: bold ? FontWeight.w800 : null),
        ),
      ],
    ),
  );
}
