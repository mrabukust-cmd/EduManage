import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirrors a document in the `notices` collection.
/// Replaces the hardcoded `NoticeModel` + `_notices` list that previously
/// lived inline in notices_board_screen.dart.
class NoticeModel {
  final String id;
  final String title;
  final String body;
  final String category; // 'Event' | 'Exam' | 'Finance' | 'Holiday' | 'General'
  final String author;
  final DateTime? createdAt;

  const NoticeModel({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.author,
    this.createdAt,
  });

  factory NoticeModel.fromMap(String id, Map<String, dynamic> map) {
    return NoticeModel(
      id: id,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      author: map['author'] as String? ?? 'Admin',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory NoticeModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return NoticeModel.fromMap(doc.id, data);
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'category': category,
      'author': author,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  /// Short date label like "Jun 16" for list display.
  String get dateLabel {
    if (createdAt == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[createdAt!.month - 1]} ${createdAt!.day}';
  }
}