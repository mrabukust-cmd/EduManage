import '../models/student_model.dart';
import '../services/firebase_service.dart';

/// All reads/writes for the `students` collection go through here instead
/// of screens calling FirebaseFirestore.instance directly.
class StudentRepository {
  StudentRepository._();
  static final StudentRepository instance = StudentRepository._();

  final _fs = FirebaseService.instance;

  /// Real-time list of every student, ordered by name.
  Stream<List<StudentModel>> watchAll() {
    return _fs.students.orderBy('name').snapshots().map(
          (snap) => snap.docs.map(StudentModel.fromDoc).toList(),
        );
  }

  /// Real-time list of students in one class (used by attendance & grades).
  Stream<List<StudentModel>> watchByClass(String className) {
    return _fs.students
        .where('class', isEqualTo: className)
        .snapshots()
        .map((snap) => snap.docs.map(StudentModel.fromDoc).toList());
  }

  Stream<int> watchCountByClass(String className) {
    return _fs.students
        .where('class', isEqualTo: className)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Stream<int> watchTotalCount() {
    return _fs.students.snapshots().map((snap) => snap.docs.length);
  }

  Future<StudentModel?> getById(String id) async {
    final doc = await _fs.students.doc(id).get();
    if (!doc.exists) return null;
    return StudentModel.fromDoc(doc);
  }

  Future<void> create(String uid, StudentModel student) {
    return _fs.students.doc(uid).set(student.toMap());
  }

  Future<void> update(String id, Map<String, dynamic> data) {
    return _fs.students.doc(id).update(data);
  }

  Future<void> delete(String id) {
    return _fs.students.doc(id).delete();
  }
}