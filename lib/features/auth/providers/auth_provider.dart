import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_management_system/data/repositories/auth_repository.dart';
import 'package:school_management_system/data/services/auth_service.dart';
import 'package:school_management_system/data/services/notification_service.dart';

// ── Auth state ──────────────────────────────────────────────
class AuthState {
  final bool isLoading;
  final bool isInitializing;
  final String? error;
  final User? user;
  final String? role;
  final bool isPending;

  const AuthState({
    this.isLoading = false,
    this.isInitializing = false,
    this.error,
    this.user,
    this.role,
    this.isPending = false,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isInitializing,
    String? error,
    User? user,
    String? role,
    bool? isPending,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isInitializing: isInitializing ?? this.isInitializing,
      error: error ?? this.error,
      user: user ?? this.user,
      role: role ?? this.role,
      isPending: isPending ?? this.isPending,
    );
  }
}

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
      // isInitializing=true blocks ALL router redirects until
      // Firestore confirms the role and approval status
      state = state.copyWith(user: user, isInitializing: true);
      _restoreRole(user);
    }
    // if user is null, isInitializing stays false → router goes to /login normally
  }

  Future<void> _restoreRole(User user) async {
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        state = state.copyWith(isInitializing: false);
        return;
      }
      final data = doc.data()!;
      final role = data['role'] as String? ?? 'student';
      final approved = data['approved'] as bool? ?? false;

      if (role == 'admin' || approved) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_role', role);
        state = state.copyWith(
          role: role,
          isPending: false,
          isInitializing: false,
        );
      } else {
        state = state.copyWith(
          role: role,
          isPending: true,
          isInitializing: false,
        );
      }
    } catch (_) {
      // On error, release the block so the app doesn't freeze
      state = state.copyWith(isInitializing: false);
    }
  }

  Future<void> refreshApprovalStatus() async {
    final user = state.user;
    if (user == null) return;
    await _restoreRole(user);
  }

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
        return 'This account is not active. Your registration may have '
            'been declined, or the account no longer exists. Please '
            'contact your school administrator.';
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
        return 'PENDING';
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', role);

      state = state.copyWith(
        isLoading: false,
        user: cred.user,
        role: role,
        isPending: false,
      );

      return null;
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

      return null;
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
    } on ArgumentError catch (e) {
      state = state.copyWith(isLoading: false);
      return e.message as String;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return 'An unexpected error occurred: $e';
    }
  }

  Future<String?> adminCreateUser({
    required String name,
    required String email,
    required String password,
    required String role,
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
      return null;
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

  Future<void> approveUser(String uid) => _repo.approveUser(uid);

  Future<void> signOut() async {
    await NotificationService.instance.clearTokenOnSignOut();
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
    state = const AuthState();
  }

  Future<void> logout() => signOut();

  String? get currentRole => state.role;
  User? get currentUser => state.user;
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final authStreamProvider = StreamProvider<User?>((ref) {
  return AuthService.instance.authStateChanges();
});
