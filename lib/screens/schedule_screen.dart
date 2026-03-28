// lib/screens/schedule_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme.dart';
import 'main_nav.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        actions: [
          IconButton(
            icon: Icon(Icons.menu, color: AppTheme.textPrimary(context)),
            onPressed: () => _showMenu(context),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMuted(context),
          indicatorColor: AppTheme.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [Tab(text: 'Weekly'), Tab(text: 'Courses')],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [const _WeeklyTab(), _CoursesTab()],
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _QuickNavSheet(),
    );
  }
}

// ─── Weekly Tab ───────────────────────────────────────────────────────────────

class _WeeklyTab extends StatelessWidget {
  const _WeeklyTab();

  @override
  Widget build(BuildContext context) {
    final schedule = context.watch<AppProvider>().weeklySchedule;
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('My Schedule', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context))),
        Text('Spring 2026 Semester', style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13)),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border(context))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.textPrimary(context)),
                const SizedBox(width: 6),
                const Text('Weekly Schedule', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ]),
            ),
            for (final day in days)
              if ((schedule[day] ?? []).isNotEmpty) ...[
                _DayHeader(day: day),
                for (final entry in schedule[day]!)
                  _ScheduleBlock(entry: entry),
              ],
            const SizedBox(height: 8),
          ]),
        ),
      ]),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final String day;
  const _DayHeader({required this.day});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: AppTheme.background(context),
        child: Text(day, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary(context))),
      );
}

class _ScheduleBlock extends StatelessWidget {
  final ScheduleEntry entry;
  const _ScheduleBlock({required this.entry});

  @override
  Widget build(BuildContext context) {
    final courses = context.watch<AppProvider>().courses;
    Color blockColor = AppTheme.primary;
    if (courses.isNotEmpty) {
      try {
        final c = courses.firstWhere((c) => c.code == entry.courseCode);
        blockColor = courseColor(c.colorHex);
      } catch (_) {}
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: blockColor, borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(entry.courseCode, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
        Text(entry.time, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
        Text(entry.location, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
      ]),
    );
  }
}

// ─── Courses Tab ──────────────────────────────────────────────────────────────

class _CoursesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final courses = context.watch<AppProvider>().courses;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Course Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context))),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showCourseDialog(context, null),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
          ),
        ]),
        const SizedBox(height: 16),
        if (courses.isEmpty)
          Center(
            child: Column(children: [
              const SizedBox(height: 32),
              Icon(Icons.school_outlined, size: 48, color: AppTheme.textMuted(context)),
              const SizedBox(height: 12),
              Text('No courses yet', style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 15)),
              const SizedBox(height: 8),
              TextButton(onPressed: () => _showCourseDialog(context, null), child: const Text('Add your first course')),
            ]),
          )
        else
          for (final course in courses) ...[
            _CourseCard(course: course),
            const SizedBox(height: 12),
          ],
      ]),
    );
  }

  static const _colors = ['#4F8EF7', '#22C55E', '#A855F7', '#F97316', '#EF4444', '#EC4899', '#14B8A6'];

  static void _showCourseDialog(BuildContext context, Course? existing) {
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final instructorCtrl = TextEditingController(text: existing?.instructor ?? '');
    final timeCtrl = TextEditingController(text: existing?.time ?? '');
    final locationCtrl = TextEditingController(text: existing?.location ?? '');
    final daysCtrl = TextEditingController(text: existing?.days ?? '');
    final creditsCtrl = TextEditingController(text: existing?.credits.toString() ?? '3');
    String selectedColor = existing?.colorHex ?? _colors[0];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(existing != null ? 'Edit Course' : 'Add Course'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Expanded(child: _field(codeCtrl, 'Code (e.g. CS 201)')),
                const SizedBox(width: 10),
                Expanded(child: _field(creditsCtrl, 'Credits', keyboard: TextInputType.number)),
              ]),
              const SizedBox(height: 10),
              _field(nameCtrl, 'Course Name'),
              const SizedBox(height: 10),
              _field(instructorCtrl, 'Instructor'),
              const SizedBox(height: 10),
              _field(timeCtrl, 'Time (e.g. 9:00 AM - 10:30 AM)'),
              const SizedBox(height: 10),
              _field(locationCtrl, 'Location'),
              const SizedBox(height: 10),
              _field(daysCtrl, 'Days (e.g. Mon, Wed, Fri)'),
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerLeft,
                child: Text('Color', style: TextStyle(fontSize: 12, color: AppTheme.textMuted(ctx)))),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _colors.map((hex) => GestureDetector(
                  onTap: () => setDialog(() => selectedColor = hex),
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: courseColor(hex), shape: BoxShape.circle,
                      border: selectedColor == hex
                          ? Border.all(color: AppTheme.textPrimary(ctx), width: 2)
                          : null,
                    ),
                    child: selectedColor == hex
                        ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                  ),
                )).toList(),
              ),
            ]),
          ),
          actions: [
            if (existing != null)
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await context.read<AppProvider>().deleteCourse(existing.id);
                },
                child: const Text('Delete', style: TextStyle(color: AppTheme.danger)),
              ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (codeCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) return;
                final p = context.read<AppProvider>();
                final course = Course(
                  id: existing?.id ?? 'c_${DateTime.now().millisecondsSinceEpoch}',
                  code: codeCtrl.text.trim(), name: nameCtrl.text.trim(),
                  instructor: instructorCtrl.text.trim(), time: timeCtrl.text.trim(),
                  location: locationCtrl.text.trim(), days: daysCtrl.text.trim(),
                  credits: int.tryParse(creditsCtrl.text) ?? 3,
                  colorHex: selectedColor,
                );
                if (existing != null) {
                  await p.updateCourse(course);
                } else {
                  await p.addCourse(course);
                }
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: Text(existing != null ? 'Save' : 'Add', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _field(TextEditingController ctrl, String label,
          {TextInputType keyboard = TextInputType.text}) =>
      TextField(
        controller: ctrl, keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      );
}

class _CourseCard extends StatelessWidget {
  final Course course;
  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final color = courseColor(course.colorHex);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border(context))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(course.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
            Text(course.code, style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context), fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            _infoRow(context, Icons.access_time_outlined, course.time),
            _infoRow(context, Icons.location_on_outlined, course.location),
            _infoRow(context, Icons.calendar_today_outlined, course.days),
            _infoRow(context, Icons.person_outline, 'Instructor: ${course.instructor}'),
          ]),
        ),
        Column(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _CoursesTab._showCourseDialog(context, course),
            child: Icon(Icons.edit_outlined, size: 16, color: AppTheme.textMuted(context)),
          ),
        ]),
      ]),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(children: [
          Icon(icon, size: 13, color: AppTheme.textMuted(context)), const SizedBox(width: 5),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context)))),
        ]),
      );
}

// ─── Nav Sheet ────────────────────────────────────────────────────────────────

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
