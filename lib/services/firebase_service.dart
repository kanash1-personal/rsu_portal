// lib/services/firebase_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Auth ────────────────────────────────────────────────────────────────

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<void> signOut() async => await _auth.signOut();

  Future<void> updatePassword(String newPassword) async {
    await _auth.currentUser!.updatePassword(newPassword);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ─── Student Profile ─────────────────────────────────────────────────────

  /// Returns the Firestore doc ref for the current student
  DocumentReference _studentRef(String uid) =>
      _db.collection('students').doc(uid);

  /// Fetch student profile once
  Future<StudentProfile?> getStudentProfile(String uid) async {
    final snap = await _studentRef(uid).get();
    if (!snap.exists) return null;
    return StudentProfile.fromFirestore(
        snap.data() as Map<String, dynamic>, snap.id);
  }

  /// Listen to student profile changes in real-time
  Stream<StudentProfile?> studentProfileStream(String uid) {
    return _studentRef(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return StudentProfile.fromFirestore(
          snap.data() as Map<String, dynamic>, snap.id);
    });
  }

  /// Update specific profile fields
  Future<void> updateStudentProfile(
      String uid, Map<String, dynamic> data) async {
    await _studentRef(uid).update(data);
  }

  // ─── Courses & Grades ────────────────────────────────────────────────────

  /// Fetch all courses for this student
  Future<List<Course>> getCourses(String uid) async {
    final snap = await _db
        .collection('students')
        .doc(uid)
        .collection('courses')
        .get();
    return snap.docs
        .map((d) => Course.fromFirestore(d.data(), d.id))
        .toList();
  }

  /// Real-time course stream
  Stream<List<Course>> coursesStream(String uid) {
    return _db
        .collection('students')
        .doc(uid)
        .collection('courses')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Course.fromFirestore(d.data(), d.id)).toList());
  }

  /// Fetch assignments for a specific course
  Future<List<Assignment>> getAssignments(String uid, String courseId) async {
    final snap = await _db
        .collection('students')
        .doc(uid)
        .collection('courses')
        .doc(courseId)
        .collection('assignments')
        .get();
    return snap.docs
        .map((d) => Assignment.fromFirestore(d.data(), d.id))
        .toList();
  }

  // ─── Schedule / Calendar Events ───────────────────────────────────────────

  /// Fetch all calendar events
  Future<List<CalendarEvent>> getCalendarEvents(String uid) async {
    final snap = await _db
        .collection('students')
        .doc(uid)
        .collection('events')
        .orderBy('date')
        .get();
    return snap.docs
        .map((d) => CalendarEvent.fromFirestore(d.data(), d.id))
        .toList();
  }

  Stream<List<CalendarEvent>> calendarEventsStream(String uid) {
    return _db
        .collection('students')
        .doc(uid)
        .collection('events')
        .orderBy('date')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CalendarEvent.fromFirestore(d.data(), d.id))
            .toList());
  }

  // ─── Notifications ────────────────────────────────────────────────────────

  Stream<List<AppNotification>> notificationsStream(String uid) {
    return _db
        .collection('students')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppNotification.fromFirestore(d.data(), d.id))
            .toList());
  }

  Future<void> markNotificationRead(String uid, String notifId) async {
    await _db
        .collection('students')
        .doc(uid)
        .collection('notifications')
        .doc(notifId)
        .update({'isRead': true});
  }

  Future<void> markAllNotificationsRead(String uid) async {
    final batch = _db.batch();
    final snap = await _db
        .collection('students')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String uid, String notifId) async {
    await _db
        .collection('students')
        .doc(uid)
        .collection('notifications')
        .doc(notifId)
        .delete();
  }

  // ─── Seed Data (run once to populate Firestore for a new user) ───────────

  Future<void> seedStudentData(String uid) async {
    final batch = _db.batch();
    final studentRef = _studentRef(uid);

    // Profile
    batch.set(studentRef, {
      'name': 'Alex Johnson',
      'email': _auth.currentUser?.email ?? '',
      'studentId': 'STU-2024-001',
      'major': 'Computer Science',
      'year': 'Junior',
      'phone': '+1 (555) 123-4567',
      'address': '123 Campus Drive, Dorm A, Room 204',
      'enrollmentStatus': 'Full-time',
      'startDate': 'Fall 2023',
      'expectedGraduation': 'Spring 2027',
      'gpa': 3.75,
    });

    // Courses
    final coursesData = [
      {
        'id': 'cs201',
        'code': 'CS 201',
        'name': 'Data Structures',
        'instructor': 'Dr. Smith',
        'time': '9:00 AM - 10:30 AM',
        'location': 'Tech Building, Room 204',
        'days': 'Mon, Wed, Fri',
        'credits': 4,
        'colorHex': '#4F8EF7',
      },
      {
        'id': 'cs305',
        'code': 'CS 305',
        'name': 'Database Systems',
        'instructor': 'Prof. Johnson',
        'time': '11:00 AM - 12:30 PM',
        'location': 'Science Hall, Room 101',
        'days': 'Tue, Thu',
        'credits': 3,
        'colorHex': '#22C55E',
      },
      {
        'id': 'cs340',
        'code': 'CS 340',
        'name': 'Web Development',
        'instructor': 'Dr. Williams',
        'time': '2:00 PM - 3:30 PM',
        'location': 'Tech Building, Room 305',
        'days': 'Mon, Wed',
        'credits': 3,
        'colorHex': '#A855F7',
      },
      {
        'id': 'cs401',
        'code': 'CS 401',
        'name': 'Software Engineering',
        'instructor': 'Prof. Brown',
        'time': '4:00 PM - 5:30 PM',
        'location': 'Engineering Building, Room 210',
        'days': 'Tue, Thu',
        'credits': 4,
        'colorHex': '#F97316',
      },
      {
        'id': 'cs350',
        'code': 'CS 350',
        'name': 'Computer Networks',
        'instructor': 'Prof. Lee',
        'time': '10:00 AM - 11:30 AM',
        'location': 'Tech Building, Room 150',
        'days': 'Mon, Wed, Fri',
        'credits': 3,
        'colorHex': '#EF4444',
      },
    ];

    for (final c in coursesData) {
      final courseRef = studentRef.collection('courses').doc(c['id'] as String);
      batch.set(courseRef, c);
    }

    await batch.commit();

    // Assignments (separate batch)
    final assignBatch = _db.batch();
    final assignmentsData = {
      'cs201': [
        {'name': 'Assignment 1', 'weight': 0.15, 'score': 95, 'total': 100},
        {'name': 'Assignment 2', 'weight': 0.15, 'score': 88, 'total': 100},
        {'name': 'Midterm Exam', 'weight': 0.30, 'score': 90, 'total': 100},
        {'name': 'Final Project', 'weight': 0.40, 'score': 94, 'total': 100},
      ],
      'cs305': [
        {'name': 'Lab 1', 'weight': 0.20, 'score': 88, 'total': 100},
        {'name': 'Quiz 1', 'weight': 0.15, 'score': 85, 'total': 100},
        {'name': 'Midterm', 'weight': 0.30, 'score': 82, 'total': 100},
        {'name': 'Final Exam', 'weight': 0.35, 'score': 78, 'total': 100},
      ],
      'cs340': [
        {'name': 'Project 1', 'weight': 0.25, 'score': 90, 'total': 100},
        {'name': 'Project 2', 'weight': 0.25, 'score': 82, 'total': 100},
        {'name': 'Midterm', 'weight': 0.25, 'score': 79, 'total': 100},
        {'name': 'Final Project', 'weight': 0.25, 'score': 85, 'total': 100},
      ],
      'cs401': [
        {'name': 'Sprint 1', 'weight': 0.20, 'score': 88, 'total': 100},
        {'name': 'Sprint 2', 'weight': 0.20, 'score': 90, 'total': 100},
        {'name': 'Design Doc', 'weight': 0.30, 'score': 85, 'total': 100},
        {'name': 'Final Sprint', 'weight': 0.30, 'score': 92, 'total': 100},
      ],
      'cs350': [
        {'name': 'Lab 1', 'weight': 0.20, 'score': 80, 'total': 100},
        {'name': 'Lab 2', 'weight': 0.20, 'score': 75, 'total': 100},
        {'name': 'Midterm', 'weight': 0.30, 'score': 72, 'total': 100},
        {'name': 'Final Exam', 'weight': 0.30, 'score': 78, 'total': 100},
      ],
    };

    for (final courseId in assignmentsData.keys) {
      for (final a in assignmentsData[courseId]!) {
        final ref = studentRef
            .collection('courses')
            .doc(courseId)
            .collection('assignments')
            .doc();
        assignBatch.set(ref, a);
      }
    }

    // Calendar events
    final eventsData = [
      {
        'title': 'Data Structures Midterm',
        'courseCode': 'CS 201',
        'time': '9:00 AM',
        'date': Timestamp.fromDate(DateTime(2026, 3, 24)),
        'type': 'exam',
      },
      {
        'title': 'Web Development Project Due',
        'courseCode': 'CS 340',
        'time': '11:59 PM',
        'date': Timestamp.fromDate(DateTime(2026, 3, 26)),
        'type': 'assignment',
      },
      {
        'title': 'Spring Career Fair',
        'courseCode': '',
        'time': '10:00 AM',
        'date': Timestamp.fromDate(DateTime(2026, 3, 28)),
        'type': 'event',
      },
      {
        'title': 'DB Systems Quiz',
        'courseCode': 'CS 305',
        'time': '11:00 AM',
        'date': Timestamp.fromDate(DateTime(2026, 3, 23)),
        'type': 'exam',
      },
      {
        'title': 'Software Eng. Sprint Due',
        'courseCode': 'CS 401',
        'time': '5:30 PM',
        'date': Timestamp.fromDate(DateTime(2026, 3, 30)),
        'type': 'assignment',
      },
    ];

    for (final e in eventsData) {
      final ref = studentRef.collection('events').doc();
      assignBatch.set(ref, e);
    }

    // Notifications
    final notifsData = [
      {
        'title': 'Grade Posted',
        'body': 'Your grade for CS 201 Assignment 2 has been posted: 88/100',
        'timeAgo': '2 hours ago',
        'type': 'grade',
        'actionLabel': 'Grades',
        'isRead': false,
        'createdAt': Timestamp.now(),
      },
      {
        'title': 'Upcoming Deadline',
        'body': "Web Development Project is due in 3 days. Don't forget to submit!",
        'timeAgo': '5 hours ago',
        'type': 'deadline',
        'actionLabel': 'Assignments',
        'isRead': false,
        'createdAt': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(hours: 5))),
      },
      {
        'title': 'Class Cancelled',
        'body': 'CS 350 class on March 22 has been cancelled.',
        'timeAgo': '1 day ago',
        'type': 'cancelled',
        'actionLabel': 'Schedule',
        'isRead': false,
        'createdAt': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 1))),
      },
      {
        'title': 'Registration Reminder',
        'body': 'Fall 2026 course registration opens on April 20.',
        'timeAgo': '1 day ago',
        'type': 'info',
        'actionLabel': 'Registration',
        'isRead': true,
        'createdAt': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 1, hours: 3))),
      },
      {
        'title': 'New Announcement',
        'body': 'Prof. Johnson posted a new announcement in CS 305.',
        'timeAgo': '2 days ago',
        'type': 'info',
        'actionLabel': 'Courses',
        'isRead': true,
        'createdAt': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 2))),
      },
    ];

    for (final n in notifsData) {
      final ref = studentRef.collection('notifications').doc();
      assignBatch.set(ref, n);
    }

    await assignBatch.commit();
  }
}
