// lib/screens/grades_screen.dart
import 'package:flutter/material.dart';
import '../theme.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import 'main_nav.dart';

class GradesScreen extends StatelessWidget {
  const GradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 4),
            const Text('My Grades', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            const Text('Spring 2026 Semester', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),

            // Stats
            Row(
              children: [
                Expanded(child: _StatBox(label: 'Current GPA', value: '3.77', sub: 'Semester GPA', icon: Icons.emoji_events_outlined)),
                const SizedBox(width: 12),
                Expanded(child: _StatBox(label: 'Total Credits', value: context.watch<AppProvider>().totalCredits.toString(), sub: 'Credits enrolled', icon: Icons.trending_up)),
              ],
            ),
            const SizedBox(height: 12),
            _StatBox(label: 'Courses', value: '5', sub: 'Active courses', icon: Icons.emoji_events_outlined, full: true),
            const SizedBox(height: 20),

            // Per-course grades
            for (final course in context.watch<AppProvider>().courses) ...[
              _CourseGradeCard(course: course),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final bool full;

  const _StatBox({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    this.full = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: full ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              Text(sub, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            ],
          ),
          Icon(icon, size: 18, color: AppTheme.textMuted),
        ],
      ),
    );
  }
}

class _CourseGradeCard extends StatefulWidget {
  final dynamic course;
  const _CourseGradeCard({required this.course});

  @override
  State<_CourseGradeCard> createState() => _CourseGradeCardState();
}

class _CourseGradeCardState extends State<_CourseGradeCard> {
  bool _expanded = false;

  double get _weightedScore {
    double total = 0;
    for (final a in widget.course.assignments) {
      total += a.percentage * a.weight;
    }
    return total;
  }

  String get _grade => context.watch<AppProvider>().gradeFromScore(_weightedScore);

  Color get _gradeColor {
    final g = _grade;
    if (g.startsWith('A')) return AppTheme.success;
    if (g.startsWith('B')) return AppTheme.primary;
    return AppTheme.warning;
  }

  Color get _barColor => courseColor(widget.course.colorHex);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.course.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                            Text('${widget.course.code} • ${widget.course.credits} Credits',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                      Text(_grade, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _gradeColor)),
                      const SizedBox(width: 8),
                      Text('${(_weightedScore * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _weightedScore,
                      backgroundColor: AppTheme.border,
                      valueColor: AlwaysStoppedAnimation<Color>(_barColor),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: AppTheme.border),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (final a in widget.course.assignments)
                    _AssignmentRow(assignment: a),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AssignmentRow extends StatelessWidget {
  final Assignment assignment;
  const _AssignmentRow({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final pct = assignment.percentage;
    final weightPct = (assignment.weight * 100).toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${assignment.name} ($weightPct%)',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
              ],
            ),
          ),
          Text('${assignment.score}/${assignment.total}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(width: 8),
          Text('(${(pct * 100).toStringAsFixed(1)}%)',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
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
