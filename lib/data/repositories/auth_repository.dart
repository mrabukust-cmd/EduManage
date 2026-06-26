import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../services/notification_helper.dart';

/// Sits between AuthNotifier (UI state) and AuthService/Firestore.
class AuthRepository {
  AuthRepository._();
  static final AuthRepository instance = AuthRepository._();

  final _auth = AuthService.instance;
  final _fs = FirebaseService.instance;

  // ── Registration ─────────────────────────────────────────────────────────

  /// Public self-registration (student/teacher/parent sign-up screen).
  /// Notifies all admins after a successful registration.
  Future<({String uid, bool approved})> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    if (role == 'admin') {
      throw ArgumentError(
        'Admin accounts cannot be self-registered. '
        'Use adminCreateUser from an authenticated admin session instead.',
      );
    }

    final cred = await _auth.register(email: email, password: password);
    await cred.user!.updateDisplayName(name);
    final uid = cred.user!.uid;
    const approved = false;

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
    } else if (role == 'parent') {
      await _fs.parents.doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'approved': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // ── Notify all admins about the new registration ──────────────────────
    try {
      await AppNotifications.onUserRegistered(
        userName: name,
        role: role,
        email: email,
      );
    } catch (_) {
      // Non-fatal.
    }

    return (uid: uid, approved: approved);
  }

  /// Admin-only: creates a student or teacher account without disturbing
  /// the admin's session. Rolls back Auth if Firestore writes fail.
  Future<String> adminCreateUser({
    required String name,
    required String email,
    required String password,
    required String role,
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
          'subjects': extraData['subjects'] ?? <String>[],
          'subject':
              (extraData['subjects'] as List<dynamic>?)?.isNotEmpty == true
                  ? (extraData['subjects'] as List<dynamic>).first
                  : (extraData['subject'] ?? ''),
          'qualification': extraData['qualification'] ?? '',
          'classes': extraData['classes'] ?? <String>[],
          'approved': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      rethrow;
    }

    return uid;
  }

  // ── Approvals ─────────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchPendingUsers() {
    return _fs.users
        .where('approved', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {'uid': d.id, ...d.data()}).toList(),
        );
  }

  /// Approves a user and notifies them.
  Future<void> approveUser(String uid, {String? studentId}) async {
    final userDoc = await _fs.users.doc(uid).get();
    final data = userDoc.data();
    final role = data?['role'] as String?;
    final name = data?['name'] as String? ?? 'User';

    await _fs.users.doc(uid).update({'approved': true});

    if (role == 'student') {
      await _fs.students.doc(uid).update({'approved': true});
    } else if (role == 'teacher') {
      await _fs.teachers.doc(uid).update({'approved': true});
    } else if (role == 'parent') {
      await _fs.parents.doc(uid).update({'approved': true});
      if (studentId != null && studentId.isNotEmpty) {
        await linkParentToStudent(parentId: uid, studentId: studentId);
      }
    }

    // ── Notify the approved user ──────────────────────────────────────────
    try {
      await AppNotifications.onUserApproved(
        userUid: uid,
        userName: name,
        role: role ?? 'student',
      );
    } catch (_) {
      // Non-fatal.
    }
  }

  /// Rejects/deletes a pending user's Firestore profile docs.
  Future<void> rejectUser(String uid) async {
    final userDoc = await _fs.users.doc(uid).get();
    final role = userDoc.data()?['role'] as String?;

    if (role == 'student') {
      await _fs.students.doc(uid).delete();
    } else if (role == 'teacher') {
      await _fs.teachers.doc(uid).delete();
    } else if (role == 'parent') {
      await _fs.parents.doc(uid).delete();
    }
    await _fs.users.doc(uid).delete();
  }

  // ── Parent ↔ Student linking ──────────────────────────────────────────────

  Future<void> linkParentToStudent({
    required String parentId,
    required String studentId,
  }) async {
    await _fs.parentChildren.doc('${parentId}_$studentId').set({
      'parentId': parentId,
      'studentId': studentId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unlinkParentFromStudent({
    required String parentId,
    required String studentId,
  }) async {
    await _fs.parentChildren.doc('${parentId}_$studentId').delete();
  }

  Stream<List<Map<String, dynamic>>> watchParentsForStudent(String studentId) {
    return _fs.parentChildren
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .asyncMap((snap) async {
      final results = <Map<String, dynamic>>[];
      for (final doc in snap.docs) {
        final parentId = doc.data()['parentId'] as String?;
        if (parentId == null) continue;
        final parentDoc = await _fs.parents.doc(parentId).get();
        if (parentDoc.exists) {
          results.add({
            'parentId': parentId,
            'name': parentDoc.data()?['name'] ?? 'Unknown',
            'email': parentDoc.data()?['email'] ?? '',
          });
        }
      }
      return results;
    });
  }

  Stream<List<Map<String, dynamic>>> watchAvailableParents(String studentId) {
    return _fs.parentChildren
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .asyncMap((linkedSnap) async {
      final linkedIds = linkedSnap.docs
          .map((d) => d.data()['parentId'] as String?)
          .whereType<String>()
          .toSet();
      final allParents =
          await _fs.parents.where('approved', isEqualTo: true).get();
      return allParents.docs
          .where((d) => !linkedIds.contains(d.id))
          .map((d) => {
                'parentId': d.id,
                'name': d.data()['name'] ?? 'Unknown',
                'email': d.data()['email'] ?? '',
              })
          .toList();
    });
  }
}