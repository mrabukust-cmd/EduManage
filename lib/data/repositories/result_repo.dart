import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/result_model.dart';
import '../services/firebase_service.dart';

/// Centralized repository for recording, retrieving, and analyzing student grades and exam results.
class ResultRepository {
  ResultRepository._();
  static final ResultRepository instance = ResultRepository._();

  final _fs = FirebaseService.instance;

  /// Stream all exam results for a specific student.
  Stream<List<ResultModel>> watchByStudent(String studentId) {
    return _fs.results
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(ResultModel.fromDoc).toList();
      list.sort((a, b) {
        final aTime = a.createdAt ?? DateTime(0);
        final bTime = b.createdAt ?? DateTime(0);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  /// Stream exam results for a specific class.
  Stream<List<ResultModel>> watchByClass(String className) {
    return _fs.results
        .where('className', isEqualTo: className.trim())
        .snapshots()
        .map((snap) => snap.docs.map(ResultModel.fromDoc).toList());
  }

  /// Stream exam results for a class and specific exam title.
  Stream<List<ResultModel>> watchByClassAndExam({
    required String className,
    required String examTitle,
  }) {
    return _fs.results
        .where('className', isEqualTo: className.trim())
        .where('examTitle', isEqualTo: examTitle.trim())
        .snapshots()
        .map((snap) => snap.docs.map(ResultModel.fromDoc).toList());
  }

  /// Stream recent exam results across the institution.
  Stream<List<ResultModel>> watchRecent(int limit) {
    return _fs.results
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(ResultModel.fromDoc).toList());
  }

  /// Record an exam result.
  Future<DocumentReference<Map<String, dynamic>>> create(ResultModel result) {
    return _fs.results.add(result.toMap());
  }

  /// Update an existing result record.
  Future<void> update(String id, Map<String, dynamic> data) {
    return _fs.results.doc(id).update(data);
  }

  /// Delete a result record.
  Future<void> delete(String id) {
    return _fs.results.doc(id).delete();
  }
}
