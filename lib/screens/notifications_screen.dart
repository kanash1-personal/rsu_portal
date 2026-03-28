// lib/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme.dart';
import 'main_nav.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _showUnread = false;

  Color _notifColor(NotificationType type, BuildContext context) {
    switch (type) {
      case NotificationType.grade:     return AppTheme.success;
      case NotificationType.deadline:  return AppTheme.warning;
      case NotificationType.cancelled: return AppTheme.danger;
      case NotificationType.info:      return AppTheme.primary;
    }
  }

  IconData _notifIcon(NotificationType type) {
    switch (type) {
      case NotificationType.grade:     return Icons.check_circle_outline;
      case NotificationType.deadline:  return Icons.warning_amber_outlined;
      case NotificationType.cancelled: return Icons.cancel_outlined;
      case NotificationType.info:      return Icons.info_outline;
    }
  }

  void _handleAction(BuildContext context, String label) {
    final map = {'Grades': 2, 'Assignments': 2, 'Schedule': 1, 'Calendar': 3, 'Courses': 1};
    final idx = map[label];
    if (idx != null) MainNav.of(context).goTo(idx);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final all = p.notifications;
    final filtered = _showUnread ? all.where((n) => !n.isRead).toList() : all;
    final unreadCount = p.unreadCount;

    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(12),
          child: GestureDetector(
            onTap: () => MainNav.of(context).goTo(0),
            child: Container(
              decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.school, color: Colors.white, size: 18),
            ),
          ),
        ),
        title: const Text('Student Portal', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: Icon(Icons.menu, color: AppTheme.textPrimary(context)),
            onPressed: () => _showMenuSheet(context))],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Notifications',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context))),
                Text('$unreadCount unread notification${unreadCount == 1 ? '' : 's'}',
                    style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13)),
              ]),
              const Spacer(),
              if (unreadCount > 0)
                TextButton(
                  onPressed: () => p.markAllNotificationsRead(),
                  style: TextButton.styleFrom(
                    backgroundColor: AppTheme.background(context),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), side: BorderSide(color: AppTheme.border(context))),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: Text('Mark all as read', style: TextStyle(fontSize: 12, color: AppTheme.textPrimary(context))),
                ),
            ]),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              _TabChip(label: 'All', count: all.length, active: !_showUnread,
                  onTap: () => setState(() => _showUnread = false)),
              const SizedBox(width: 8),
              _TabChip(label: 'Unread', count: unreadCount, active: _showUnread,
                  onTap: () => setState(() => _showUnread = true)),
            ]),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filtered.isEmpty
                ? _EmptyState(isUnread: _showUnread)
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final n = filtered[i];
                      return Dismissible(
                        key: ValueKey(n.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(color: AppTheme.danger, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                        onDismissed: (_) => p.deleteNotification(n.id),
                        child: _NotifCard(
                          notif: n,
                          iconColor: _notifColor(n.type, context),
                          icon: _notifIcon(n.type),
                          onTap: () => p.markNotificationRead(n.id),
                          onActionTap: () => _handleAction(context, n.actionLabel),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showMenuSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _QuickNavSheet(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isUnread;
  const _EmptyState({required this.isUnread});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.notifications_none, size: 56, color: AppTheme.textMuted(context).withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(isUnread ? 'No unread notifications' : 'No notifications',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textSecondary(context))),
          const SizedBox(height: 4),
          Text("You're all caught up!", style: TextStyle(fontSize: 13, color: AppTheme.textMuted(context))),
        ]),
      );
}

class _TabChip extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;
  const _TabChip({required this.label, required this.count, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: active ? AppTheme.primary: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? AppTheme.primary : AppTheme.border(context)),
          ),
          child: Row(children: [
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppTheme.textPrimary(context))),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: active ? Colors.white.withValues(alpha: 0.2) : AppTheme.background(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: active ? Colors.white : AppTheme.textSecondary(context))),
            ),
          ]),
        ),
      );
}

class _NotifCard extends StatelessWidget {
  final AppNotification notif;
  final Color iconColor;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onActionTap;
  const _NotifCard({required this.notif, required this.iconColor, required this.icon,
      required this.onTap, required this.onActionTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: notif.isRead ? Colors.white : const Color(0xFFF0F6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: iconColor, width: 4),
                right: BorderSide(color: AppTheme.border(context)), top: BorderSide(color: AppTheme.border(context)),
                bottom: BorderSide(color: AppTheme.border(context))),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(notif.title,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context)))),
                if (!notif.isRead)
                  Container(width: 8, height: 8, margin: const EdgeInsets.only(left: 6),
                      decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle)),
              ]),
              const SizedBox(height: 3),
              Text(notif.body, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary(context))),
              const SizedBox(height: 6),
              Row(children: [
                Text(notif.timeAgo, style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context))),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onActionTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppTheme.background(context), borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.border(context))),
                    child: Text(notif.actionLabel,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                  ),
                ),
              ]),
            ])),
          ]),
        ),
      );
}

class _QuickNavSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [(Icons.home_outlined, 'Home', 0), (Icons.calendar_today_outlined, 'My Schedule', 1),
        (Icons.bar_chart_outlined, 'My Grades', 2), (Icons.event_outlined, 'Academic Calendar', 3),
        (Icons.notifications_outlined, 'Notifications', 4), (Icons.person_outline, 'My Profile', 5)];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Navigation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        for (final item in items)
          ListTile(
            leading: Icon(item.$1, color: AppTheme.primary),
            title: Text(item.$2, style: const TextStyle(fontWeight: FontWeight.w600)),
            onTap: () { Navigator.pop(context); MainNav.of(context).goTo(item.$3); },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
      ]),
    );
  }
}
