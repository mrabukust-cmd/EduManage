import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notice_model.dart';
import '../services/firebase_service.dart';

class NoticeRepository {
  NoticeRepository._();
  static final NoticeRepository instance = NoticeRepository._();

  final _fs = FirebaseService.instance;

  Stream<List<NoticeModel>> watchAll({String? category}) {
    Query<Map<String, dynamic>> query =
        _fs.notices.orderBy('createdAt', descending: true);
    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }
    return query.snapshots().map(
          (snap) => snap.docs.map(NoticeModel.fromDoc).toList(),
        );
  }

  Stream<List<NoticeModel>> watchRecent(int limit) {
    return _fs.notices
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(NoticeModel.fromDoc).toList());
  }

  Future<void> create(NoticeModel notice) {
    return _fs.notices.add(notice.toMap());
  }

  Future<void> delete(String id) {
    return _fs.notices.doc(id).delete();
  }
}