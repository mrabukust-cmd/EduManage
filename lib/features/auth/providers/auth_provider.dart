import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_management_system/data/repositories/auth_repository.dart';
import 'package:school_management_system/data/services/auth_service.dart';

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
  final AuthService _auth = AuthService.instance;
  final AuthRepository _repo = AuthRepository.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  void _init() {
    final user = _auth.currentUser;
    if (user != null) {
      state = state.copyWith(user: user);
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
      final cred = await _auth.signIn(email: email, password: password);

      final doc = await _db.collection('users').doc(cred.user!.uid).get();
      if (!doc.exists) {
        await _auth.signOut();
        state = state.copyWith(isLoading: false);
        return 'Account not found. Contact your administrator.';
      }

      final data = doc.data()!;
      final role = data['role'] as String? ?? 'student';
      final approved = data['approved'] as bool? ?? false;

      if (role != 'admin' && !approved) {
        state = state.copyWith(
          isLoading: false,
          isPending: true,
          user: cred.user,
          role: role,
        );
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
      final result = await _repo.register(
        name: name,
        email: email,
        password: password,
        role: role,
      );

      state = state.copyWith(
        isLoading: false,
        user: _auth.currentUser,
        role: role,
        isPending: !result.approved,
      );

      if (result.approved) {
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

  /// Admin-only: create a student or teacher account.
  ///
  /// FIXED: this now delegates to AuthRepository.adminCreateUser, which
  /// uses a secondary FirebaseApp instance internally. The admin's
  /// session and `state.user` here are NEVER touched, so no
  /// "please sign in again" dialog and no navigation to /login is needed.
  Future<String?> adminCreateUser({
    required String name,
    required String email,
    required String password,
    required String role, // 'student' | 'teacher'
    Map<String, dynamic> extraData = const {},
  }) async {
    try {
      await _repo.adminCreateUser(
        name: name,
        email: email,
        password: password,
        role: role,
        extraData: extraData,
      );
      return null; // success — admin is still logged in, nothing to restore
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

  /// Approve a pending user (admin action)
  Future<void> approveUser(String uid) => _repo.approveUser(uid);

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
  return AuthService.instance.authStateChanges();
});