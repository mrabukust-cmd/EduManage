import 'package:cloud_firestore/cloud_firestore.dart';

/// Thin wrapper around Firestore so repositories don't each reinvent
/// collection access. Centralizing this also makes it trivial to swap in
/// a fake/mock instance for tests.
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  final FirebaseFirestore db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> collection(String path) =>
      db.collection(path);

  CollectionReference<Map<String, dynamic>> get users => db.collection('users');
  CollectionReference<Map<String, dynamic>> get students =>
      db.collection('students');
  CollectionReference<Map<String, dynamic>> get teachers =>
      db.collection('teachers');
  CollectionReference<Map<String, dynamic>> get classes =>
      db.collection('classes');
  CollectionReference<Map<String, dynamic>> get notices =>
      db.collection('notices');
  CollectionReference<Map<String, dynamic>> get results =>
      db.collection('results');
  CollectionReference<Map<String, dynamic>> get attendance =>
      db.collection('attendance');
  CollectionReference<Map<String, dynamic>> get assignments =>
      db.collection('assignments');
  CollectionReference<Map<String, dynamic>> get timetable =>
      db.collection('timetable');
  CollectionReference<Map<String, dynamic>> get fees => db.collection('fees');
  CollectionReference<Map<String, dynamic>> get notifications =>
      db.collection('notifications');

  Future<void> runBatch(void Function(WriteBatch batch) build) async {
    final batch = db.batch();
    build(batch);
    await batch.commit();
  }
}