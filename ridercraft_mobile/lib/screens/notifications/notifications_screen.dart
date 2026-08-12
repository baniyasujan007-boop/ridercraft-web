import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/notification.dart';
import '../../routes/route_names.dart';
import '../../services/api_exception.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _authError = false;
    });
    try {
      final items = await _service.listNotifications();
      if (!mounted) return;
      setState(() => _items = items);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _authError = error.isUnauthorized;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    await _service.markAllRead();
    if (!mounted) return;
    setState(() {
      _items = _items
          .map((e) => AppNotification(
                id: e.id,
                title: e.title,
                body: e.body,
                type: e.type,
                isRead: true,
                createdAt: e.createdAt,
              ))
          .toList();
    });
  }

  Future<void> _openNotification(AppNotification item) async {
    if (!item.isRead) {
      await _service.markRead(item.id);
      if (!mounted) return;
      setState(() {
        _items = _items
            .map((e) => e.id == item.id
                ? AppNotification(
                    id: e.id,
                    title: e.title,
                    body: e.body,
                    type: e.type,
                    isRead: true,
                    createdAt: e.createdAt,
                  )
                : e)
            .toList();
      });
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_items.any((item) => !item.isRead))
            TextButton(onPressed: _markAllRead, child: const Text('Mark all')),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView(label: 'Loading notifications…');

    if (_authError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 48,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 16),
              const Text(
                'Sign in to see your notifications.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(context)
                    .pushNamed(RouteNames.login),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _load);
    }

    if (_items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 48,
              color: AppColors.textMuted,
            ),
            SizedBox(height: 16),
            Text(
              'No notifications yet.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = _items[index];
        return ListTile(
          onTap: () => _openNotification(item),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _typeColor(item.type).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _typeIcon(item.type),
              color: _typeColor(item.type),
              size: 22,
            ),
          ),
          title: Text(
            item.title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: item.isRead ? FontWeight.w400 : FontWeight.w700,
            ),
          ),
          subtitle: Text(
            item.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          trailing: item.isRead
              ? null
              : Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
        );
      },
    );
  }

  IconData _typeIcon(String type) => switch (type) {
        'order' => Icons.receipt_long_outlined,
        'service' => Icons.build_outlined,
        'payment' => Icons.payments_outlined,
        'coupon' => Icons.confirmation_number_outlined,
        'profile' => Icons.person_outline_rounded,
        _ => Icons.notifications_none_rounded,
      };

  Color _typeColor(String type) => switch (type) {
        'order' => AppColors.info,
        'service' => AppColors.primary,
        'payment' => AppColors.success,
        'coupon' => AppColors.accent,
        'profile' => AppColors.secondary,
        _ => AppColors.textSecondary,
      };
}
