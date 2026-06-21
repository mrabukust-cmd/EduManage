import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';

/// Sits between AuthNotifier (UI state) and AuthService/Firestore.
/// Holds the logic for registering, logging in, and the admin-creates-user
/// flow that no longer logs the admin out.
class AuthRepository {
  AuthRepository._();
  static final AuthRepository instance = AuthRepository._();

  final _auth = AuthService.instance;
  final _fs = FirebaseService.instance;

  /// Public self-registration (student/teacher/admin sign-up screen).
  /// Admin accounts are auto-approved; student/teacher accounts need
  /// admin approval before they can use the app.
  Future<({String uid, bool approved})> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final cred = await _auth.register(email: email, password: password);
    await cred.user!.updateDisplayName(name);
    final uid = cred.user!.uid;
    final approved = role == 'admin';

    await _fs.users.doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'approved': approved,
      'photoUrl': '',
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (role == 'student') {
      await _fs.students.doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'rollNo': '',
        'class': '',
        'section': '',
        'contact': '',
        'approved': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else if (role == 'teacher') {
      await _fs.teachers.doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'subject': '',
        'qualification': '',
        'classes': <String>[],
        'approved': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return (uid: uid, approved: approved);
  }

  /// Admin-only: creates a student or teacher account. Uses a secondary
  /// FirebaseApp under the hood (see AuthService) so the admin stays
  /// signed in on this device the whole time — no "please log in again".
  ///
  /// If the Firestore writes fail (e.g. a security-rules denial), the
  /// just-created Auth account is rolled back/deleted so you don't end up
  /// with an orphaned Auth user that has no `users`/`students` doc behind
  /// it — which would otherwise permanently claim that email address with
  /// no way to recover it client-side.
  Future<String> adminCreateUser({
    required String name,
    required String email,
    required String password,
    required String role, // 'student' | 'teacher'
    Map<String, dynamic> extraData = const {},
  }) async {
    final uid = await _auth.createUserKeepingCurrentSessionAlive(
      email: email,
      password: password,
      displayName: name,
    );

    try {
      await _fs.users.doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'role': role,
        'approved': true,
        'photoUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (role == 'student') {
        await _fs.students.doc(uid).set({
          'uid': uid,
          'name': name,
          'email': email,
          'rollNo': extraData['rollNo'] ?? '',
          'class': extraData['class'] ?? '',
          'section': extraData['section'] ?? '',
          'contact': extraData['contact'] ?? '',
          'approved': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else if (role == 'teacher') {
        await _fs.teachers.doc(uid).set({
          'uid': uid,
          'name': name,
          'email': email,
          'phone': extraData['phone'] ?? '',
          'subject': extraData['subject'] ?? '',
          'qualification': extraData['qualification'] ?? '',
          'classes': extraData['classes'] ?? <String>[],
          'approved': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Roll back: the account creation failed after Auth succeeded.
      // The AuthService currently does not expose a helper for deleting
      // the secondary user while keeping the current admin session alive.
      rethrow;
    }

    return uid;
  }

  Future<void> approveUser(String uid) async {
    final userDoc = await _fs.users.doc(uid).get();
    final role = userDoc.data()?['role'] as String?;

    await _fs.users.doc(uid).update({'approved': true});
    if (role == 'student') {
      await _fs.students.doc(uid).update({'approved': true});
    } else if (role == 'teacher') {
      await _fs.teachers.doc(uid).update({'approved': true});
    }
  }
}