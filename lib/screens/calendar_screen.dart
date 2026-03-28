// lib/screens/calendar_screen.dart
import 'package:flutter/material.dart';
import '../theme.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import 'main_nav.dart';

// Pure Dart date formatting — no intl package needed
String _formatMonthYear(DateTime dt) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  return '${months[dt.month - 1]} ${dt.year}';
}

String _formatFullDate(DateTime dt) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focused = DateTime(2026, 3);
  DateTime? _selected;

  List<CalendarEvent> _eventsForDay(DateTime day) {
    return context.watch<AppProvider>().events
        .where((e) =>
            e.date.year == day.year &&
            e.date.month == day.month &&
            e.date.day == day.day)
        .toList();
  }

  Color _eventDotColor(EventType type) {
    switch (type) {
      case EventType.exam:       return AppTheme.danger;
      case EventType.assignment: return AppTheme.primary;
      case EventType.event:      return AppTheme.purple;
      case EventType.holiday:    return AppTheme.success;
    }
  }

  void _prevMonth() => setState(() =>
      _focused = DateTime(_focused.year, _focused.month - 1));
  void _nextMonth() => setState(() =>
      _focused = DateTime(_focused.year, _focused.month + 1));

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDay = DateTime(_focused.year, _focused.month, 1);
    final daysInMonth = DateTime(_focused.year, _focused.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0=Sun

    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(12),
          child: GestureDetector(
            onTap: () => MainNav.of(context).goTo(0),
            child: Container(
              decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.school, color: Colors.white, size: 18),
            ),
          ),
        ),
        title: const Text('Student Portal',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        actions: [

          IconButton(
            icon: Icon(Icons.menu, color: AppTheme.textPrimary(context)),
            onPressed: () => showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              builder: (_) => _QuickNavSheet(),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Academic Calendar',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary(context))),
            Text('Spring 2026 Semester',
                style:
                    TextStyle(color: AppTheme.textSecondary(context), fontSize: 13)),
            const SizedBox(height: 16),

            // Legend
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border(context)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _LegendDot(label: 'Exams', color: AppTheme.danger),
                  _LegendDot(label: 'Assignments', color: AppTheme.primary),
                  _LegendDot(label: 'Events', color: AppTheme.purple),
                  _LegendDot(label: 'Holidays', color: AppTheme.success),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Calendar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border(context)),
              ),
              child: Column(
                children: [
                  // Month header
                  Row(
                    children: [
                      Text(
                        _formatMonthYear(_focused),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: () => setState(() {
                          _focused = DateTime(now.year, now.month);
                          _selected = now;
                        }),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          side: BorderSide(color: AppTheme.border(context)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                        child: Text('Today',
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.textPrimary(context))),
                      ),
                      const SizedBox(width: 6),
                      _NavBtn(icon: Icons.chevron_left, onTap: _prevMonth),
                      const SizedBox(width: 4),
                      _NavBtn(icon: Icons.chevron_right, onTap: _nextMonth),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Weekday labels
                  Row(
                    children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                        .map((d) => Expanded(
                              child: Center(
                                child: Text(d,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textMuted(context))),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 8),

                  // Days grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                    ),
                    itemCount: startWeekday + daysInMonth,
                    itemBuilder: (ctx, i) {
                      if (i < startWeekday) return const SizedBox();
                      final day = DateTime(
                          _focused.year, _focused.month, i - startWeekday + 1);
                      final isToday = day.year == now.year &&
                          day.month == now.month &&
                          day.day == now.day;
                      final isSelected = _selected != null &&
                          _selected!.year == day.year &&
                          _selected!.month == day.month &&
                          _selected!.day == day.day;
                      final events = _eventsForDay(day);

                      return GestureDetector(
                        onTap: () => setState(() => _selected = day),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primary
                                    : isToday
                                        ? AppTheme.primaryLight
                                        : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isToday || isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? Colors.white
                                        : isToday
                                            ? AppTheme.primary
                                            : AppTheme.textPrimary(context),
                                  ),
                                ),
                              ),
                            ),
                            if (events.isNotEmpty)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: events
                                    .take(2)
                                    .map((e) => Container(
                                          width: 5,
                                          height: 5,
                                          margin: const EdgeInsets.only(
                                              top: 2, left: 1, right: 1),
                                          decoration: BoxDecoration(
                                            color: _eventDotColor(e.type),
                                            shape: BoxShape.circle,
                                          ),
                                        ))
                                    .toList(),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Selected date panel
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border(context)),
              ),
              child: _selected == null
                  ? Column(
                      children: [
                        const SizedBox(height: 8),
                        const Text('Select a Date',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 24),
                        Text('Tap on a date to view events',
                            style: TextStyle(
                                fontSize: 13, color: AppTheme.textMuted(context))),
                        const SizedBox(height: 24),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatFullDate(_selected!),
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        if (_eventsForDay(_selected!).isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text('No events on this date',
                                style: TextStyle(
                                    fontSize: 13, color: AppTheme.textMuted(context))),
                          )
                        else
                          for (final e in _eventsForDay(_selected!))
                            _EventTile(event: e),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets ─────────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: AppTheme.textSecondary(context))),
      ],
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.border(context)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 18, color: AppTheme.textPrimary(context)),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final CalendarEvent event;
  const _EventTile({required this.event});

  Color get _typeColor {
    switch (event.type) {
      case EventType.exam:       return AppTheme.danger;
      case EventType.assignment: return AppTheme.primary;
      case EventType.event:      return AppTheme.purple;
      case EventType.holiday:    return AppTheme.success;
    }
  }

  String get _typeLabel {
    switch (event.type) {
      case EventType.exam:       return 'Exam';
      case EventType.assignment: return 'Assignment';
      case EventType.event:      return 'Event';
      case EventType.holiday:    return 'Holiday';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
                color: _typeColor, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                if (event.courseCode.isNotEmpty)
                  Text(event.courseCode,
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textMuted(context))),
                Row(children: [
                  Icon(Icons.access_time,
                      size: 12, color: AppTheme.textMuted(context)),
                  const SizedBox(width: 3),
                  Text(event.time,
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary(context))),
                ]),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(_typeLabel,
                style: TextStyle(
                    fontSize: 11,
                    color: _typeColor,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _QuickNavSheet extends StatelessWidget {
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
          const Text('Navigation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          for (final item in items)
            ListTile(
              leading: Icon(item.$1, color: AppTheme.primary),
              title: Text(item.$2,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                MainNav.of(context).goTo(item.$3);
              },
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
        ],
      ),
    );
  }
}
