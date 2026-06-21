import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirrors a document in the `teachers` collection.
class TeacherModel {
  final String id; // == Firebase Auth uid
  final String name;
  final String email;
  final String phone;
  final String subject;
  final String qualification;
  final List<String> classes;
  final bool approved;
  final DateTime? createdAt;

  const TeacherModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.subject,
    required this.qualification,
    required this.classes,
    this.approved = true,
    this.createdAt,
  });

  factory TeacherModel.fromMap(String id, Map<String, dynamic> map) {
    return TeacherModel(
      id: id,
      name: map['name'] as String? ?? 'Unknown',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      subject: map['subject'] as String? ?? '-',
      qualification: map['qualification'] as String? ?? '-',
      classes: (map['classes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      approved: map['approved'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory TeacherModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TeacherModel.fromMap(doc.id, data);
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': id,
      'name': name,
      'email': email,
      'phone': phone,
      'subject': subject,
      'qualification': qualification,
      'classes': classes,
      'approved': approved,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}