// lib/models/models.dart
import 'package:cloud_firestore/cloud_firestore.dart';

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
    required this.uid,
    required this.name,
    required this.email,
    required this.studentId,
    required this.major,
    required this.year,
    required this.phone,
    required this.address,
    required this.enrollmentStatus,
    required this.startDate,
    required this.expectedGraduation,
    required this.gpa,
  });

  factory StudentProfile.fromFirestore(Map<String, dynamic> data, String uid) {
    return StudentProfile(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      studentId: data['studentId'] ?? '',
      major: data['major'] ?? '',
      year: data['year'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      enrollmentStatus: data['enrollmentStatus'] ?? '',
      startDate: data['startDate'] ?? '',
      expectedGraduation: data['expectedGraduation'] ?? '',
      gpa: (data['gpa'] ?? 0.0).toDouble(),
    );
  }

  StudentProfile copyWith({String? name, String? email, String? phone, String? address}) {
    return StudentProfile(
      uid: uid, name: name ?? this.name, email: email ?? this.email,
      studentId: studentId, major: major, year: year,
      phone: phone ?? this.phone, address: address ?? this.address,
      enrollmentStatus: enrollmentStatus, startDate: startDate,
      expectedGraduation: expectedGraduation, gpa: gpa,
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

  factory Course.fromFirestore(Map<String, dynamic> data, String id) {
    return Course(
      id: id, code: data['code'] ?? '', name: data['name'] ?? '',
      instructor: data['instructor'] ?? '', time: data['time'] ?? '',
      location: data['location'] ?? '', days: data['days'] ?? '',
      credits: data['credits'] ?? 0, colorHex: data['colorHex'] ?? '#4F8EF7',
    );
  }
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

  factory Assignment.fromFirestore(Map<String, dynamic> data, String id) {
    return Assignment(
      id: id, name: data['name'] ?? '',
      weight: (data['weight'] ?? 0.0).toDouble(),
      score: data['score'] ?? 0, total: data['total'] ?? 100,
    );
  }

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

  factory CalendarEvent.fromFirestore(Map<String, dynamic> data, String id) {
    return CalendarEvent(
      id: id, title: data['title'] ?? '', courseCode: data['courseCode'] ?? '',
      time: data['time'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      type: _parseEventType(data['type'] ?? 'event'),
    );
  }

  static EventType _parseEventType(String t) {
    switch (t) {
      case 'exam':       return EventType.exam;
      case 'assignment': return EventType.assignment;
      case 'holiday':    return EventType.holiday;
      default:           return EventType.event;
    }
  }
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

  factory AppNotification.fromFirestore(Map<String, dynamic> data, String id) {
    return AppNotification(
      id: id, title: data['title'] ?? '', body: data['body'] ?? '',
      timeAgo: data['timeAgo'] ?? '',
      type: _parseType(data['type'] ?? 'info'),
      actionLabel: data['actionLabel'] ?? '',
      isRead: data['isRead'] ?? false,
    );
  }

  static NotificationType _parseType(String t) {
    switch (t) {
      case 'grade':     return NotificationType.grade;
      case 'deadline':  return NotificationType.deadline;
      case 'cancelled': return NotificationType.cancelled;
      default:          return NotificationType.info;
    }
  }
}

enum NotificationType { grade, deadline, cancelled, info }
