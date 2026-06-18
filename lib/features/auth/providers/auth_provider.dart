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

  const AuthState({
    this.isLoading = false,
    this.error,
    this.user,
    this.role,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    User? user,
    String? role,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      user: user ?? this.user,
      role: role ?? this.role,
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
    }
  }

  /// Returns error string on failure, null on success
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
      final role = doc.data()?['role'] as String? ?? 'student';

      // Save to prefs for splash routing
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', role);

      state = state.copyWith(
        isLoading: false,
        user: cred.user,
        role: role,
      );

      return null; // success
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false);
      switch (e.code) {
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
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

  /// Returns error string on failure, null on success
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

      // Update display name
      await cred.user!.updateDisplayName(name);

      // Save user doc in Firestore
      await _db.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'name': name,
        'email': email,
        'role': role,
        'photoUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // If student/teacher, create role-specific record
      if (role == 'student') {
        await _db.collection('students').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
          'name': name,
          'email': email,
          'rollNo': '',
          'class': '',
          'section': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else if (role == 'teacher') {
        await _db.collection('teachers').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
          'name': name,
          'email': email,
          'subject': '',
          'qualification': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', role);

      state = state.copyWith(
        isLoading: false,
        user: cred.user,
        role: role,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false);
      switch (e.code) {
        case 'email-already-in-use':
          return 'This email is already registered.';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'weak-password':
          return 'Password is too weak.';
        default:
          return 'Registration failed. Try again.';
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return 'An unexpected error occurred.';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
    state = const AuthState();
  }

  String? get currentRole => state.role;
  User? get currentUser => state.user;

  void signOut() {}
}

// ── Provider ────────────────────────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// Convenience stream provider for auth state changes
final authStreamProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});