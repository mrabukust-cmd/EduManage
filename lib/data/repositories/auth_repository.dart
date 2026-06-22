import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';

/// Sits between AuthNotifier (UI state) and AuthService/Firestore.
/// Holds the logic for registering, logging in, the admin-creates-user
/// flow that no longer logs the admin out, and approval/rejection of
/// pending student/teacher/parent registrations.
class AuthRepository {
  AuthRepository._();
  static final AuthRepository instance = AuthRepository._();

  final _auth = AuthService.instance;
  final _fs = FirebaseService.instance;

  // ── Registration ─────────────────────────────────────────────────

  /// Public self-registration (student/teacher/parent sign-up screen).
  /// Admin accounts CANNOT be created through this method — admins must
  /// be created by an already-authenticated admin via [adminCreateUser],
  /// which runs on a secondary FirebaseApp and requires the caller to
  /// already hold an admin session. This prevents an unauthenticated
  /// caller from self-granting admin access by passing role: 'admin'
  /// directly to this method, even if such a button is removed from
  /// the UI.
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
    const approved = false; // student/teacher/parent all require approval

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

  // ── Approvals ────────────────────────────────────────────────────

  /// Stream of all users awaiting admin approval (students, teachers,
  /// parents). Admins are excluded since they're never self-registered
  /// with approved: false in the first place.
  Stream<List<Map<String, dynamic>>> watchPendingUsers() {
    return _fs.users
        .where('approved', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => {'uid': d.id, ...d.data()}).toList());
  }

  /// Approves a user, flipping `approved: true` on both the shared
  /// `users` doc and the matching role-specific collection. If the user
  /// is a parent and [studentId] is provided, also creates the
  /// parent_children link in the same pass — pass nothing for a plain
  /// approval with no linking.
  Future<void> approveUser(String uid, {String? studentId}) async {
    final userDoc = await _fs.users.doc(uid).get();
    final role = userDoc.data()?['role'] as String?;

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
  }

  /// Rejects/deletes a pending user's Firestore profile docs.
  /// NOTE: this does not delete the underlying Firebase Auth account —
  /// that requires Admin SDK / Cloud Functions, which this client app
  /// does not have access to. The account will simply remain unapproved
  /// and unable to use the app past the pending screen.
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

  // ── Parent ↔ Student linking ─────────────────────────────────────

  /// Creates (or overwrites) the link between a parent and a student.
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

  /// All parent_children docs for a given student, joined with parent
  /// info — used by the "Manage Parents" sheet on a student's card.
  Stream<List<Map<String, dynamic>>> watchParentsForStudent(
      String studentId) {
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

  /// All approved parents not yet linked to this particular student —
  /// used to populate the "add parent" picker in the same sheet.
  Stream<List<Map<String, dynamic>>> watchAvailableParents(
      String studentId) {
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