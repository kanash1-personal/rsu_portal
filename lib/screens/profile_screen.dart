// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import 'main_nav.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final profile = p.profile;

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
              child: Icon(Icons.school, color: Colors.white, size: 18),
            ),
          ),
        ),
        title: const Text('Student Portal', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: Icon(Icons.menu, color: AppTheme.textPrimary(context)),
            onPressed: () => _showMenuSheet(context))],
      ),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('My Profile',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context))),
                  Text('Manage your personal information',
                      style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13)),
                  const SizedBox(height: 16),

                  // Profile card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border(context))),
                    child: Column(children: [
                      Container(
                        width: 72, height: 72,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF4F8EF7)],
                              begin: Alignment.topLeft, end: Alignment.bottomRight),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            profile.name.isNotEmpty
                                ? profile.name.split(' ').map((e) => e[0]).take(2).join()
                                : '?',
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(profile.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context))),
                      const SizedBox(height: 4),
                      Text(profile.email, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary(context))),
                      const SizedBox(height: 12),
                      Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: [
                        _Badge(label: profile.major, color: AppTheme.primary),
                        _Badge(label: profile.year, color: Colors.transparent, textColor: AppTheme.textSecondary(context), bordered: true),
                        _Badge(label: 'GPA: ${profile.gpa.toStringAsFixed(2)}', color: Colors.transparent, textColor: AppTheme.textSecondary(context), bordered: true),
                      ]),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => _showEditProfileDialog(context, p),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.border(context)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        ),
                        child: Text('Edit Profile', style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  _Section(title: 'Academic Information', icon: Icons.school_outlined, children: [
                    _InfoRow(icon: Icons.person_outline, label: 'Student ID', value: profile.studentId),
                    _InfoRow(icon: Icons.book_outlined, label: 'Major', value: profile.major),
                    _InfoRow(icon: Icons.school_outlined, label: 'Academic Year', value: profile.year),
                    _InfoRow(icon: Icons.emoji_events_outlined, label: 'Current GPA', value: profile.gpa.toStringAsFixed(2)),
                  ]),
                  const SizedBox(height: 16),

                  _Section(title: 'Contact Information', icon: Icons.mail_outline, children: [
                    _EditableRow(icon: Icons.mail_outline, label: 'Email', value: profile.email,
                        onEdit: () => _editField(context, p, 'Email', profile.email, 'email')),
                    _EditableRow(icon: Icons.phone_outlined, label: 'Phone', value: profile.phone,
                        onEdit: () => _editField(context, p, 'Phone', profile.phone, 'phone')),
                    _EditableRow(icon: Icons.location_on_outlined, label: 'Address', value: profile.address,
                        onEdit: () => _editField(context, p, 'Address', profile.address, 'address')),
                  ]),
                  const SizedBox(height: 16),

                  _Section(title: 'Enrollment Information', icon: Icons.calendar_today_outlined, children: [
                    _InfoRow(icon: Icons.calendar_today_outlined, label: 'Enrollment Status', value: profile.enrollmentStatus),
                    _InfoRow(icon: Icons.calendar_today_outlined, label: 'Start Date', value: profile.startDate),
                    _InfoRow(icon: Icons.school_outlined, label: 'Expected Graduation', value: profile.expectedGraduation),
                  ]),
                  const SizedBox(height: 16),

                  Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
                  // Dark mode toggle
                  _ActionButton(
                    icon: Theme.of(context).brightness == Brightness.dark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    label: Theme.of(context).brightness == Brightness.dark
                        ? 'Switch to Light Mode'
                        : 'Switch to Dark Mode',
                    onTap: () => context.read<AppProvider>().toggleTheme(),
                  ),
                  const SizedBox(height: 8),
                  const SizedBox(height: 10),
                  _ActionButton(icon: Icons.mail_outline, label: 'Change Email',
                      onTap: () => _editField(context, p, 'Email', profile.email, 'email')),
                  const SizedBox(height: 8),
                  _ActionButton(icon: Icons.lock_outline, label: 'Update Password',
                      onTap: () => _showChangePasswordDialog(context, p)),
                  const SizedBox(height: 8),

                  _ActionButton(icon: Icons.download_outlined, label: 'Download Transcript',
                      onTap: () => _showTranscriptDialog(context)),
                  const SizedBox(height: 8),
                  _ActionButton(icon: Icons.logout, label: 'Sign Out',
                      onTap: () => _confirmSignOut(context, p), textColor: AppTheme.danger),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // ─── Dialogs ──────────────────────────────────────────────────────────────

  void _editField(BuildContext context, AppProvider p, String label, String current, String field) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit $label'),
        content: TextField(
          controller: ctrl, autofocus: true,
          decoration: InputDecoration(labelText: label,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final val = ctrl.text.trim();
              if (val.isNotEmpty) await p.updateProfile({field: val});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$label updated successfully')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AppProvider p) {
    final nameCtrl = TextEditingController(text: p.profile?.name ?? '');
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Profile'),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(labelText: 'Display Name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await p.updateProfile({'name': nameCtrl.text.trim()});
              if (context.mounted) Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, AppProvider p) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Update Password'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _PassField(controller: currentCtrl, label: 'Current Password'),
          const SizedBox(height: 10),
          _PassField(controller: newCtrl, label: 'New Password'),
          const SizedBox(height: 10),
          _PassField(controller: confirmCtrl, label: 'Confirm New Password'),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (newCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match'), backgroundColor: AppTheme.danger),
                );
                return;
              }
              Navigator.pop(context);
              final err = await p.changePassword(currentCtrl.text, newCtrl.text);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(err ?? 'Password updated successfully'),
                backgroundColor: err != null ? AppTheme.danger : null,
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showTranscriptDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Download Transcript'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Select transcript format:'),
          const SizedBox(height: 16),
          _TranscriptOption(label: 'Official PDF', subtitle: 'Signed & certified'),
          const SizedBox(height: 8),
          _TranscriptOption(label: 'Unofficial PDF', subtitle: 'For personal use'),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transcript download started...')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Download', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, AppProvider p) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (context.mounted) Navigator.pop(context);
              await p.signOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
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

// ─── Helper widgets ───────────────────────────────────────────────────────────

class _PassField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  const _PassField({required this.controller, required this.label});
  @override
  State<_PassField> createState() => _PassFieldState();
}

class _PassFieldState extends State<_PassField> {
  bool _obscure = true;
  @override
  Widget build(BuildContext context) => TextField(
        controller: widget.controller, obscureText: _obscure,
        decoration: InputDecoration(
          labelText: widget.label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon: IconButton(
            icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
      );
}

class _TranscriptOption extends StatelessWidget {
  final String label, subtitle;
  const _TranscriptOption({required this.label, required this.subtitle});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(border: Border.all(color: AppTheme.border(context)), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Icon(Icons.picture_as_pdf_outlined, color: AppTheme.danger, size: 20),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text(subtitle, style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context))),
          ]),
        ]),
      );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final bool bordered;
  const _Badge({required this.label, required this.color, this.textColor = Colors.white, this.bordered = false});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20),
            border: bordered ? Border.all(color: AppTheme.border(context)) : null),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
      );
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _Section({required this.title, required this.icon, required this.children});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: AppTheme.textPrimary(context)), const SizedBox(width: 6),
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
        ]),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border(context))),
          child: Column(children: [
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1) Divider(height: 1, color: AppTheme.border(context), indent: 16, endIndent: 16),
            ],
          ]),
        ),
      ]);
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Icon(icon, size: 16, color: AppTheme.textMuted(context)), const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context))),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
          ]),
        ]),
      );
}

class _EditableRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final VoidCallback onEdit;
  const _EditableRow({required this.icon, required this.label, required this.value, required this.onEdit});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Icon(icon, size: 16, color: AppTheme.textMuted(context)), const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context))),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
          ])),
          GestureDetector(onTap: onEdit,
              child: Text('Edit', style: TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600))),
        ]),
      );
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? textColor;
  const _ActionButton({required this.icon, required this.label, required this.onTap, this.textColor});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border(context))),
        child: InkWell(
          onTap: onTap, borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Icon(icon, size: 18, color: textColor ?? AppTheme.textSecondary(context)), const SizedBox(width: 10),
              Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor ?? AppTheme.textPrimary(context))),
              const Spacer(),
              Icon(Icons.chevron_right, size: 16, color: textColor ?? AppTheme.textMuted(context)),
            ]),
          ),
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
