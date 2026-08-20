import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/notification.dart';
import '../../routes/route_names.dart';
import '../../services/api_exception.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../utils/formatters.dart';
import '../../widgets/error_view.dart';
import '../../widgets/staggered_entry.dart';
import '../orders/widgets/order_skeleton.dart';

/// Notification inbox from `GET /notifications`. Requires authentication;
/// guests see a sign-in prompt.
///
/// Reads/writes the existing mark-as-read endpoints only; the model has no
/// target/route field so tapping a notification always opens its detail sheet
/// (no invented deep links).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  List<AppNotification> _items = [];
  bool _loading = true;
  String? _error;
  bool _authError = false;

  late final AnimationController _entrance;

  NotificationService get _service => context.read<NotificationService>();

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
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

  /// Loads the inbox. [showLoader] blanks the list with the skeleton on the
  /// first load; a pull-to-refresh keeps the existing rows visible.
  Future<void> _load({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _loading = true;
        _error = null;
        _authError = false;
      });
    }
    try {
      final items = await _service.listNotifications();
      if (!mounted) return;
      setState(() {
        _items = items;
        _error = null;
        _authError = false;
      });
      _entrance.forward(from: 0);
    } on ApiException catch (error) {
      if (!mounted) return;
      // Keep stale rows visible on a failed refresh; surface the failure.
      if (_items.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      } else {
        setState(() {
          _error = error.message;
          _authError = error.isUnauthorized;
        });
      }
    } finally {
      if (mounted && showLoader) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() => _load(showLoader: false);

  Future<void> _markAllRead() async {
    try {
      await _service.markAllRead();
      if (!mounted) return;
      setState(() {
        _items = _items.map((item) => item.copyWith(isRead: true)).toList();
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _openNotification(AppNotification item) async {
    if (!item.isRead) {
      try {
        await _service.markRead(item.id);
        if (!mounted) return;
        setState(() {
          _items = _items
              .map((e) => e.id == item.id ? e.copyWith(isRead: true) : e)
              .toList();
        });
      } on ApiException catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: typeColor(item.type).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        typeIcon(item.type),
                        color: typeColor(item.type),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.body,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int get _unreadCount => _items.where((item) => !item.isRead).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_unreadCount > 0)
            TextButton(onPressed: _markAllRead, child: const Text('Mark all')),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Text(
              'Loading notifications…',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const Expanded(child: NotificationListSkeleton()),
        ],
      );
    }

    if (_authError) {
      return _CenteredState(
        icon: Icons.lock_outline_rounded,
        message: 'Sign in to see your notifications.',
        action: FilledButton(
          onPressed: () => Navigator.of(context).pushNamed(RouteNames.login),
          child: const Text('Sign in'),
        ),
      );
    }

    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _load);
    }

    if (_items.isEmpty) {
      return const _CenteredState(
        icon: Icons.notifications_none_rounded,
        message: 'No notifications yet.',
        subtitle: 'When something happens, it will show up here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        itemCount: _items.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _InboxHeader(
              unread: _unreadCount,
              total: _items.length,
            );
          }
          final item = _items[index - 1];
          return StaggeredEntry(
            parent: _entrance,
            index: index - 1,
            child: _NotificationTile(
              item: item,
              onTap: () => _openNotification(item),
            ),
          );
        },
      ),
    );
  }
}

/// Slim inbox header showing the live unread/total counts.
class _InboxHeader extends StatelessWidget {
  final int unread;
  final int total;

  const _InboxHeader({required this.unread, required this.total});

  @override
  Widget build(BuildContext context) {
    final unreadLabel = unread == 1 ? '1 unread' : '$unread unread';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              total == 1 ? '1 notification' : '$total notifications',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: unread > 0
                ? Container(
                    key: ValueKey<int>(unread),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm + 2,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      unreadLabel,
                      style: const TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Row for a single notification: type icon, title + relative time, body, an
/// unread accent bar/dot for unread rows and a muted surface once read.
/// Uses [Expanded]/[Flexible] throughout so it never overflows at narrow
/// widths or large text scales.
class _NotificationTile extends StatelessWidget {
  final AppNotification item;
  final VoidCallback onTap;

  const _NotificationTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final timeLabel = item.createdAt == null
        ? ''
        : Formatters.timeAgoLabel(item.createdAt!);
    final unread = !item.isRead;

    return Semantics(
      button: true,
      label:
          '${unread ? 'Unread. ' : ''}${item.title}. ${item.body}. '
          '${timeLabel.isEmpty ? '' : '$timeLabel.'} '
          'Type ${item.type}.',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        color: unread ? AppColors.surfaceAlt : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg,
                 vertical: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 3.5,
                  height: 54,
                  decoration: BoxDecoration(
                    color: unread
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: typeColor(item.type).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    typeIcon(item.type),
                    color: typeColor(item.type),
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight:
                                    unread ? FontWeight.w700 : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (timeLabel.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              timeLabel,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (item.body.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AnimatedScale(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  scale: unread ? 1 : 0,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.55),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Scroll-safe centered state used for the guest and empty inboxes so the
/// content never overflows a short viewport at large text scales.
class _CenteredState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;
  final Widget? action;

  const _CenteredState({
    required this.icon,
    required this.message,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

IconData typeIcon(String type) => switch (type) {
      'order' => Icons.receipt_long_outlined,
      'service' => Icons.build_outlined,
      'payment' => Icons.payments_outlined,
      'coupon' => Icons.confirmation_number_outlined,
      'profile' => Icons.person_outline_rounded,
      _ => Icons.notifications_none_rounded,
    };

Color typeColor(String type) => switch (type) {
      'order' => AppColors.info,
      'service' => AppColors.primary,
      'payment' => AppColors.success,
      'coupon' => AppColors.accent,
      'profile' => AppColors.secondary,
      _ => AppColors.textSecondary,
    };