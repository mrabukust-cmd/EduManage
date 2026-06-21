import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../firebase_options.dart';

/// Centralizes every Firebase Auth interaction.
///
/// THE FIX: previously, AddStudentScreen / AddTeacherScreen called
/// `FirebaseAuth.instance.createUserWithEmailAndPassword(...)` directly.
/// Firebase Auth ALWAYS signs in the account it just created, which
/// signed the admin out and forced a "please log in again" dialog.
///
/// The fix is to create the new user on a *separate, secondary*
/// FirebaseApp instance. That secondary app gets its own Auth session,
/// completely independent of the admin's session on the default app.
/// We sign the secondary session out and delete the secondary app right
/// after writing Firestore docs, and the admin is never touched.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> register({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name);
  }

  /// Creates a brand-new Auth user (student/teacher) WITHOUT disturbing
  /// whichever admin is currently signed in on the default app.
  ///
  /// Returns the new user's uid.
  Future<String> createUserKeepingCurrentSessionAlive({
    required String email,
    required String password,
    required String displayName,
  }) async {
    // 1. Spin up a throwaway secondary FirebaseApp. Using a timestamp in
    //    the name guarantees no collisions if this runs more than once.
    final secondaryApp = await Firebase.initializeApp(
      name: 'secondary_${DateTime.now().microsecondsSinceEpoch}',
      options: DefaultFirebaseOptions.currentPlatform,
    );

    try {
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // 2. Create the account on the secondary app. This signs the new
      //    user in on `secondaryAuth`, NOT on the default app, so the
      //    admin's session on FirebaseAuth.instance is untouched.
      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user!.updateDisplayName(displayName);
      final newUid = cred.user!.uid;

      // 3. Clean up: sign out of and delete the secondary app/session.
      await secondaryAuth.signOut();
      return newUid;
    } finally {
      await secondaryApp.delete();
    }
  }

  /// Fetches the role document for [uid] from `users/{uid}`.
  Future<Map<String, dynamic>?> fetchUserDoc(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }
}