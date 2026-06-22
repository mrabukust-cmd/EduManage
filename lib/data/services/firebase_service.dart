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
  CollectionReference<Map<String, dynamic>> get parents =>
      db.collection('parents');
  CollectionReference<Map<String, dynamic>> get parentChildren =>
      db.collection('parent_children');
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

//-----------------------------------
// import 'dart:io';
// import 'package:firebase_storage/firebase_storage.dart';

// /// Handles profile photo uploads. Pairs with the /profile_photos/{uid}/
// /// path convention enforced in storage.rules.
// class StorageService {
//   StorageService._();
//   static final StorageService instance = StorageService._();

//   final FirebaseStorage _storage = FirebaseStorage.instance;

//   /// Uploads [file] as the current user's profile photo and returns the
//   /// public download URL to save into UserModel.photoUrl.
//   Future<String> uploadProfilePhoto({
//     required String uid,
//     required File file,
//   }) async {
//     final ref = _storage.ref('profile_photos/$uid/avatar.jpg');
//     await ref.putFile(file);
//     return ref.getDownloadURL();
//   }

//   Future<void> deleteProfilePhoto(String uid) async {
//     final ref = _storage.ref('profile_photos/$uid/avatar.jpg');
//     try {
//       await ref.delete();
//     } catch (_) {
//       // No-op if there was never a photo to delete.
//     }
//   }
// }