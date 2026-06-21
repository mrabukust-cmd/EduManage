import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatusValue { present, absent, late, leave, unmarked }

AttendanceStatusValue attendanceStatusFromString(String? s) {
  switch (s) {
    case 'present':
      return AttendanceStatusValue.present;
    case 'absent':
      return AttendanceStatusValue.absent;
    case 'late':
      return AttendanceStatusValue.late;
    case 'leave':
      return AttendanceStatusValue.leave;
    default:
      return AttendanceStatusValue.unmarked;
  }
}

/// Mirrors a single-student document in the `attendance` collection.
class AttendanceModel {
  final String id;
  final String studentId;
  final String studentName;
  final String className;
  final String date; // 'yyyy-MM-dd'
  final AttendanceStatusValue status;
  final DateTime? createdAt;

  const AttendanceModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.date,
    required this.status,
    this.createdAt,
  });

  factory AttendanceModel.fromMap(String id, Map<String, dynamic> map) {
    return AttendanceModel(
      id: id,
      studentId: map['studentId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      className: map['className'] as String? ?? '',
      date: map['date'] as String? ?? '',
      status: attendanceStatusFromString(map['status'] as String?),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ??
          (map['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  factory AttendanceModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AttendanceModel.fromMap(doc.id, data);
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'className': className,
      'date': date,
      'status': status.name,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}