import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Represents an assignment published by a teacher for a class.
class AssignmentModel {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String className;
  final DateTime? dueDate;
  final String teacherId;
  final String teacherName;
  final String? fileUrl;
  final double? totalMarks;
  final DateTime? createdAt;

  const AssignmentModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.subject,
    required this.className,
    this.dueDate,
    required this.teacherId,
    this.teacherName = '',
    this.fileUrl,
    this.totalMarks,
    this.createdAt,
  });

  factory AssignmentModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String && val.isNotEmpty) {
        try {
          return DateTime.parse(val);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    return AssignmentModel(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      className: (map['className'] as String? ?? '').trim(),
      dueDate: parseDate(map['dueDate']),
      teacherId: map['teacherId'] as String? ?? '',
      teacherName: map['teacherName'] as String? ?? '',
      fileUrl: map['fileUrl'] as String?,
      totalMarks: (map['totalMarks'] as num?)?.toDouble(),
      createdAt: parseDate(map['createdAt']) ?? parseDate(map['timestamp']),
    );
  }

  factory AssignmentModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AssignmentModel.fromMap(doc.id, data);
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'subject': subject,
      'className': className,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'teacherId': teacherId,
      'teacherName': teacherName,
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (totalMarks != null) 'totalMarks': totalMarks,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  bool get isOverdue {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  String get formattedDueDate {
    if (dueDate == null) return 'No due date';
    return DateFormat('MMM d, yyyy').format(dueDate!);
  }

  AssignmentModel copyWith({
    String? id,
    String? title,
    String? description,
    String? subject,
    String? className,
    DateTime? dueDate,
    String? teacherId,
    String? teacherName,
    String? fileUrl,
    double? totalMarks,
    DateTime? createdAt,
  }) {
    return AssignmentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      className: className ?? this.className,
      dueDate: dueDate ?? this.dueDate,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      fileUrl: fileUrl ?? this.fileUrl,
      totalMarks: totalMarks ?? this.totalMarks,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
