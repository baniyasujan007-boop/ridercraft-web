import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/user.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../routes/route_names.dart';
import '../../../services/notification_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../widgets/rc_avatar.dart';
import '../../../widgets/rc_icon_button.dart';

/// Premium Home header: RiderCraft brand on the left, notification (unread
/// dot), cart (live badge count) and the rider avatar on the right.
///
/// Navigation for the notification button is delegated to the owning screen
/// through [onNotificationsTap]; the header still resolves the unread state
/// from [NotificationService] when the provider and an authenticated session
/// are present. The cart and notification features degrade gracefully when
/// their providers are absent (guests / widget-test harnesses), so the header
/// never breaks.
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationsTap;

  const HomeAppBar({
    super.key,
    required this.onProfileTap,
    required this.onNotificationsTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: AppSpacing.lg,
      shape: const Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/ridercraft-logo.png',
              width: 28,
              height: 28,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Flexible(
            child: Text(
              'RiderCraft',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
      actions: [
        _NotificationBadge(onNotificationsTap: onNotificationsTap),
        _CartHeaderButton(),
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: Center(child: _ProfileAvatar(onTap: onProfileTap)),
        ),
      ],
    );
  }
}

/// Notification bell with an unread dot. Loads the real inbox through
/// [NotificationService] when the provider (and an authenticated session) is
/// present. Navigation is delegated to the owning screen. Falls back to a
/// plain icon otherwise.
class _NotificationBadge extends StatefulWidget {
  final VoidCallback onNotificationsTap;

  const _NotificationBadge({required this.onNotificationsTap});

  @override
  State<_NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<_NotificationBadge> {
  NotificationService? _service;
  bool _hasUnread = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated && _service == null) {
      try {
        _service = Provider.of<NotificationService>(context, listen: false);
      } catch (_) {
        _service = null;
      }
      if (_service != null) _refreshUnread();
    }
  }

  Future<void> _refreshUnread() async {
    try {
      final items = await _service!.listNotifications();
      if (!mounted) return;
      setState(() => _hasUnread = items.any((item) => !item.isRead));
    } catch (_) {
      // Optional enhancement: never block or break the header on a failure.
    }
  }

  Future<void> _open() async {
    widget.onNotificationsTap();
    if (mounted && _service != null) _refreshUnread();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: RcIconButton(
        icon: Icons.notifications_none_rounded,
        tooltip: 'Notifications',
        showDot: _hasUnread,
        onTap: _open,
      ),
    );
  }
}

/// Cart icon with a live item-count badge. Hidden when no [CartProvider]
/// ancestor exists (harness/guest wrapper without a cart).
class _CartHeaderButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    CartProvider? cart;
    try {
      cart = Provider.of<CartProvider>(context, listen: true);
    } catch (_) {
      cart = null;
    }
    if (cart == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: RcIconButton(
        icon: Icons.shopping_bag_outlined,
        tooltip: 'Cart',
        badgeCount: cart.count,
        onTap: () => Navigator.of(context).pushNamed(RouteNames.cart),
      ),
    );
  }
}

/// Rider avatar wired to the signed-in [User] (avatar URI or initials).
class _ProfileAvatar extends StatelessWidget {
  final VoidCallback onTap;

  const _ProfileAvatar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthProvider, User?>(
      (provider) => provider.user,
    );
    final avatarUrl = (user?.avatar ?? '').trim().isEmpty
        ? null
        : user!.avatar.trim();
    return RcAvatar(
      avatarUrl: avatarUrl,
      name: user?.name ?? '',
      size: 32,
      onTap: onTap,
    );
  }
}
