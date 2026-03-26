// lib/services/database_service.dart
//
// Local SQLite database for RSU Student Portal.
// Stores: courses, assignments, calendar_events, notifications, student_profile
// Uses sqflite — works fully offline, no internet required.

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  // ─── Init & Schema ────────────────────────────────────────────────────────

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'rsu_portal.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Student profile table
    await db.execute('''
      CREATE TABLE student_profile (
        uid         TEXT PRIMARY KEY,
        name        TEXT NOT NULL,
        email       TEXT NOT NULL,
        student_id  TEXT,
        major       TEXT,
        year        TEXT,
        phone       TEXT,
        address     TEXT,
        enroll_status TEXT,
        start_date  TEXT,
        graduation  TEXT,
        gpa         REAL DEFAULT 0.0
      )
    ''');

    // Courses table
    await db.execute('''
      CREATE TABLE courses (
        id          TEXT PRIMARY KEY,
        uid         TEXT NOT NULL,
        code        TEXT NOT NULL,
        name        TEXT NOT NULL,
        instructor  TEXT,
        time        TEXT,
        location    TEXT,
        days        TEXT,
        credits     INTEGER DEFAULT 3,
        color_hex   TEXT DEFAULT '#4F8EF7'
      )
    ''');

    // Assignments table (linked to courses)
    await db.execute('''
      CREATE TABLE assignments (
        id          TEXT PRIMARY KEY,
        course_id   TEXT NOT NULL,
        uid         TEXT NOT NULL,
        name        TEXT NOT NULL,
        weight      REAL DEFAULT 0.0,
        score       INTEGER DEFAULT 0,
        total       INTEGER DEFAULT 100,
        FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
      )
    ''');

    // Calendar events table
    await db.execute('''
      CREATE TABLE calendar_events (
        id          TEXT PRIMARY KEY,
        uid         TEXT NOT NULL,
        title       TEXT NOT NULL,
        course_code TEXT DEFAULT '',
        time        TEXT DEFAULT '',
        date        INTEGER NOT NULL,
        type        TEXT DEFAULT 'event'
      )
    ''');

    // Notifications table
    await db.execute('''
      CREATE TABLE notifications (
        id          TEXT PRIMARY KEY,
        uid         TEXT NOT NULL,
        title       TEXT NOT NULL,
        body        TEXT NOT NULL,
        time_ago    TEXT,
        type        TEXT DEFAULT 'info',
        action_label TEXT DEFAULT '',
        is_read     INTEGER DEFAULT 0,
        created_at  INTEGER
      )
    ''');

    // Seed default data for first run (will be tied to uid on login)
  }

  // ─── Student Profile ──────────────────────────────────────────────────────

  Future<StudentProfile?> getProfile(String uid) async {
    final db = await database;
    final rows = await db.query('student_profile',
        where: 'uid = ?', whereArgs: [uid], limit: 1);
    if (rows.isEmpty) return null;
    return _profileFromRow(rows.first);
  }

  Future<void> upsertProfile(StudentProfile p) async {
    final db = await database;
    await db.insert(
      'student_profile',
      {
        'uid': p.uid, 'name': p.name, 'email': p.email,
        'student_id': p.studentId, 'major': p.major, 'year': p.year,
        'phone': p.phone, 'address': p.address,
        'enroll_status': p.enrollmentStatus, 'start_date': p.startDate,
        'graduation': p.expectedGraduation, 'gpa': p.gpa,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateProfileField(String uid, Map<String, dynamic> fields) async {
    final db = await database;
    // Map model field names → column names
    final colMap = {
      'name': 'name', 'email': 'email', 'phone': 'phone',
      'address': 'address', 'gpa': 'gpa',
    };
    final updates = <String, dynamic>{};
    for (final key in fields.keys) {
      final col = colMap[key];
      if (col != null) updates[col] = fields[key];
    }
    if (updates.isNotEmpty) {
      await db.update('student_profile', updates,
          where: 'uid = ?', whereArgs: [uid]);
    }
  }

  // ─── Courses ──────────────────────────────────────────────────────────────

  Future<List<Course>> getCourses(String uid) async {
    final db = await database;
    final rows = await db.query('courses',
        where: 'uid = ?', whereArgs: [uid], orderBy: 'code ASC');
    final courses = rows.map(_courseFromRow).toList();
    // Load assignments for each course
    for (final course in courses) {
      course.assignments = await getAssignments(uid, course.id);
    }
    return courses;
  }

  Future<Course?> getCourse(String uid, String courseId) async {
    final db = await database;
    final rows = await db.query('courses',
        where: 'uid = ? AND id = ?', whereArgs: [uid, courseId], limit: 1);
    if (rows.isEmpty) return null;
    final course = _courseFromRow(rows.first);
    course.assignments = await getAssignments(uid, courseId);
    return course;
  }

  Future<void> insertCourse(String uid, Course course) async {
    final db = await database;
    await db.insert(
      'courses',
      {
        'id': course.id, 'uid': uid, 'code': course.code,
        'name': course.name, 'instructor': course.instructor,
        'time': course.time, 'location': course.location,
        'days': course.days, 'credits': course.credits,
        'color_hex': course.colorHex,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCourse(String uid, Course course) async {
    final db = await database;
    await db.update(
      'courses',
      {
        'code': course.code, 'name': course.name,
        'instructor': course.instructor, 'time': course.time,
        'location': course.location, 'days': course.days,
        'credits': course.credits, 'color_hex': course.colorHex,
      },
      where: 'id = ? AND uid = ?',
      whereArgs: [course.id, uid],
    );
  }

  Future<void> deleteCourse(String uid, String courseId) async {
    final db = await database;
    // Cascade deletes assignments too
    await db.delete('assignments',
        where: 'course_id = ? AND uid = ?', whereArgs: [courseId, uid]);
    await db.delete('courses',
        where: 'id = ? AND uid = ?', whereArgs: [courseId, uid]);
  }

  // ─── Assignments ──────────────────────────────────────────────────────────

  Future<List<Assignment>> getAssignments(String uid, String courseId) async {
    final db = await database;
    final rows = await db.query('assignments',
        where: 'course_id = ? AND uid = ?',
        whereArgs: [courseId, uid],
        orderBy: 'name ASC');
    return rows.map(_assignmentFromRow).toList();
  }

  Future<void> insertAssignment(
      String uid, String courseId, Assignment a) async {
    final db = await database;
    await db.insert(
      'assignments',
      {
        'id': a.id, 'course_id': courseId, 'uid': uid,
        'name': a.name, 'weight': a.weight,
        'score': a.score, 'total': a.total,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateAssignment(
      String uid, String courseId, Assignment a) async {
    final db = await database;
    await db.update(
      'assignments',
      {
        'name': a.name, 'weight': a.weight,
        'score': a.score, 'total': a.total,
      },
      where: 'id = ? AND course_id = ? AND uid = ?',
      whereArgs: [a.id, courseId, uid],
    );
  }

  Future<void> deleteAssignment(
      String uid, String courseId, String assignmentId) async {
    final db = await database;
    await db.delete('assignments',
        where: 'id = ? AND course_id = ? AND uid = ?',
        whereArgs: [assignmentId, courseId, uid]);
  }

  // ─── Calendar Events ──────────────────────────────────────────────────────

  Future<List<CalendarEvent>> getCalendarEvents(String uid) async {
    final db = await database;
    final rows = await db.query('calendar_events',
        where: 'uid = ?', whereArgs: [uid], orderBy: 'date ASC');
    return rows.map(_eventFromRow).toList();
  }

  Future<void> insertCalendarEvent(String uid, CalendarEvent e) async {
    final db = await database;
    await db.insert(
      'calendar_events',
      {
        'id': e.id, 'uid': uid, 'title': e.title,
        'course_code': e.courseCode, 'time': e.time,
        'date': e.date.millisecondsSinceEpoch,
        'type': _eventTypeStr(e.type),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteCalendarEvent(String uid, String eventId) async {
    final db = await database;
    await db.delete('calendar_events',
        where: 'id = ? AND uid = ?', whereArgs: [eventId, uid]);
  }

  // ─── Notifications ────────────────────────────────────────────────────────

  Future<List<AppNotification>> getNotifications(String uid) async {
    final db = await database;
    final rows = await db.query('notifications',
        where: 'uid = ?', whereArgs: [uid], orderBy: 'created_at DESC');
    return rows.map(_notifFromRow).toList();
  }

  Future<void> insertNotification(String uid, AppNotification n) async {
    final db = await database;
    await db.insert(
      'notifications',
      {
        'id': n.id, 'uid': uid, 'title': n.title, 'body': n.body,
        'time_ago': n.timeAgo, 'type': _notifTypeStr(n.type),
        'action_label': n.actionLabel, 'is_read': n.isRead ? 1 : 0,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> markNotificationRead(String uid, String notifId) async {
    final db = await database;
    await db.update('notifications', {'is_read': 1},
        where: 'id = ? AND uid = ?', whereArgs: [notifId, uid]);
  }

  Future<void> markAllNotificationsRead(String uid) async {
    final db = await database;
    await db.update('notifications', {'is_read': 1},
        where: 'uid = ? AND is_read = 0', whereArgs: [uid]);
  }

  Future<void> deleteNotification(String uid, String notifId) async {
    final db = await database;
    await db.delete('notifications',
        where: 'id = ? AND uid = ?', whereArgs: [notifId, uid]);
  }

  // ─── Seed Default Data ────────────────────────────────────────────────────

  /// Called on first login — populates the DB with sample academic data
  Future<void> seedData(String uid, String email) async {
    final db = await database;

    // Check if already seeded
    final existing = await db.query('courses',
        where: 'uid = ?', whereArgs: [uid], limit: 1);
    if (existing.isNotEmpty) return;

    // Profile
    await db.insert('student_profile', {
      'uid': uid, 'name': 'Alex Johnson', 'email': email,
      'student_id': 'STU-2024-001', 'major': 'Computer Science',
      'year': 'Junior', 'phone': '+1 (555) 123-4567',
      'address': '123 Campus Drive, Dorm A, Room 204',
      'enroll_status': 'Full-time', 'start_date': 'Fall 2023',
      'graduation': 'Spring 2027', 'gpa': 3.75,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // Courses
    final courses = [
      {'id': 'cs201', 'code': 'CS 201', 'name': 'Data Structures',
       'instructor': 'Dr. Smith', 'time': '9:00 AM - 10:30 AM',
       'location': 'Tech Building, Room 204', 'days': 'Mon, Wed, Fri',
       'credits': 4, 'color_hex': '#4F8EF7'},
      {'id': 'cs305', 'code': 'CS 305', 'name': 'Database Systems',
       'instructor': 'Prof. Johnson', 'time': '11:00 AM - 12:30 PM',
       'location': 'Science Hall, Room 101', 'days': 'Tue, Thu',
       'credits': 3, 'color_hex': '#22C55E'},
      {'id': 'cs340', 'code': 'CS 340', 'name': 'Web Development',
       'instructor': 'Dr. Williams', 'time': '2:00 PM - 3:30 PM',
       'location': 'Tech Building, Room 305', 'days': 'Mon, Wed',
       'credits': 3, 'color_hex': '#A855F7'},
      {'id': 'cs401', 'code': 'CS 401', 'name': 'Software Engineering',
       'instructor': 'Prof. Brown', 'time': '4:00 PM - 5:30 PM',
       'location': 'Engineering Building, Room 210', 'days': 'Tue, Thu',
       'credits': 4, 'color_hex': '#F97316'},
      {'id': 'cs350', 'code': 'CS 350', 'name': 'Computer Networks',
       'instructor': 'Prof. Lee', 'time': '10:00 AM - 11:30 AM',
       'location': 'Tech Building, Room 150', 'days': 'Mon, Wed, Fri',
       'credits': 3, 'color_hex': '#EF4444'},
    ];

    for (final c in courses) {
      await db.insert('courses', {...c, 'uid': uid},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // Assignments
    final assignments = {
      'cs201': [
        {'id': 'cs201_a1', 'name': 'Assignment 1', 'weight': 0.15, 'score': 95, 'total': 100},
        {'id': 'cs201_a2', 'name': 'Assignment 2', 'weight': 0.15, 'score': 88, 'total': 100},
        {'id': 'cs201_mid', 'name': 'Midterm Exam', 'weight': 0.30, 'score': 90, 'total': 100},
        {'id': 'cs201_fin', 'name': 'Final Project', 'weight': 0.40, 'score': 94, 'total': 100},
      ],
      'cs305': [
        {'id': 'cs305_l1', 'name': 'Lab 1', 'weight': 0.20, 'score': 88, 'total': 100},
        {'id': 'cs305_q1', 'name': 'Quiz 1', 'weight': 0.15, 'score': 85, 'total': 100},
        {'id': 'cs305_mid', 'name': 'Midterm', 'weight': 0.30, 'score': 82, 'total': 100},
        {'id': 'cs305_fin', 'name': 'Final Exam', 'weight': 0.35, 'score': 78, 'total': 100},
      ],
      'cs340': [
        {'id': 'cs340_p1', 'name': 'Project 1', 'weight': 0.25, 'score': 90, 'total': 100},
        {'id': 'cs340_p2', 'name': 'Project 2', 'weight': 0.25, 'score': 82, 'total': 100},
        {'id': 'cs340_mid', 'name': 'Midterm', 'weight': 0.25, 'score': 79, 'total': 100},
        {'id': 'cs340_fin', 'name': 'Final Project', 'weight': 0.25, 'score': 85, 'total': 100},
      ],
      'cs401': [
        {'id': 'cs401_s1', 'name': 'Sprint 1', 'weight': 0.20, 'score': 88, 'total': 100},
        {'id': 'cs401_s2', 'name': 'Sprint 2', 'weight': 0.20, 'score': 90, 'total': 100},
        {'id': 'cs401_dd', 'name': 'Design Doc', 'weight': 0.30, 'score': 85, 'total': 100},
        {'id': 'cs401_fs', 'name': 'Final Sprint', 'weight': 0.30, 'score': 92, 'total': 100},
      ],
      'cs350': [
        {'id': 'cs350_l1', 'name': 'Lab 1', 'weight': 0.20, 'score': 80, 'total': 100},
        {'id': 'cs350_l2', 'name': 'Lab 2', 'weight': 0.20, 'score': 75, 'total': 100},
        {'id': 'cs350_mid', 'name': 'Midterm', 'weight': 0.30, 'score': 72, 'total': 100},
        {'id': 'cs350_fin', 'name': 'Final Exam', 'weight': 0.30, 'score': 78, 'total': 100},
      ],
    };

    for (final courseId in assignments.keys) {
      for (final a in assignments[courseId]!) {
        await db.insert('assignments', {...a, 'uid': uid, 'course_id': courseId},
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }

    // Calendar events
    final now = DateTime.now();
    final events = [
      {'id': 'ev1', 'title': 'Data Structures Midterm', 'course_code': 'CS 201',
       'time': '9:00 AM', 'date': DateTime(now.year, now.month, now.day + 4).millisecondsSinceEpoch, 'type': 'exam'},
      {'id': 'ev2', 'title': 'Web Development Project Due', 'course_code': 'CS 340',
       'time': '11:59 PM', 'date': DateTime(now.year, now.month, now.day + 6).millisecondsSinceEpoch, 'type': 'assignment'},
      {'id': 'ev3', 'title': 'Spring Career Fair', 'course_code': '',
       'time': '10:00 AM', 'date': DateTime(now.year, now.month, now.day + 8).millisecondsSinceEpoch, 'type': 'event'},
      {'id': 'ev4', 'title': 'DB Systems Quiz', 'course_code': 'CS 305',
       'time': '11:00 AM', 'date': DateTime(now.year, now.month, now.day + 3).millisecondsSinceEpoch, 'type': 'exam'},
      {'id': 'ev5', 'title': 'Software Eng. Sprint Due', 'course_code': 'CS 401',
       'time': '5:30 PM', 'date': DateTime(now.year, now.month, now.day + 10).millisecondsSinceEpoch, 'type': 'assignment'},
    ];

    for (final e in events) {
      await db.insert('calendar_events', {...e, 'uid': uid},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // Notifications
    final notifs = [
      {'id': 'n1', 'title': 'Grade Posted',
       'body': 'Your grade for CS 201 Assignment 2 has been posted: 88/100',
       'time_ago': '2 hours ago', 'type': 'grade', 'action_label': 'Grades', 'is_read': 0},
      {'id': 'n2', 'title': 'Upcoming Deadline',
       'body': "Web Development Project is due in 3 days. Don't forget to submit!",
       'time_ago': '5 hours ago', 'type': 'deadline', 'action_label': 'Assignments', 'is_read': 0},
      {'id': 'n3', 'title': 'Class Cancelled',
       'body': 'CS 350 class has been cancelled. Check calendar for makeup date.',
       'time_ago': '1 day ago', 'type': 'cancelled', 'action_label': 'Schedule', 'is_read': 0},
      {'id': 'n4', 'title': 'Registration Reminder',
       'body': 'Fall 2026 course registration opens on April 20.',
       'time_ago': '1 day ago', 'type': 'info', 'action_label': 'Registration', 'is_read': 1},
      {'id': 'n5', 'title': 'New Announcement',
       'body': 'Prof. Johnson posted a new announcement in CS 305.',
       'time_ago': '2 days ago', 'type': 'info', 'action_label': 'Courses', 'is_read': 1},
    ];

    final ts = DateTime.now().millisecondsSinceEpoch;
    for (final n in notifs) {
      await db.insert('notifications', {...n, 'uid': uid, 'created_at': ts},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // ─── Delete All User Data ─────────────────────────────────────────────────

  Future<void> clearUserData(String uid) async {
    final db = await database;
    for (final table in ['student_profile', 'courses', 'assignments',
        'calendar_events', 'notifications']) {
      await db.delete(table, where: 'uid = ?', whereArgs: [uid]);
    }
  }

  // ─── Row Mappers ──────────────────────────────────────────────────────────

  StudentProfile _profileFromRow(Map<String, dynamic> r) => StudentProfile(
        uid: r['uid'], name: r['name'], email: r['email'],
        studentId: r['student_id'] ?? '', major: r['major'] ?? '',
        year: r['year'] ?? '', phone: r['phone'] ?? '',
        address: r['address'] ?? '', enrollmentStatus: r['enroll_status'] ?? '',
        startDate: r['start_date'] ?? '', expectedGraduation: r['graduation'] ?? '',
        gpa: (r['gpa'] ?? 0.0).toDouble(),
      );

  Course _courseFromRow(Map<String, dynamic> r) => Course(
        id: r['id'], code: r['code'], name: r['name'],
        instructor: r['instructor'] ?? '', time: r['time'] ?? '',
        location: r['location'] ?? '', days: r['days'] ?? '',
        credits: r['credits'] ?? 3, colorHex: r['color_hex'] ?? '#4F8EF7',
      );

  Assignment _assignmentFromRow(Map<String, dynamic> r) => Assignment(
        id: r['id'], name: r['name'],
        weight: (r['weight'] ?? 0.0).toDouble(),
        score: r['score'] ?? 0, total: r['total'] ?? 100,
      );

  CalendarEvent _eventFromRow(Map<String, dynamic> r) => CalendarEvent(
        id: r['id'], title: r['title'],
        courseCode: r['course_code'] ?? '',
        time: r['time'] ?? '',
        date: DateTime.fromMillisecondsSinceEpoch(r['date']),
        type: _parseEventType(r['type'] ?? 'event'),
      );

  AppNotification _notifFromRow(Map<String, dynamic> r) => AppNotification(
        id: r['id'], title: r['title'], body: r['body'],
        timeAgo: r['time_ago'] ?? '',
        type: _parseNotifType(r['type'] ?? 'info'),
        actionLabel: r['action_label'] ?? '',
        isRead: r['is_read'] == 1,
      );

  EventType _parseEventType(String t) {
    switch (t) {
      case 'exam':       return EventType.exam;
      case 'assignment': return EventType.assignment;
      case 'holiday':    return EventType.holiday;
      default:           return EventType.event;
    }
  }

  String _eventTypeStr(EventType t) {
    switch (t) {
      case EventType.exam:       return 'exam';
      case EventType.assignment: return 'assignment';
      case EventType.holiday:    return 'holiday';
      default:                   return 'event';
    }
  }

  NotificationType _parseNotifType(String t) {
    switch (t) {
      case 'grade':     return NotificationType.grade;
      case 'deadline':  return NotificationType.deadline;
      case 'cancelled': return NotificationType.cancelled;
      default:          return NotificationType.info;
    }
  }

  String _notifTypeStr(NotificationType t) {
    switch (t) {
      case NotificationType.grade:     return 'grade';
      case NotificationType.deadline:  return 'deadline';
      case NotificationType.cancelled: return 'cancelled';
      default:                         return 'info';
    }
  }
}
