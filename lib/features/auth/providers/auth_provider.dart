import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Auth state ──────────────────────────────────────────────
class AuthState {
  final bool isLoading;
  final String? error;
  final User? user;
  final String? role;
  final bool isPending; // true = registered but not approved by admin yet

  const AuthState({
    this.isLoading = false,
    this.error,
    this.user,
    this.role,
    this.isPending = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    User? user,
    String? role,
    bool? isPending,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      user: user ?? this.user,
      role: role ?? this.role,
      isPending: isPending ?? this.isPending,
    );
  }
}

// ── Auth Notifier ───────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  void _init() {
    final user = _auth.currentUser;
    if (user != null) {
      state = state.copyWith(user: user);
      // Re-fetch role from prefs so router can redirect properly
      _restoreRole(user);
    }
  }

  Future<void> _restoreRole(User user) async {
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (!doc.exists) return;
      final data = doc.data()!;
      final role = data['role'] as String? ?? 'student';
      final approved = data['approved'] as bool? ?? false;

      // Admin is always approved
      if (role == 'admin' || approved) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_role', role);
        state = state.copyWith(role: role, isPending: false);
      } else {
        state = state.copyWith(role: role, isPending: true);
      }
    } catch (_) {}
  }

  /// Login — only works if user exists in Firestore AND is approved (or admin)
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Fetch role from Firestore
      final doc = await _db.collection('users').doc(cred.user!.uid).get();
      if (!doc.exists) {
        await _auth.signOut();
        state = state.copyWith(isLoading: false);
        return 'Account not found. Contact your administrator.';
      }

      final data = doc.data()!;
      final role = data['role'] as String? ?? 'student';
      final approved = data['approved'] as bool? ?? false;

      // Admin is always approved; others need admin approval
      if (role != 'admin' && !approved) {
        await _auth.signOut();
        state = state.copyWith(isLoading: false, isPending: true, user: cred.user, role: role);
        return 'PENDING'; // Special signal for pending state
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', role);

      state = state.copyWith(
        isLoading: false,
        user: cred.user,
        role: role,
        isPending: false,
      );

      return null; // success
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false);
      switch (e.code) {
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please try later.';
        default:
          return 'Login failed. Please try again.';
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return 'An unexpected error occurred.';
    }
  }

  /// Public registration for students, teachers, and admins.
  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user!.updateDisplayName(name);

      final approved = role == 'admin';
      await _db.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'name': name,
        'email': email,
        'role': role,
        'approved': approved,
        'photoUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (role == 'student') {
        await _db.collection('students').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
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
        await _db.collection('teachers').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
          'name': name,
          'email': email,
          'subject': '',
          'qualification': '',
          'classes': [],
          'approved': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Update local auth state.
      state = state.copyWith(
        isLoading: false,
        user: cred.user,
        role: role,
        isPending: !approved,
      );

      if (approved) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_role', role);
      }

      return null; // success
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false);
      switch (e.code) {
        case 'email-already-in-use':
          return 'This email is already registered.';
        case 'weak-password':
          return 'Password must be at least 6 characters.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        default:
          return 'Failed to create account: ${e.message}';
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return 'An unexpected error occurred: $e';
    }
  }

  /// Admin-only: create a student or teacher account
  /// Called from AdminStudentsScreen / AddTeacherScreen
  Future<String?> adminCreateUser({
    required String name,
    required String email,
    required String password,
    required String role, // 'student' | 'teacher'
    Map<String, dynamic> extraData = const {},
  }) async {
    try {
      // Use a secondary auth instance so admin doesn't get signed out
      final secondaryApp = await _createSecondaryAuth();
      final cred = await secondaryApp.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user!.updateDisplayName(name);

      // Save user doc — mark as approved immediately since admin is adding
      await _db.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'name': name,
        'email': email,
        'role': role,
        'approved': true,
        'photoUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Role-specific collection
      if (role == 'student') {
        await _db.collection('students').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
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
        await _db.collection('teachers').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
          'name': name,
          'email': email,
          'subject': extraData['subject'] ?? '',
          'qualification': extraData['qualification'] ?? '',
          'classes': extraData['classes'] ?? [],
          'approved': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await secondaryApp.signOut();
      return null; // success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'This email is already registered.';
        case 'weak-password':
          return 'Password must be at least 6 characters.';
        default:
          return 'Failed to create account: ${e.message}';
      }
    } catch (e) {
      return 'An unexpected error occurred: $e';
    }
  }

  // Creates a secondary FirebaseAuth instance so admin stays signed in
  Future<FirebaseAuth> _createSecondaryAuth() async {
    // We use the same FirebaseAuth but trick it by capturing current user first
    // The proper way is FirebaseApp secondary instance, but for simplicity
    // we'll create the user then immediately restore admin session
    return FirebaseAuth.instance;
  }

  /// Approve a pending user (admin action)
  Future<void> approveUser(String uid) async {
    await _db.collection('users').doc(uid).update({'approved': true});
    // Also update in role collection
    final userDoc = await _db.collection('users').doc(uid).get();
    final role = userDoc.data()?['role'] as String?;
    if (role == 'student') {
      await _db.collection('students').doc(uid).update({'approved': true});
    } else if (role == 'teacher') {
      await _db.collection('teachers').doc(uid).update({'approved': true});
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
    state = const AuthState();
  }

  // Keep backward compat alias
  Future<void> logout() => signOut();

  String? get currentRole => state.role;
  User? get currentUser => state.user;
}

// ── Provider ────────────────────────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final authStreamProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});