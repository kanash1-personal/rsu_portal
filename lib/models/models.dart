// lib/models/models.dart
// Pure Dart models — no Firebase imports needed (data comes from SQLite).

// ─── Student Profile ──────────────────────────────────────────────────────

class StudentProfile {
  final String uid;
  final String name;
  final String email;
  final String studentId;
  final String major;
  final String year;
  final String phone;
  final String address;
  final String enrollmentStatus;
  final String startDate;
  final String expectedGraduation;
  final double gpa;

  const StudentProfile({
    required this.uid, required this.name, required this.email,
    required this.studentId, required this.major, required this.year,
    required this.phone, required this.address, required this.enrollmentStatus,
    required this.startDate, required this.expectedGraduation, required this.gpa,
  });

  StudentProfile copyWith({String? name, String? email, String? phone, String? address, double? gpa}) {
    return StudentProfile(
      uid: uid, name: name ?? this.name, email: email ?? this.email,
      studentId: studentId, major: major, year: year,
      phone: phone ?? this.phone, address: address ?? this.address,
      enrollmentStatus: enrollmentStatus, startDate: startDate,
      expectedGraduation: expectedGraduation, gpa: gpa ?? this.gpa,
    );
  }
}

// ─── Course ───────────────────────────────────────────────────────────────

class Course {
  final String id;
  final String code;
  final String name;
  final String instructor;
  final String time;
  final String location;
  final String days;
  final int credits;
  final String colorHex;
  List<Assignment> assignments;

  Course({
    required this.id, required this.code, required this.name,
    required this.instructor, required this.time, required this.location,
    required this.days, required this.credits, required this.colorHex,
    this.assignments = const [],
  });
}

// ─── Assignment ───────────────────────────────────────────────────────────

class Assignment {
  final String id;
  final String name;
  final double weight;
  final int score;
  final int total;

  const Assignment({
    required this.id, required this.name, required this.weight,
    required this.score, required this.total,
  });

  double get percentage => total > 0 ? score / total : 0.0;
}

// ─── Schedule Entry ───────────────────────────────────────────────────────

class ScheduleEntry {
  final String courseCode;
  final String courseName;
  final String time;
  final String location;
  final String day;

  const ScheduleEntry({
    required this.courseCode, required this.courseName,
    required this.time, required this.location, required this.day,
  });
}

// ─── Calendar Event ───────────────────────────────────────────────────────

class CalendarEvent {
  final String id;
  final String title;
  final String courseCode;
  final String time;
  final DateTime date;
  final EventType type;

  const CalendarEvent({
    required this.id, required this.title, required this.courseCode,
    required this.time, required this.date, required this.type,
  });
}

enum EventType { exam, assignment, event, holiday }

// ─── App Notification ─────────────────────────────────────────────────────

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String timeAgo;
  final NotificationType type;
  final String actionLabel;
  bool isRead;

  AppNotification({
    required this.id, required this.title, required this.body,
    required this.timeAgo, required this.type, required this.actionLabel,
    this.isRead = false,
  });
}

enum NotificationType { grade, deadline, cancelled, info }
