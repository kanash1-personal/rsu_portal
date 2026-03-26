// lib/providers/app_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';

class AppProvider extends ChangeNotifier {
  final FirebaseService _svc = FirebaseService();

  // ─── Auth state ───────────────────────────────────────────────────────────
  User? _user;
  User? get user => _user;
  bool get isLoggedIn => _user != null;

  // ─── Data ─────────────────────────────────────────────────────────────────
  StudentProfile? _profile;
  List<Course> _courses = [];
  List<CalendarEvent> _events = [];
  List<AppNotification> _notifications = [];

  StudentProfile? get profile => _profile;
  List<Course> get courses => _courses;
  List<CalendarEvent> get events => _events;
  List<AppNotification> get notifications => _notifications;

  // ─── Loading / error ─────────────────────────────────────────────────────
  bool _loading = false;
  String? _error;
  bool get loading => _loading;
  String? get error => _error;

  // Stream subscriptions
  StreamSubscription? _profileSub;
  StreamSubscription? _coursesSub;
  StreamSubscription? _eventsSub;
  StreamSubscription? _notifsSub;

  // ─── Derived getters ─────────────────────────────────────────────────────

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  int get totalCredits => _courses.fold(0, (sum, c) => sum + c.credits);

  Map<String, List<ScheduleEntry>> get weeklySchedule {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    final Map<String, List<ScheduleEntry>> schedule = {
      for (var d in days) d: []
    };
    for (final course in _courses) {
      final courseDays = course.days.split(', ');
      for (final day in courseDays) {
        final short = day.length >= 3 ? day.substring(0, 3) : day;
        if (schedule.containsKey(short)) {
          schedule[short]!.add(ScheduleEntry(
            courseCode: course.code,
            courseName: course.name,
            time: course.time,
            location: course.location,
            day: short,
          ));
        }
      }
    }
    for (final day in schedule.keys) {
      schedule[day]!.sort((a, b) => a.time.compareTo(b.time));
    }
    return schedule;
  }

  String gradeFromScore(double pct) {
    if (pct >= 0.93) return 'A';
    if (pct >= 0.90) return 'A-';
    if (pct >= 0.87) return 'B+';
    if (pct >= 0.83) return 'B';
    if (pct >= 0.80) return 'B-';
    if (pct >= 0.77) return 'C+';
    if (pct >= 0.73) return 'C';
    return 'D';
  }

  // ─── Auth ─────────────────────────────────────────────────────────────────

  void listenToAuth() {
    _svc.authStateChanges.listen((user) async {
      _user = user;
      if (user != null) {
        await _subscribeToStreams(user.uid);
      } else {
        _cancelStreams();
        _clearData();
      }
      notifyListeners();
    });
  }

  Future<String?> signIn(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final cred = await _svc.signIn(email, password);
      _user = cred.user;
      // Seed data if this is a new user (no profile doc yet)
      if (_user != null) {
        final existing = await _svc.getStudentProfile(_user!.uid);
        if (existing == null) {
          await _svc.seedStudentData(_user!.uid);
        }
        await _subscribeToStreams(_user!.uid);
      }
      return null; // success
    } on FirebaseAuthException catch (e) {
      _error = _authError(e.code);
      return _error;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _svc.signOut();
    _cancelStreams();
    _clearData();
    _user = null;
    notifyListeners();
  }

  Future<String?> changePassword(
      String currentPassword, String newPassword) async {
    try {
      // Re-authenticate first
      final cred = EmailAuthProvider.credential(
        email: _user!.email!,
        password: currentPassword,
      );
      await _user!.reauthenticateWithCredential(cred);
      await _svc.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e.code);
    }
  }

  // ─── Profile ─────────────────────────────────────────────────────────────

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_user == null) return;
    await _svc.updateStudentProfile(_user!.uid, data);
    // Stream will update _profile automatically
  }

  // ─── Notifications ────────────────────────────────────────────────────────

  Future<void> markNotificationRead(String notifId) async {
    if (_user == null) return;
    await _svc.markNotificationRead(_user!.uid, notifId);
  }

  Future<void> markAllNotificationsRead() async {
    if (_user == null) return;
    await _svc.markAllNotificationsRead(_user!.uid);
  }

  Future<void> deleteNotification(String notifId) async {
    if (_user == null) return;
    await _svc.deleteNotification(_user!.uid, notifId);
  }

  // ─── Courses ──────────────────────────────────────────────────────────────

  /// Load assignments for all courses (called once after courses load)
  Future<void> loadAssignments() async {
    if (_user == null) return;
    for (final course in _courses) {
      final assignments = await _svc.getAssignments(_user!.uid, course.id);
      course.assignments = assignments;
    }
    notifyListeners();
  }

  // ─── Streams ──────────────────────────────────────────────────────────────

  Future<void> _subscribeToStreams(String uid) async {
    _cancelStreams();

    _profileSub = _svc.studentProfileStream(uid).listen((p) {
      _profile = p;
      notifyListeners();
    });

    _coursesSub = _svc.coursesStream(uid).listen((courses) async {
      _courses = courses;
      notifyListeners();
      await loadAssignments();
    });

    _eventsSub = _svc.calendarEventsStream(uid).listen((events) {
      _events = events;
      notifyListeners();
    });

    _notifsSub = _svc.notificationsStream(uid).listen((notifs) {
      _notifications = notifs;
      notifyListeners();
    });
  }

  void _cancelStreams() {
    _profileSub?.cancel();
    _coursesSub?.cancel();
    _eventsSub?.cancel();
    _notifsSub?.cancel();
  }

  void _clearData() {
    _profile = null;
    _courses = [];
    _events = [];
    _notifications = [];
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _authError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  @override
  void dispose() {
    _cancelStreams();
    super.dispose();
  }
}
