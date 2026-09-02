import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/assignment_model.dart';
import '../services/firebase_service.dart';

/// Centralized repository for creating, retrieving, and managing assignments.
class AssignmentRepository {
  AssignmentRepository._();
  static final AssignmentRepository instance = AssignmentRepository._();

  final _fs = FirebaseService.instance;

  /// Stream assignments for a specific class (sorted by due date).
  Stream<List<AssignmentModel>> watchByClass(String className) {
    return _fs.assignments
        .where('className', isEqualTo: className.trim())
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(AssignmentModel.fromDoc).toList();
      list.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
      return list;
    });
  }

  /// Stream assignments created by a specific teacher.
  Stream<List<AssignmentModel>> watchByTeacher(String teacherId) {
    return _fs.assignments
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(AssignmentModel.fromDoc).toList();
      list.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
      return list;
    });
  }

  /// Watch recent assignments for all classes up to [limit].
  Stream<List<AssignmentModel>> watchRecent(int limit) {
    return _fs.assignments
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(AssignmentModel.fromDoc).toList());
  }

  /// Real-time count of total assignments in the system.
  Stream<int> watchTotalCount() {
    return _fs.assignments.snapshots().map((snap) => snap.docs.length);
  }

  /// Get single assignment by ID.
  Future<AssignmentModel?> getById(String id) async {
    final doc = await _fs.assignments.doc(id).get();
    if (!doc.exists) return null;
    return AssignmentModel.fromDoc(doc);
  }

  /// Create a new assignment document.
  Future<DocumentReference<Map<String, dynamic>>> create(
      AssignmentModel assignment) {
    return _fs.assignments.add(assignment.toMap());
  }

  /// Update an existing assignment.
  Future<void> update(String id, Map<String, dynamic> data) {
    return _fs.assignments.doc(id).update(data);
  }

  /// Delete an assignment.
  Future<void> delete(String id) {
    return _fs.assignments.doc(id).delete();
  }
}
