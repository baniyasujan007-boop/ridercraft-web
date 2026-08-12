import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../routes/route_names.dart';
import '../../services/order_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/custom_button.dart';

class OrderSuccessScreen extends StatelessWidget {
  final Order order;
  const OrderSuccessScreen({super.key, required this.order});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 70,
            ),
            const SizedBox(height: 16),
            const Text(
              'Order Confirmed',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Order #${order.id.length > 8 ? order.id.substring(order.id.length - 8).toUpperCase() : order.id}',
            ),
            const SizedBox(height: 8),
            const Text(
              'Thank you for your purchase.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'VIEW ORDER',
              onPressed: () => Navigator.pushReplacementNamed(
                context,
                RouteNames.orderDetail,
                arguments: order,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                RouteNames.main,
                (r) => false,
              ),
              child: const Text('CONTINUE SHOPPING'),
            ),
          ],
        ),
      ),
    ),
  );
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
