// lib/screens/grades_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme.dart';
import 'main_nav.dart';

class GradesScreen extends StatelessWidget {
  const GradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My Grades', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context))),
            Text('Spring 2026 Semester', style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13)),
            const SizedBox(height: 16),

            // Stats
            Row(children: [
              Expanded(child: _StatBox(label: 'Current GPA', value: (p.profile?.gpa ?? 0.0).toStringAsFixed(2), sub: 'Semester GPA', icon: Icons.emoji_events_outlined)),
              const SizedBox(width: 12),
              Expanded(child: _StatBox(label: 'Total Credits', value: '${p.totalCredits}', sub: 'Credits enrolled', icon: Icons.trending_up)),
            ]),
            const SizedBox(height: 12),
            _StatBox(label: 'Courses', value: '${p.courses.length}', sub: 'Active courses', icon: Icons.book_outlined, full: true),
            const SizedBox(height: 20),

            for (final course in p.courses) ...[
              _CourseGradeCard(course: course),
              const SizedBox(height: 14),
            ],
          ],
        ),
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

// ─── Stat Box ─────────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final bool full;
  const _StatBox({required this.label, required this.value, required this.sub, required this.icon, this.full = false});

  @override
  Widget build(BuildContext context) => Container(
        width: full ? double.infinity : null,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border(context))),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context), fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context))),
            Text(sub, style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context))),
          ]),
          Icon(icon, size: 18, color: AppTheme.textMuted(context)),
        ]),
      );
}

// ─── Course Grade Card ────────────────────────────────────────────────────────

class _CourseGradeCard extends StatefulWidget {
  final Course course;
  const _CourseGradeCard({required this.course});

  @override
  State<_CourseGradeCard> createState() => _CourseGradeCardState();
}

class _CourseGradeCardState extends State<_CourseGradeCard> {
  bool _expanded = false;

  double get _weightedScore {
    if (widget.course.assignments.isEmpty) return 0;
    return widget.course.assignments.fold(0.0, (s, a) => s + a.percentage * a.weight);
  }

  String get _grade => context.read<AppProvider>().gradeFromScore(_weightedScore);

  Color get _gradeColor {
    final g = _grade;
    if (g.startsWith('A')) return AppTheme.success;
    if (g.startsWith('B')) return AppTheme.primary;
    return AppTheme.warning;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border(context))),
      child: Column(
        children: [
          // Header row — tap to expand
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 10, height: 10, margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(color: courseColor(widget.course.colorHex), shape: BoxShape.circle)),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.course.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    Text('${widget.course.code} • ${widget.course.credits} Credits',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context))),
                  ])),
                  Text(_grade, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _gradeColor)),
                  const SizedBox(width: 8),
                  Text('${(_weightedScore * 100).toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary(context))),
                  const SizedBox(width: 4),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      size: 18, color: AppTheme.textMuted(context)),
                ]),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _weightedScore,
                    backgroundColor: AppTheme.border(context),
                    valueColor: AlwaysStoppedAnimation<Color>(courseColor(widget.course.colorHex)),
                    minHeight: 6,
                  ),
                ),
              ]),
            ),
          ),

          // Expanded: assignments list + add button
          if (_expanded) ...[
            Divider(height: 1, color: AppTheme.border(context)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (widget.course.assignments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('No assignments yet', style: TextStyle(color: AppTheme.textMuted(context), fontSize: 13)),
                    )
                  else
                    for (final a in widget.course.assignments)
                      _AssignmentRow(
                        assignment: a,
                        courseId: widget.course.id,
                        onEdit: () => _showEditAssignment(context, a),
                        onDelete: () => _confirmDelete(context, a),
                        context: context,
                      ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showAddAssignment(context),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Assignment'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddAssignment(BuildContext context) {
    _showAssignmentDialog(context, null);
  }

  void _showEditAssignment(BuildContext context, Assignment a) {
    _showAssignmentDialog(context, a);
  }

  void _showAssignmentDialog(BuildContext context, Assignment? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final weightCtrl = TextEditingController(
        text: existing != null ? (existing.weight * 100).toStringAsFixed(0) : '');
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
            _field(nameCtrl, 'Assignment Name'),
            const SizedBox(height: 10),
            _field(weightCtrl, 'Weight (%)', keyboard: TextInputType.number),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _field(scoreCtrl, 'Score', keyboard: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: _field(totalCtrl, 'Out of', keyboard: TextInputType.number)),
            ]),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final weight = double.tryParse(weightCtrl.text) ?? 0;
              final score = int.tryParse(scoreCtrl.text) ?? 0;
              final total = int.tryParse(totalCtrl.text) ?? 100;
              if (name.isEmpty) return;

              final p = context.read<AppProvider>();
              final a = Assignment(
                id: existing?.id ?? 'a_${DateTime.now().millisecondsSinceEpoch}',
                name: name, weight: weight / 100, score: score, total: total,
              );

              if (isEdit) {
                await p.updateAssignment(widget.course.id, a);
              } else {
                await p.addAssignment(widget.course.id, a);
              }

              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: Text(isEdit ? 'Save' : 'Add', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Assignment a) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Assignment'),
        content: Text('Delete "${a.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
          onPressed: () async {
            if (mounted) {
              Navigator.pop(context);
            }
            await context.read<AppProvider>().deleteAssignment(widget.course.id, a.id);
          },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {TextInputType keyboard = TextInputType.text}) =>
      TextField(
        controller: ctrl,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      );
}

// ─── Assignment Row ───────────────────────────────────────────────────────────

class _AssignmentRow extends StatelessWidget {
  final Assignment assignment;
  final String courseId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final BuildContext context;
  const _AssignmentRow({required this.assignment, required this.courseId, required this.onEdit, required this.onDelete, required this.context});

  @override
  Widget build(BuildContext context) {
    final pct = assignment.percentage;
    final weightPct = (assignment.weight * 100).toStringAsFixed(0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${assignment.name} ($weightPct%)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary(context))),
          Text('${assignment.score}/${assignment.total}  (${(pct * 100).toStringAsFixed(1)}%)',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context))),
        ])),
        IconButton(icon: Icon(Icons.edit_outlined, size: 16, color: AppTheme.textMuted(context)), onPressed: onEdit, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        const SizedBox(width: 8),
        IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.danger), onPressed: onDelete, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
      ]),
    );
  }
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
