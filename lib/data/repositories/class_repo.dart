import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/class_model.dart';
import '../services/firebase_service.dart';

/// Centralized repository for managing classes and section data.
class ClassRepository {
  ClassRepository._();
  static final ClassRepository instance = ClassRepository._();

  final _fs = FirebaseService.instance;

  /// Stream all classes ordered by name.
  Stream<List<ClassModel>> watchAll() {
    return _fs.classes.orderBy('name').snapshots().map(
          (snap) => snap.docs.map(ClassModel.fromDoc).toList(),
        );
  }

  /// Stream unique class names sorted alphabetically.
  Stream<List<String>> watchClassNames() {
    return _fs.classes.orderBy('name').snapshots().map((snap) {
      final names = snap.docs
          .map((d) => (d.data()['name'] as String? ?? '').trim())
          .where((n) => n.isNotEmpty)
          .toSet()
          .toList();
      names.sort();
      return names;
    });
  }

  /// Stream total count of registered classes.
  Stream<int> watchTotalCount() {
    return _fs.classes.snapshots().map((snap) => snap.docs.length);
  }

  /// Get class by document ID.
  Future<ClassModel?> getById(String id) async {
    final doc = await _fs.classes.doc(id).get();
    if (!doc.exists) return null;
    return ClassModel.fromDoc(doc);
  }

  /// Check if a class with the given name already exists.
  Future<bool> existsByName(String name) async {
    final snap = await _fs.classes
        .where('name', isEqualTo: name.trim())
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Create a new class document.
  Future<DocumentReference<Map<String, dynamic>>> create(ClassModel classModel) {
    return _fs.classes.add(classModel.toMap());
  }

  /// Update an existing class document.
  Future<void> update(String id, Map<String, dynamic> data) {
    return _fs.classes.doc(id).update(data);
  }

  /// Delete a class by ID.
  Future<void> delete(String id) {
    return _fs.classes.doc(id).delete();
  }
}
