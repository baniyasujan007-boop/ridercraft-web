import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../routes/route_names.dart';
import '../../screens/main_scaffold.dart';
import '../../services/api_exception.dart';
import '../../services/order_service.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/error_view.dart';
import '../../widgets/staggered_entry.dart';
import '../../widgets/section_header.dart';
import 'widgets/empty_orders.dart';
import 'widgets/order_card.dart';
import 'widgets/order_skeleton.dart';

/// Customer order history from `GET /orders/my`.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  List<Order> _orders = [];
  bool _loading = true;
  String? _error;

  late final AnimationController _entrance;

  OrderService get _service => context.read<OrderService>();

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      if (!_entrance.isCompleted) _entrance.value = 1;
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Future<void> _load({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final orders = await _service.listMyOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _error = null;
      });
      _entrance.forward(from: 0);
    } on ApiException catch (error) {
      if (!mounted) return;
      if (_orders.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      } else {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted && showLoader) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() => _load(showLoader: false);

  void _openOrder(Order order) {
    Navigator.pushNamed(context, RouteNames.orderDetail, arguments: order);
  }

  void _exploreShop() {
    MainScaffold.switchToTab(2); // Shop
    Navigator.of(context).pushNamedAndRemoveUntil(
      RouteNames.main,
      (route) => route.settings.name == RouteNames.main,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const OrderListSkeleton();

    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _load);
    }

    if (_orders.isEmpty) {
      return EmptyOrders(onExploreShop: _exploreShop);
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: AppSpacing.md),
        itemCount: _orders.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _OrdersHeader(count: _orders.length);
          }
          final order = _orders[index - 1];
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: StaggeredEntry(
              parent: _entrance,
              index: index - 1,
              child: OrderCard(
                order: order,
                onTap: () => _openOrder(order),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// "Track every purchase from checkout to delivery." + a live order count.
class _OrdersHeader extends StatelessWidget {
  final int count;

  const _OrdersHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: SectionHeader(
        kicker: count == 1 ? '1 order' : '$count orders',
        title: 'Track every purchase from checkout to delivery.',
        showDivider: true,
      ),
    );
  }
}