// lib/screens/tabs/notifications_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../models/user.dart';
import '../../models/app_notification.dart';
import '../../services/api_client.dart';

class NotificationsTab extends StatefulWidget {
  final AppUser currentUser;
  final void Function(int unreadCount)? onUnreadChanged;

  const NotificationsTab({
    super.key,
    required this.currentUser,
    this.onUnreadChanged,
  });

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  final _api = ApiClient();
  bool _loading = false;
  String? _error;
  List<AppNotification> _items = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await _api.fetchNotifications(widget.currentUser.id);
      _items = list;
      _notifyUnreadChanged();
    } catch (e, st) {
      debugPrint('Error loading notifications: $e\n$st');
      _error = 'Failed to load notifications. Please pull to refresh.';
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _notifyUnreadChanged() {
    if (widget.onUnreadChanged == null) return;
    final unread = _items.where((n) => !n.isRead && !n.deleted).length;
    widget.onUnreadChanged!(unread);
  }

  Future<void> _onRefresh() async {
    await _loadNotifications();
  }

  Future<void> _deleteNotification(AppNotification removed, int index) async {
    try {
      await _api.deleteNotification(removed.id);
    } catch (e, st) {
      debugPrint('Error deleting notification: $e\n$st');
      if (!mounted) return;

      // Revert UI optimistically
      setState(() {
        _items.insert(index, removed);
      });
      _notifyUnreadChanged();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete notification. Please try again.'),
        ),
      );
    }
  }

  void _onTapNotification(int index) {
    final n = _items[index];

    if (!n.isRead) {
      final updated = AppNotification(
        id: n.id,
        title: n.title,
        body: n.body,
        createdAt: n.createdAt,
        isRead: true,
        deleted: n.deleted,
      );

      setState(() => _items[index] = updated);
      _notifyUnreadChanged();

      _markAsReadSilently(n.id);
    }
  }

  Future<void> _markAsReadSilently(String id) async {
    try {
      await _api.markNotificationsRead(widget.currentUser.id, [id]);
    } catch (e, st) {
      debugPrint('Error marking notification as read: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          children: [
            const SizedBox(height: 120),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Error loading notifications.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pull down to try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: onSurface.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          children: [
            const SizedBox(height: 120),
            Center(
              child: Text(
                'No notifications yet',
                style: TextStyle(color: onSurface.withOpacity(0.5)),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.separated(
        itemCount: _items.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: theme.dividerColor.withOpacity(0.15)),
        itemBuilder: (context, index) {
          final n = _items[index];
          final isRead = n.isRead;

          // Balanced highlight for unread
          final unreadBg = theme.brightness == Brightness.dark
              ? theme.colorScheme.primary.withOpacity(0.22)
              : theme.colorScheme.primary.withOpacity(0.15);

          final bgColor = isRead ? Colors.transparent : unreadBg;

          final titleStyle = theme.textTheme.bodyMedium!.copyWith(
            fontWeight: isRead ? FontWeight.w400 : FontWeight.w700,
            color: isRead ? onSurface.withOpacity(0.7) : onSurface,
          );

          final bodyStyle = theme.textTheme.bodySmall!.copyWith(
            color: isRead
                ? onSurface.withOpacity(0.5)
                : onSurface.withOpacity(0.85),
          );

          final timeStyle = theme.textTheme.labelSmall!.copyWith(
            color: onSurface.withOpacity(0.45),
          );

          final iconColor = isRead
              ? onSurface.withOpacity(0.5)
              : theme.colorScheme.primary;

          final tile = Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              leading: Icon(
                isRead ? Icons.notifications_none : Icons.notifications_active,
                color: iconColor,
              ),
              title: Text(n.title, style: titleStyle),
              subtitle: Text(n.body, style: bodyStyle),
              trailing: Text(
                n.createdAt.toLocal().toString().substring(0, 16),
                style: timeStyle,
              ),
              onTap: () => _onTapNotification(index),
            ),
          );

          return Dismissible(
            key: ValueKey(n.id),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) {
              final removed = n;
              setState(() => _items.removeAt(index));
              _notifyUnreadChanged();
              _deleteNotification(removed, index);
            },
            child: tile,
          );
        },
      ),
    );
  }
}
