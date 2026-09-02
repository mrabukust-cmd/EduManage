import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a period / schedule slot in a class timetable.
class TimetableModel {
  final String id;
  final String className;
  final String day;
  final String subject;
  final String teacher;
  final String? teacherId;
  final String startTime;
  final String endTime;
  final String? room;
  final DateTime? createdAt;

  const TimetableModel({
    required this.id,
    required this.className,
    required this.day,
    required this.subject,
    required this.teacher,
    this.teacherId,
    required this.startTime,
    required this.endTime,
    this.room,
    this.createdAt,
  });

  factory TimetableModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      return null;
    }

    return TimetableModel(
      id: id,
      className: (map['className'] as String? ?? '').trim(),
      day: (map['day'] as String? ?? '').trim(),
      subject: (map['subject'] as String? ?? '').trim(),
      teacher: (map['teacher'] as String? ?? '').trim(),
      teacherId: map['teacherId'] as String?,
      startTime: (map['startTime'] as String? ?? '').trim(),
      endTime: (map['endTime'] as String? ?? '').trim(),
      room: map['room'] as String?,
      createdAt: parseDate(map['createdAt']) ?? parseDate(map['timestamp']),
    );
  }

  factory TimetableModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TimetableModel.fromMap(doc.id, data);
  }

  Map<String, dynamic> toMap() {
    return {
      'className': className,
      'day': day,
      'subject': subject,
      'teacher': teacher,
      if (teacherId != null) 'teacherId': teacherId,
      'startTime': startTime,
      'endTime': endTime,
      if (room != null) 'room': room,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  String get timeRange => '$startTime - $endTime';

  TimetableModel copyWith({
    String? id,
    String? className,
    String? day,
    String? subject,
    String? teacher,
    String? teacherId,
    String? startTime,
    String? endTime,
    String? room,
    DateTime? createdAt,
  }) {
    return TimetableModel(
      id: id ?? this.id,
      className: className ?? this.className,
      day: day ?? this.day,
      subject: subject ?? this.subject,
      teacher: teacher ?? this.teacher,
      teacherId: teacherId ?? this.teacherId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
