import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/notification.dart';
import '../../routes/route_names.dart';
import '../../services/api_exception.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

/// Notification inbox from `GET /notifications`. Requires authentication;
/// guests see a sign-in prompt.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _items = [];
  bool _loading = true;
  String? _error;
  bool _authError = false;

  NotificationService get _service => context.read<NotificationService>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Loads the inbox. [showLoader] blanks the list with the loading view on
  /// the first load; a pull-to-refresh keeps the existing rows visible.
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
                Text(
                  item.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
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
    if (_loading) return const LoadingView(label: 'Loading notifications…');

    if (_authError) {
      return _CenteredState(
        icon: Icons.lock_outline_rounded,
        message: 'Sign in to see your notifications.',
        action: FilledButton(
          onPressed: () =>
              Navigator.of(context).pushNamed(RouteNames.login),
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
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const Divider(
          height: 1,
          color: AppColors.borderSubtle,
        ),
        itemBuilder: (context, index) => _NotificationTile(
          item: _items[index],
          onTap: () => _openNotification(_items[index]),
        ),
      ),
    );
  }
}

/// Row for a single notification: type icon, title + relative time, body, and
/// an orange unread dot. Uses [Expanded]/[Flexible] throughout so it never
/// overflows at narrow widths or large text scales.
class _NotificationTile extends StatelessWidget {
  final AppNotification item;
  final VoidCallback onTap;

  const _NotificationTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final timeLabel = item.createdAt == null
        ? ''
        : Formatters.timeAgoLabel(item.createdAt!);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(width: 12),
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
                                item.isRead ? FontWeight.w400 : FontWeight.w700,
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
            if (!item.isRead) ...[
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ],
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
  final Widget? action;

  const _CenteredState({
    required this.icon,
    required this.message,
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
              style: const TextStyle(color: AppColors.textSecondary),
            ),
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