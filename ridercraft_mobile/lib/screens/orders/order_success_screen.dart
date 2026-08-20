import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../routes/route_names.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/rc_button.dart';
import '../cart/widgets/order_summary_card.dart';
import 'widgets/order_status_chip.dart';

/// Premium order-confirmation state: an animated success mark with a subtle
/// ripple, the order number, a clean totals summary and the existing
/// View Order / Continue Shopping actions.
///
/// Shows only real data from the just-created [Order] — no fake delivery
/// dates or promises.
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
  late final Animation<double> _ripple;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );
    _check = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.55, curve: Curves.easeOutBack),
      ),
    );
    _content = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 1, curve: Curves.easeOutCubic),
    );
    _ripple = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 1, curve: Curves.easeOut),
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
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.35),
                    radius: 0.9,
                    colors: AppColors.heroGlowColors,
                  ),
                ),
              ),
            ),
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          width: 150,
                          height: 150,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Expanding ripple ring.
                              ScaleTransition(
                                scale: Tween<double>(begin: 0.4, end: 1.6)
                                    .animate(_ripple),
                                child: FadeTransition(
                                  opacity: Tween<double>(begin: 0.5, end: 0)
                                      .animate(_ripple),
                                  child: Container(
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.success.withValues(
                                          alpha: 0.45,
                                        ),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              ScaleTransition(
                                scale: _check,
                                child: Container(
                                  width: 104,
                                  height: 104,
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(
                                      alpha: 0.14,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.success.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 36,
                                        offset: const Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: AppColors.success,
                                    size: 58,
                                  ),
                                ),
                              ),
                            ],
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
                              const SizedBox(height: AppSpacing.sm),
                              OrderStatusChip(status: order.status),
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
          ],
        ),
      ),
    );
  }
}