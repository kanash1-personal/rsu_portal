// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme.dart';
import 'main_nav.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final profile = p.profile;
    final courses = p.courses;
    final events = p.events;
    final notifs = p.notifications;
    final now = DateTime.now();

    // Today's classes
    final dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final todayAbbr = dayNames[now.weekday];
    final todayCourses = courses.where((c) => c.days.contains(todayAbbr)).toList();

    // Upcoming events (next 7 days)
    final upcoming = events.where((e) {
      final diff = e.date.difference(now).inDays;
      return diff >= 0 && diff <= 7;
    }).toList()..sort((a, b) => a.date.compareTo(b.date));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: AppTheme.textPrimary),
            onPressed: () => _showMenu(context),
          ),
        ],
      ),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Welcome back, ${profile.name.split(' ').first}!',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                  Text(_formatDate(now),
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  const SizedBox(height: 20),

                  // Stat cards
                  Row(children: [
                    Expanded(child: _StatCard(label: 'Current GPA', value: profile.gpa.toStringAsFixed(2),
                        sub: 'Semester GPA', icon: Icons.emoji_events_outlined, onTap: () => MainNav.of(context).goTo(2))),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(label: 'Classes Today', value: '${todayCourses.length}',
                        sub: '${_dayName(now.weekday)} schedule', icon: Icons.calendar_today_outlined, onTap: () => MainNav.of(context).goTo(1))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _StatCard(label: 'Upcoming Events', value: '${upcoming.length}',
                        sub: 'Next 7 days', icon: Icons.bookmark_outline, onTap: () => MainNav.of(context).goTo(3))),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(label: 'Notifications', value: '${p.unreadCount}',
                        sub: 'Unread messages', icon: Icons.notifications_outlined, onTap: () => MainNav.of(context).goTo(4))),
                  ]),
                  const SizedBox(height: 20),

                  // Today's schedule
                  _SectionHeader(title: "Today's Schedule", actionText: 'View All',
                      icon: Icons.calendar_today_outlined, onAction: () => MainNav.of(context).goTo(1)),
                  const SizedBox(height: 10),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: todayCourses.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('No classes today', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                          )
                        : Column(
                            children: [
                              for (int i = 0; i < todayCourses.length; i++) ...[
                                if (i > 0) const Divider(height: 20, color: AppTheme.border),
                                _ScheduleItem(course: todayCourses[i], onTap: () => MainNav.of(context).goTo(1)),
                              ],
                            ],
                          ),
                  ),
                  const SizedBox(height: 20),

                  // Recent grades
                  _SectionHeader(title: 'Recent Grades', actionText: 'View All',
                      icon: Icons.trending_up, onAction: () => MainNav.of(context).goTo(2)),
                  const SizedBox(height: 10),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: courses.isEmpty
                        ? const Text('No grades yet', style: TextStyle(color: AppTheme.textMuted))
                        : Column(
                            children: [
                              for (int i = 0; i < courses.length && i < 3; i++) ...[
                                if (i > 0) const Divider(height: 16, color: AppTheme.border),
                                _GradeItem(course: courses[i], provider: p,
                                    onTap: () => MainNav.of(context).goTo(2)),
                              ],
                            ],
                          ),
                  ),
                  const SizedBox(height: 20),

                  // Upcoming events
                  _SectionHeader(title: 'Upcoming Events', actionText: 'View Calendar',
                      icon: Icons.bookmark_outline, onAction: () => MainNav.of(context).goTo(3)),
                  const SizedBox(height: 10),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: upcoming.isEmpty
                        ? const Text('No upcoming events', style: TextStyle(color: AppTheme.textMuted))
                        : Column(
                            children: [
                              for (int i = 0; i < upcoming.length && i < 3; i++) ...[
                                if (i > 0) const Divider(height: 16, color: AppTheme.border),
                                _EventItem(event: upcoming[i], now: now,
                                    onTap: () => MainNav.of(context).goTo(3)),
                              ],
                            ],
                          ),
                  ),
                  const SizedBox(height: 20),

                  // Recent notifications
                  _SectionHeader(title: 'Recent Notifications', actionText: 'View All',
                      icon: Icons.notifications_outlined, onAction: () => MainNav.of(context).goTo(4)),
                  const SizedBox(height: 10),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: notifs.isEmpty
                        ? const Text('No notifications', style: TextStyle(color: AppTheme.textMuted))
                        : Column(
                            children: [
                              for (int i = 0; i < notifs.length && i < 2; i++) ...[
                                if (i > 0) const Divider(height: 16, color: AppTheme.border),
                                GestureDetector(
                                  onTap: () => MainNav.of(context).goTo(4),
                                  child: _NotifItem(notif: notifs[i]),
                                ),
                              ],
                            ],
                          ),
                  ),
                  const SizedBox(height: 20),

                  // Quick actions
                  const Text('Quick Actions',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  const SizedBox(height: 10),
                  _QuickActionButton(icon: Icons.calendar_today_outlined, label: 'View Schedule', onTap: () => MainNav.of(context).goTo(1)),
                  const SizedBox(height: 8),
                  _QuickActionButton(icon: Icons.trending_up, label: 'Check Grades', onTap: () => MainNav.of(context).goTo(2)),
                  const SizedBox(height: 8),
                  _QuickActionButton(icon: Icons.event_outlined, label: 'View Calendar', onTap: () => MainNav.of(context).goTo(3)),
                  const SizedBox(height: 8),
                  _QuickActionButton(icon: Icons.person_outline, label: 'My Profile', onTap: () => MainNav.of(context).goTo(5)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  String _formatDate(DateTime dt) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'];
    return '${days[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _dayName(int weekday) {
    const names = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return names[weekday];
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _MenuSheet(),
    );
  }
}

// ─── Menu Sheet ──────────────────────────────────────────────────────────────
class _MenuSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_outlined, 'Home', 0),
      (Icons.calendar_today_outlined, 'My Schedule', 1),
      (Icons.bar_chart_outlined, 'My Grades', 2),
      (Icons.event_outlined, 'Academic Calendar', 3),
      (Icons.notifications_outlined, 'Notifications', 4),
      (Icons.person_outline, 'My Profile', 5),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Navigation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          for (final item in items)
            ListTile(
              leading: Icon(item.$1, color: AppTheme.primary),
              title: Text(item.$2, style: const TextStyle(fontWeight: FontWeight.w600)),
              onTap: () { Navigator.pop(context); MainNav.of(context).goTo(item.$3); },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final VoidCallback onTap;
  const _StatCard({required this.label, required this.value, required this.sub, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
              Icon(icon, size: 16, color: AppTheme.textMuted),
            ]),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            Text(sub, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ]),
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  final String title, actionText;
  final IconData icon;
  final VoidCallback onAction;
  const _SectionHeader({required this.title, required this.actionText, required this.icon, required this.onAction});

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 18, color: AppTheme.textPrimary),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const Spacer(),
        GestureDetector(onTap: onAction, child: Row(children: [
          Text(actionText, style: const TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w500)),
          const Icon(Icons.chevron_right, size: 16, color: AppTheme.primary),
        ])),
      ]);
}

class _ScheduleItem extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;
  const _ScheduleItem({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Row(children: [
          Container(width: 3, height: 50,
              decoration: BoxDecoration(color: courseColor(course.colorHex), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(course.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            Text(course.code, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            Row(children: [
              const Icon(Icons.access_time, size: 12, color: AppTheme.textMuted), const SizedBox(width: 3),
              Text(course.time, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ]),
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 12, color: AppTheme.textMuted), const SizedBox(width: 3),
              Text(course.location, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ]),
          ])),
          const Icon(Icons.chevron_right, size: 16, color: AppTheme.textMuted),
        ]),
      );
}

class _GradeItem extends StatelessWidget {
  final Course course;
  final AppProvider provider;
  final VoidCallback onTap;
  const _GradeItem({required this.course, required this.provider, required this.onTap});

  double get _score {
    if (course.assignments.isEmpty) return 0;
    return course.assignments.fold(0.0, (s, a) => s + a.percentage * a.weight);
  }

  @override
  Widget build(BuildContext context) {
    final grade = provider.gradeFromScore(_score);
    final color = grade.startsWith('A') ? AppTheme.success : grade.startsWith('B') ? AppTheme.primary : AppTheme.warning;
    return GestureDetector(
      onTap: onTap,
      child: Row(children: [
        Container(width: 10, height: 10, margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(color: courseColor(course.colorHex), shape: BoxShape.circle)),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(course.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          Text(course.code, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(grade, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          Text('${(_score * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ]),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right, size: 16, color: AppTheme.textMuted),
      ]),
    );
  }
}

class _EventItem extends StatelessWidget {
  final CalendarEvent event;
  final DateTime now;
  final VoidCallback onTap;
  const _EventItem({required this.event, required this.now, required this.onTap});

  Color get _badgeColor {
    switch (event.type) {
      case EventType.exam:       return AppTheme.danger;
      case EventType.assignment: return AppTheme.primary;
      case EventType.holiday:    return AppTheme.success;
      default:                   return AppTheme.purple;
    }
  }

  String get _badge {
    final diff = event.date.difference(now).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return 'In $diff days';
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(event.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            if (event.courseCode.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 3, bottom: 3),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(4)),
                child: Text(event.courseCode, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
              ),
            Row(children: [
              const Icon(Icons.access_time, size: 12, color: AppTheme.textMuted), const SizedBox(width: 3),
              Text(event.time, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ]),
          ])),
          Text(_badge, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _badgeColor)),
        ]),
      );
}

class _NotifItem extends StatelessWidget {
  final AppNotification notif;
  const _NotifItem({required this.notif});

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(notif.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          Text(notif.body, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          Text(notif.timeAgo, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        ])),
        if (!notif.isRead)
          Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 4),
              decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle)),
      ]);
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.border)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Icon(icon, size: 18, color: AppTheme.primary),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
              const Spacer(),
              const Icon(Icons.chevron_right, size: 16, color: AppTheme.textMuted),
            ]),
          ),
        ),
      );
}
