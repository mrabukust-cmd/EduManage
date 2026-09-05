import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a classroom / section entity in the institution.
class ClassModel {
  final String id;
  final String name;
  final String classTeacher;
  final String? classTeacherId;
  final String? room;
  final int? capacity;
  final DateTime? createdAt;

  const ClassModel({
    required this.id,
    required this.name,
    this.classTeacher = '',
    this.classTeacherId,
    this.room,
    this.capacity,
    this.createdAt,
  });

  factory ClassModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return ClassModel(
      id: id,
      name: (map['name'] as String? ?? '').trim(),
      classTeacher: (map['classTeacher'] as String? ?? '').trim(),
      classTeacherId: map['classTeacherId'] as String?,
      room: map['room'] as String?,
      capacity: (map['capacity'] as num?)?.toInt(),
      createdAt: parseDate(map['createdAt']) ?? parseDate(map['timestamp']),
    );
  }

  factory ClassModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ClassModel.fromMap(doc.id, data);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'classTeacher': classTeacher,
      if (classTeacherId != null) 'classTeacherId': classTeacherId,
      if (room != null) 'room': room,
      if (capacity != null) 'capacity': capacity,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  ClassModel copyWith({
    String? id,
    String? name,
    String? classTeacher,
    String? classTeacherId,
    String? room,
    int? capacity,
    DateTime? createdAt,
  }) {
    return ClassModel(
      id: id ?? this.id,
      name: name ?? this.name,
      classTeacher: classTeacher ?? this.classTeacher,
      classTeacherId: classTeacherId ?? this.classTeacherId,
      room: room ?? this.room,
      capacity: capacity ?? this.capacity,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
