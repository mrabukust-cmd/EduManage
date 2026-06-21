import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirrors a document in the `results` collection.
class ResultModel {
  final String id;
  final String studentId;
  final String studentName;
  final String className;
  final String subject;
  final String examTitle;
  final double marksObtained;
  final double totalMarks;
  final double percentage;
  final DateTime? createdAt;

  const ResultModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.subject,
    required this.examTitle,
    required this.marksObtained,
    required this.totalMarks,
    required this.percentage,
    this.createdAt,
  });

  factory ResultModel.fromMap(String id, Map<String, dynamic> map) {
    final marks = (map['marksObtained'] as num?)?.toDouble() ?? 0;
    final total = (map['totalMarks'] as num?)?.toDouble() ?? 100;
    return ResultModel(
      id: id,
      studentId: map['studentId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      className: map['className'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      examTitle: map['examTitle'] as String? ?? 'General',
      marksObtained: marks,
      totalMarks: total,
      percentage: (map['percentage'] as num?)?.toDouble() ??
          (total == 0 ? 0 : (marks / total) * 100),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory ResultModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ResultModel.fromMap(doc.id, data);
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'className': className,
      'subject': subject,
      'examTitle': examTitle,
      'marksObtained': marksObtained,
      'totalMarks': totalMarks,
      'percentage': percentage,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  String get letterGrade {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B+';
    if (percentage >= 60) return 'B';
    if (percentage >= 50) return 'C';
    if (percentage >= 40) return 'D';
    return 'F';
  }
}