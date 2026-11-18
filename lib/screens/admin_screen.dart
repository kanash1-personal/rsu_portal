// lib/screens/admin_screen.dart
// Admin panel — direct CRUD over every table (profile, courses, assignments,
// calendar events, notifications). Reached from Profile → Quick Actions,
// gated by AppProvider.isAdmin. Not part of the bottom tab bar.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme.dart';

const _courseColors = ['#4F8EF7', '#22C55E', '#A855F7', '#F97316', '#EF4444', '#EC4899', '#14B8A6'];

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Admin Panel', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Courses'),
            Tab(text: 'Calendar'),
            Tab(text: 'Notifications'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _ProfileTab(),
          _CoursesTab(),
          _CalendarTab(),
          _NotificationsTab(),
        ],
      ),
    );
  }
}

// ─── Profile Tab ──────────────────────────────────────────────────────────────

class _ProfileTab extends StatefulWidget {
  const _ProfileTab();
  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  late TextEditingController _name, _email, _studentId, _major, _year, _phone,
      _address, _enrollStatus, _startDate, _graduation, _gpa;
  bool _loadedOnce = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _email = TextEditingController();
    _studentId = TextEditingController();
    _major = TextEditingController();
    _year = TextEditingController();
    _phone = TextEditingController();
    _address = TextEditingController();
    _enrollStatus = TextEditingController();
    _startDate = TextEditingController();
    _graduation = TextEditingController();
    _gpa = TextEditingController();
  }

  void _loadFrom(StudentProfile p) {
    _name.text = p.name;
    _email.text = p.email;
    _studentId.text = p.studentId;
    _major.text = p.major;
    _year.text = p.year;
    _phone.text = p.phone;
    _address.text = p.address;
    _enrollStatus.text = p.enrollmentStatus;
    _startDate.text = p.startDate;
    _graduation.text = p.expectedGraduation;
    _gpa.text = p.gpa.toStringAsFixed(2);
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _studentId, _major, _year, _phone, _address,
        _enrollStatus, _startDate, _graduation, _gpa]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save(AppProvider p) async {
    final current = p.profile!;
    await p.updateFullProfile(StudentProfile(
      uid: current.uid,
      name: _name.text.trim(),
      email: _email.text.trim(),
      studentId: _studentId.text.trim(),
      major: _major.text.trim(),
      year: _year.text.trim(),
      phone: _phone.text.trim(),
      address: _address.text.trim(),
      enrollmentStatus: _enrollStatus.text.trim(),
      startDate: _startDate.text.trim(),
      expectedGraduation: _graduation.text.trim(),
      gpa: double.tryParse(_gpa.text) ?? current.gpa,
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final profile = p.profile;
    if (profile == null) return const Center(child: CircularProgressIndicator());
    if (!_loadedOnce) {
      _loadFrom(profile);
      _loadedOnce = true;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _field(_name, 'Name'),
        _field(_email, 'Email'),
        _field(_studentId, 'Student ID'),
        _field(_major, 'Major'),
        _field(_year, 'Year'),
        _field(_phone, 'Phone'),
        _field(_address, 'Address'),
        _field(_enrollStatus, 'Enrollment Status'),
        _field(_startDate, 'Start Date'),
        _field(_graduation, 'Expected Graduation'),
        _field(_gpa, 'GPA', keyboard: TextInputType.number),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _save(p),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {TextInputType keyboard = TextInputType.text}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: ctrl,
          keyboardType: keyboard,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      );
}

// ─── Courses & Assignments Tab ───────────────────────────────────────────────

class _CoursesTab extends StatelessWidget {
  const _CoursesTab();

  @override
  Widget build(BuildContext context) {
    final courses = context.watch<AppProvider>().courses;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Courses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showCourseDialog(context, null),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Course'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
          ),
        ]),
        const SizedBox(height: 12),
        if (courses.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('No courses yet', style: TextStyle(color: AppTheme.textMuted)),
          )
        else
          for (final course in courses) ...[
            _AdminCourseCard(course: course),
            const SizedBox(height: 12),
          ],
      ]),
    );
  }

  static void _showCourseDialog(BuildContext context, Course? existing) {
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final instructorCtrl = TextEditingController(text: existing?.instructor ?? '');
    final timeCtrl = TextEditingController(text: existing?.time ?? '');
    final locationCtrl = TextEditingController(text: existing?.location ?? '');
    final daysCtrl = TextEditingController(text: existing?.days ?? '');
    final creditsCtrl = TextEditingController(text: existing?.credits.toString() ?? '3');
    String selectedColor = existing?.colorHex ?? _courseColors[0];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(existing != null ? 'Edit Course' : 'Add Course'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Expanded(child: _dlgField(codeCtrl, 'Code')),
                const SizedBox(width: 10),
                Expanded(child: _dlgField(creditsCtrl, 'Credits', keyboard: TextInputType.number)),
              ]),
              const SizedBox(height: 10),
              _dlgField(nameCtrl, 'Course Name'),
              const SizedBox(height: 10),
              _dlgField(instructorCtrl, 'Instructor'),
              const SizedBox(height: 10),
              _dlgField(timeCtrl, 'Time'),
              const SizedBox(height: 10),
              _dlgField(locationCtrl, 'Location'),
              const SizedBox(height: 10),
              _dlgField(daysCtrl, 'Days (e.g. Mon, Wed, Fri)'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _courseColors.map((hex) => GestureDetector(
                  onTap: () => setDialog(() => selectedColor = hex),
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: courseColor(hex), shape: BoxShape.circle,
                      border: selectedColor == hex ? Border.all(color: AppTheme.textPrimary, width: 2) : null,
                    ),
                    child: selectedColor == hex ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
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
                  assignments: existing?.assignments ?? const [],
                );
                if (existing != null) {
                  await p.updateCourse(course);
                } else {
                  await p.addCourse(course);
                }
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: Text(existing != null ? 'Save' : 'Add', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminCourseCard extends StatefulWidget {
  final Course course;
  const _AdminCourseCard({required this.course});
  @override
  State<_AdminCourseCard> createState() => _AdminCourseCardState();
}

class _AdminCourseCardState extends State<_AdminCourseCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(width: 10, height: 10, margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(color: courseColor(course.colorHex), shape: BoxShape.circle)),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(course.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              Text('${course.code} • ${course.assignments.length} assignments',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            ])),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.textMuted),
              onPressed: () => _CoursesTab._showCourseDialog(context, course),
            ),
            IconButton(
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 20, color: AppTheme.textMuted),
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
          ]),
        ),
        if (_expanded) ...[
          const Divider(height: 1, color: AppTheme.border),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              if (course.assignments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No assignments yet', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                )
              else
                for (final a in course.assignments) _AdminAssignmentRow(courseId: course.id, assignment: a),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showAssignmentDialog(context, course.id, null),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Assignment'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}

void _showAssignmentDialog(BuildContext context, String courseId, Assignment? existing) {
  final nameCtrl = TextEditingController(text: existing?.name ?? '');
  final weightCtrl = TextEditingController(text: existing != null ? (existing.weight * 100).toStringAsFixed(0) : '');
  final scoreCtrl = TextEditingController(text: existing?.score.toString() ?? '');
  final totalCtrl = TextEditingController(text: existing?.total.toString() ?? '100');
  final isEdit = existing != null;

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(isEdit ? 'Edit Assignment' : 'Add Assignment'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _dlgField(nameCtrl, 'Assignment Name'),
          const SizedBox(height: 10),
          _dlgField(weightCtrl, 'Weight (%)', keyboard: TextInputType.number),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _dlgField(scoreCtrl, 'Score', keyboard: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(child: _dlgField(totalCtrl, 'Out of', keyboard: TextInputType.number)),
          ]),
        ]),
      ),
      actions: [
        if (isEdit)
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AppProvider>().deleteAssignment(courseId, existing.id);
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.danger)),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            final name = nameCtrl.text.trim();
            if (name.isEmpty) return;
            final a = Assignment(
              id: existing?.id ?? 'a_${DateTime.now().millisecondsSinceEpoch}',
              name: name,
              weight: (double.tryParse(weightCtrl.text) ?? 0) / 100,
              score: int.tryParse(scoreCtrl.text) ?? 0,
              total: int.tryParse(totalCtrl.text) ?? 100,
            );
            final p = context.read<AppProvider>();
            if (isEdit) {
              await p.updateAssignment(courseId, a);
            } else {
              await p.addAssignment(courseId, a);
            }
            if (!context.mounted) return;
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
          child: Text(isEdit ? 'Save' : 'Add', style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

Widget _dlgField(TextEditingController ctrl, String label, {TextInputType keyboard = TextInputType.text}) =>
    TextField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );

class _AdminAssignmentRow extends StatelessWidget {
  final String courseId;
  final Assignment assignment;
  const _AdminAssignmentRow({required this.courseId, required this.assignment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${assignment.name} (${(assignment.weight * 100).toStringAsFixed(0)}%)',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          Text('${assignment.score}/${assignment.total}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        ])),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.textMuted),
          onPressed: () => _showAssignmentDialog(context, courseId, assignment),
          padding: EdgeInsets.zero, constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.danger),
          onPressed: () => context.read<AppProvider>().deleteAssignment(courseId, assignment.id),
          padding: EdgeInsets.zero, constraints: const BoxConstraints(),
        ),
      ]),
    );
  }
}

// ─── Calendar Tab ─────────────────────────────────────────────────────────────

class _CalendarTab extends StatelessWidget {
  const _CalendarTab();

  @override
  Widget build(BuildContext context) {
    final events = context.watch<AppProvider>().events;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Calendar Events', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showEventDialog(context, null),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
          ),
        ]),
        const SizedBox(height: 12),
        if (events.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('No events yet', style: TextStyle(color: AppTheme.textMuted)),
          )
        else
          for (final e in events) ...[
            AppCard(
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  Text('${_typeLabel(e.type)} • ${e.date.month}/${e.date.day}/${e.date.year} • ${e.time}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  if (e.courseCode.isNotEmpty)
                    Text(e.courseCode, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ])),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.textMuted),
                  onPressed: () => _showEventDialog(context, e),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.danger),
                  onPressed: () => context.read<AppProvider>().deleteCalendarEvent(e.id),
                ),
              ]),
            ),
            const SizedBox(height: 10),
          ],
      ]),
    );
  }

  static String _typeLabel(EventType t) => switch (t) {
        EventType.exam => 'Exam',
        EventType.assignment => 'Assignment',
        EventType.holiday => 'Holiday',
        EventType.event => 'Event',
      };

  static void _showEventDialog(BuildContext context, CalendarEvent? existing) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final courseCtrl = TextEditingController(text: existing?.courseCode ?? '');
    final timeCtrl = TextEditingController(text: existing?.time ?? '');
    DateTime date = existing?.date ?? DateTime.now();
    EventType type = existing?.type ?? EventType.event;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(existing != null ? 'Edit Event' : 'Add Event'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _dlgField(titleCtrl, 'Title'),
              const SizedBox(height: 10),
              _dlgField(courseCtrl, 'Course Code (optional)'),
              const SizedBox(height: 10),
              _dlgField(timeCtrl, 'Time (e.g. 9:00 AM)'),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx, initialDate: date,
                        firstDate: DateTime(2020), lastDate: DateTime(2100),
                      );
                      if (picked != null) setDialog(() => date = picked);
                    },
                    child: Text('${date.month}/${date.day}/${date.year}'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<EventType>(
                    initialValue: type,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    items: EventType.values
                        .map((t) => DropdownMenuItem(value: t, child: Text(_typeLabel(t))))
                        .toList(),
                    onChanged: (v) => setDialog(() => type = v ?? type),
                  ),
                ),
              ]),
            ]),
          ),
          actions: [
            if (existing != null)
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await context.read<AppProvider>().deleteCalendarEvent(existing.id);
                },
                child: const Text('Delete', style: TextStyle(color: AppTheme.danger)),
              ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                final p = context.read<AppProvider>();
                final event = CalendarEvent(
                  id: existing?.id ?? 'ev_${DateTime.now().millisecondsSinceEpoch}',
                  title: titleCtrl.text.trim(),
                  courseCode: courseCtrl.text.trim(),
                  time: timeCtrl.text.trim(),
                  date: date,
                  type: type,
                );
                if (existing != null) {
                  await p.updateCalendarEvent(event);
                } else {
                  await p.addCalendarEvent(event);
                }
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: Text(existing != null ? 'Save' : 'Add', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Notifications Tab ────────────────────────────────────────────────────────

class _NotificationsTab extends StatelessWidget {
  const _NotificationsTab();

  @override
  Widget build(BuildContext context) {
    final notifs = context.watch<AppProvider>().notifications;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showNotifDialog(context, null),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
          ),
        ]),
        const SizedBox(height: 12),
        if (notifs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('No notifications yet', style: TextStyle(color: AppTheme.textMuted)),
          )
        else
          for (final n in notifs) ...[
            AppCard(
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    if (!n.isRead) const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(Icons.circle, size: 7, color: AppTheme.primary),
                    ),
                  ]),
                  Text(n.body, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  Text('${n.type.name} • ${n.actionLabel}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ])),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.textMuted),
                  onPressed: () => _showNotifDialog(context, n),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.danger),
                  onPressed: () => context.read<AppProvider>().deleteNotification(n.id),
                ),
              ]),
            ),
            const SizedBox(height: 10),
          ],
      ]),
    );
  }

  static void _showNotifDialog(BuildContext context, AppNotification? existing) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final bodyCtrl = TextEditingController(text: existing?.body ?? '');
    final timeAgoCtrl = TextEditingController(text: existing?.timeAgo ?? 'Just now');
    final actionCtrl = TextEditingController(text: existing?.actionLabel ?? '');
    NotificationType type = existing?.type ?? NotificationType.info;
    bool isRead = existing?.isRead ?? false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(existing != null ? 'Edit Notification' : 'Add Notification'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _dlgField(titleCtrl, 'Title'),
              const SizedBox(height: 10),
              _dlgField(bodyCtrl, 'Body'),
              const SizedBox(height: 10),
              _dlgField(timeAgoCtrl, 'Time Ago (e.g. 2 hours ago)'),
              const SizedBox(height: 10),
              _dlgField(actionCtrl, 'Action Label (e.g. Grades)'),
              const SizedBox(height: 10),
              DropdownButtonFormField<NotificationType>(
                initialValue: type,
                decoration: InputDecoration(labelText: 'Type', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                items: NotificationType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                    .toList(),
                onChanged: (v) => setDialog(() => type = v ?? type),
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Read', style: TextStyle(fontSize: 14)),
                value: isRead,
                onChanged: (v) => setDialog(() => isRead = v),
              ),
            ]),
          ),
          actions: [
            if (existing != null)
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await context.read<AppProvider>().deleteNotification(existing.id);
                },
                child: const Text('Delete', style: TextStyle(color: AppTheme.danger)),
              ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                final p = context.read<AppProvider>();
                final notif = AppNotification(
                  id: existing?.id ?? 'n_${DateTime.now().millisecondsSinceEpoch}',
                  title: titleCtrl.text.trim(),
                  body: bodyCtrl.text.trim(),
                  timeAgo: timeAgoCtrl.text.trim(),
                  type: type,
                  actionLabel: actionCtrl.text.trim(),
                  isRead: isRead,
                );
                if (existing != null) {
                  await p.updateNotification(notif);
                } else {
                  await p.addNotification(notif);
                }
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: Text(existing != null ? 'Save' : 'Add', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
