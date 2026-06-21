import '../models/teacher_model.dart';
import '../services/firebase_service.dart';

class TeacherRepository {
  TeacherRepository._();
  static final TeacherRepository instance = TeacherRepository._();

  final _fs = FirebaseService.instance;

  Stream<List<TeacherModel>> watchAll() {
    return _fs.teachers.orderBy('name').snapshots().map(
          (snap) => snap.docs.map(TeacherModel.fromDoc).toList(),
        );
  }

  Stream<int> watchTotalCount() {
    return _fs.teachers.snapshots().map((snap) => snap.docs.length);
  }

  Future<TeacherModel?> getById(String id) async {
    final doc = await _fs.teachers.doc(id).get();
    if (!doc.exists) return null;
    return TeacherModel.fromDoc(doc);
  }

  Future<void> create(String uid, TeacherModel teacher) {
    return _fs.teachers.doc(uid).set(teacher.toMap());
  }

  Future<void> update(String id, Map<String, dynamic> data) {
    return _fs.teachers.doc(id).update(data);
  }

  Future<void> delete(String id) {
    return _fs.teachers.doc(id).delete();
  }

  /// Classes assigned to a teacher: prefers the `classes` array on the
  /// teacher doc, falls back to matching `classTeacher` on `classes` docs.
  Stream<List<String>> watchAssignedClassNames({
    required String uid,
    required String teacherName,
  }) {
    return _fs.teachers.doc(uid).snapshots().asyncMap((snapshot) async {
      final data = snapshot.data();
      final fromTeacher = (data?['classes'] as List<dynamic>?)
              ?.map((e) => e.toString().trim())
              .where((v) => v.isNotEmpty)
              .toSet()
              .toList() ??
          <String>[];
      if (fromTeacher.isNotEmpty) {
        fromTeacher.sort();
        return fromTeacher;
      }

      if (teacherName.trim().isEmpty) return <String>[];

      final classSnap = await _fs.classes
          .where('classTeacher', isEqualTo: teacherName)
          .get();
      final fromClasses = classSnap.docs
          .map((d) => (d.data()['name'] as String? ?? '').trim())
          .where((v) => v.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      return fromClasses;
    });
  }
}