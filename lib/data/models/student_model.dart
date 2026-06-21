import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirrors a document in the `students` collection.
class StudentModel {
  final String id; // == Firebase Auth uid
  final String name;
  final String email;
  final String rollNo;
  final String className; // stored as 'class' in Firestore
  final String section;
  final String contact;
  final bool approved;
  final DateTime? createdAt;

  const StudentModel({
    required this.id,
    required this.name,
    required this.email,
    required this.rollNo,
    required this.className,
    required this.section,
    required this.contact,
    this.approved = true,
    this.createdAt,
  });

  factory StudentModel.fromMap(String id, Map<String, dynamic> map) {
    return StudentModel(
      id: id,
      name: map['name'] as String? ?? 'Unknown',
      email: map['email'] as String? ?? '',
      rollNo: map['rollNo'] as String? ?? '-',
      className: map['class'] as String? ?? 'Unknown',
      section: map['section'] as String? ?? '-',
      contact: map['contact'] as String? ?? '-',
      approved: map['approved'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory StudentModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StudentModel.fromMap(doc.id, data);
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': id,
      'name': name,
      'email': email,
      'rollNo': rollNo,
      'class': className,
      'section': section,
      'contact': contact,
      'approved': approved,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}