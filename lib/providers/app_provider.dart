// lib/providers/app_provider.dart
// Auth via Firebase. All data (courses, grades, events, notifications) via SQLite.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../services/database_service.dart';

class AppProvider extends ChangeNotifier {
  final FirebaseService _auth = FirebaseService();
  final DatabaseService _db = DatabaseService();

  // ─── Auth ─────────────────────────────────────────────────────────────────
  User? _user;
  User? get user => _user;
  bool get isLoggedIn => _user != null;

  // ─── Data (from SQLite) ───────────────────────────────────────────────────
  StudentProfile? _profile;
  List<Course> _courses = [];
  List<CalendarEvent> _events = [];
  List<AppNotification> _notifications = [];

  StudentProfile? get profile => _profile;
  List<Course> get courses => _courses;
  List<CalendarEvent> get events => _events;
  List<AppNotification> get notifications => _notifications;

  // ─── Loading / error ──────────────────────────────────────────────────────
  bool _loading = false;
  String? _error;
  bool get loading => _loading;
  String? get error => _error;

  // ─── Derived getters ─────────────────────────────────────────────────────

  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  int get totalCredits => _courses.fold(0, (s, c) => s + c.credits);

  Map<String, List<ScheduleEntry>> get weeklySchedule {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    final Map<String, List<ScheduleEntry>> schedule = {for (var d in days) d: []};
    for (final course in _courses) {
      for (final day in course.days.split(', ')) {
        final short = day.length >= 3 ? day.substring(0, 3) : day;
        if (schedule.containsKey(short)) {
          schedule[short]!.add(ScheduleEntry(
            courseCode: course.code, courseName: course.name,
            time: course.time, location: course.location, day: short,
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

  // ─── Auth listener ────────────────────────────────────────────────────────

  void listenToAuth() {
    _auth.authStateChanges.listen((user) async {
      _user = user;
      if (user != null) {
        await _loadAllData(user.uid, user.email ?? '');
      } else {
        _clearData();
      }
      notifyListeners();
    });
  }

  // ─── Sign In ──────────────────────────────────────────────────────────────

  Future<String?> signIn(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final cred = await _auth.signIn(email, password);
      _user = cred.user;
      if (_user != null) {
        await _db.seedData(_user!.uid, _user!.email ?? email);
        await _loadAllData(_user!.uid, _user!.email ?? email);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      _error = _authError(e.code);
      return _error;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _clearData();
    _user = null;
    notifyListeners();
  }

  Future<String?> changePassword(String current, String newPass) async {
    final err = await _auth.reauthenticate(current);
    if (err != null) return err;
    await _auth.updatePassword(newPass);
    return null;
  }

  // ─── Profile ──────────────────────────────────────────────────────────────

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_user == null) return;
    await _db.updateProfileField(_user!.uid, data);
    _profile = await _db.getProfile(_user!.uid);
    notifyListeners();
  }

  // ─── Courses ──────────────────────────────────────────────────────────────

  Future<void> addCourse(Course course) async {
    if (_user == null) return;
    await _db.insertCourse(_user!.uid, course);
    await _refreshCourses();
  }

  Future<void> updateCourse(Course course) async {
    if (_user == null) return;
    await _db.updateCourse(_user!.uid, course);
    await _refreshCourses();
  }

  Future<void> deleteCourse(String courseId) async {
    if (_user == null) return;
    await _db.deleteCourse(_user!.uid, courseId);
    await _refreshCourses();
  }

  // ─── Assignments ──────────────────────────────────────────────────────────

  Future<void> addAssignment(String courseId, Assignment a) async {
    if (_user == null) return;
    await _db.insertAssignment(_user!.uid, courseId, a);
    await _refreshCourses();
  }

  Future<void> updateAssignment(String courseId, Assignment a) async {
    if (_user == null) return;
    await _db.updateAssignment(_user!.uid, courseId, a);
    await _refreshCourses();
  }

  Future<void> deleteAssignment(String courseId, String assignmentId) async {
    if (_user == null) return;
    await _db.deleteAssignment(_user!.uid, courseId, assignmentId);
    await _refreshCourses();
  }

  // ─── Calendar Events ──────────────────────────────────────────────────────

  Future<void> addCalendarEvent(CalendarEvent e) async {
    if (_user == null) return;
    await _db.insertCalendarEvent(_user!.uid, e);
    await _refreshEvents();
  }

  Future<void> deleteCalendarEvent(String eventId) async {
    if (_user == null) return;
    await _db.deleteCalendarEvent(_user!.uid, eventId);
    await _refreshEvents();
  }

  // ─── Notifications ────────────────────────────────────────────────────────

  Future<void> markNotificationRead(String id) async {
    if (_user == null) return;
    await _db.markNotificationRead(_user!.uid, id);
    await _refreshNotifications();
  }

  Future<void> markAllNotificationsRead() async {
    if (_user == null) return;
    await _db.markAllNotificationsRead(_user!.uid);
    await _refreshNotifications();
  }

  Future<void> deleteNotification(String id) async {
    if (_user == null) return;
    await _db.deleteNotification(_user!.uid, id);
    await _refreshNotifications();
  }

  // ─── Data Loading ─────────────────────────────────────────────────────────

  Future<void> _loadAllData(String uid, String email) async {
    _profile = await _db.getProfile(uid);
    _courses = await _db.getCourses(uid);
    _events = await _db.getCalendarEvents(uid);
    _notifications = await _db.getNotifications(uid);
    notifyListeners();
  }

  Future<void> _refreshCourses() async {
    if (_user == null) return;
    _courses = await _db.getCourses(_user!.uid);
    notifyListeners();
  }

  Future<void> _refreshEvents() async {
    if (_user == null) return;
    _events = await _db.getCalendarEvents(_user!.uid);
    notifyListeners();
  }

  Future<void> _refreshNotifications() async {
    if (_user == null) return;
    _notifications = await _db.getNotifications(_user!.uid);
    notifyListeners();
  }

  void _clearData() {
    _profile = null;
    _courses = [];
    _events = [];
    _notifications = [];
  }

  String _authError(String code) {
    switch (code) {
      case 'user-not-found':     return 'No account found with this email.';
      case 'wrong-password':     return 'Incorrect password. Please try again.';
      case 'invalid-email':      return 'Please enter a valid email address.';
      case 'user-disabled':      return 'This account has been disabled.';
      case 'too-many-requests':  return 'Too many attempts. Please try again later.';
      case 'invalid-credential': return 'Invalid email or password.';
      default:                   return 'An error occurred. Please try again.';
    }
  }
}
