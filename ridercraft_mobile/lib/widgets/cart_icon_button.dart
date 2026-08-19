import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../routes/route_names.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'rc_icon_button.dart';

/// Premium cart button for headers. Watches the cart count and pulses the
/// badge whenever the count changes so "product added" feedback is visible
/// outside of the purchase surface too.
class CartIconButton extends StatelessWidget {
  const CartIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.watch<CartProvider>().count;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        RcIconButton(
          icon: Icons.shopping_bag_outlined,
          tooltip: 'Cart',
          onTap: () => Navigator.pushNamed(context, RouteNames.cart),
        ),
        Positioned(
          right: -2,
          top: -3,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, animation) {
              final scale = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              );
              return ScaleTransition(scale: scale, child: child);
            },
            child: count > 0
                ? Container(
                    key: ValueKey('cart-badge-$count'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    constraints: const BoxConstraints(minWidth: 17),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: AppColors.background,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('cart-badge-empty')),
          ),
        ),
      ],
    );
  }
}