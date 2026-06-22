/// Centralized app-wide string constants.
///
/// Scope: this only covers strings that were found duplicated verbatim
/// across multiple screens in the existing codebase (app name, role
/// display labels, generic empty-state copy). It deliberately does NOT
/// include Firestore collection names — those already live in
/// `lib/data/services/firebase_service.dart` and duplicating them here
/// would create two sources of truth for the same thing.
///
/// As you find more duplicated literals while building new screens, add
/// them here rather than re-typing the string inline again.
class AppStrings {
  AppStrings._();

  // ── App identity ─────────────────────────────────────────────────────
  static const String appName = 'EduManage';
  static const String appTagline = 'School Management System';

  // ── Role display labels ─────────────────────────────────────────────
  // Previously duplicated inline in profile_screen.dart and
  // edit_profile_screen.dart with slightly different formatting
  // ('Administrator' vs 'Admin' in different spots) — standardized here.
  static const String roleAdmin = 'Administrator';
  static const String roleTeacher = 'Teacher';
  static const String roleStudent = 'Student';
  static const String roleParent = 'Parent';

  static String roleLabel(String? role) {
    switch (role) {
      case 'admin':
        return roleAdmin;
      case 'teacher':
        return roleTeacher;
      case 'parent':
        return roleParent;
      case 'student':
      default:
        return roleStudent;
    }
  }

  // ── Generic empty-state copy ─────────────────────────────────────────
  // Each screen currently writes its own slightly different empty-state
  // string ("No students yet.", "No notices yet.", "No fee records.",
  // etc.). Keeping those screen-specific messages as-is is usually more
  // helpful to the user than a generic one, so this section intentionally
  // only holds the truly generic fallback used when nothing more specific
  // applies.
  static const String genericEmptyState = 'Nothing here yet.';
  static const String genericErrorState = 'Something went wrong. Please try again.';
  static const String genericLoading = 'Loading...';

  // ── Auth ─────────────────────────────────────────────────────────────
  static const String loginPendingMessage =
      'Your account is awaiting admin approval.';
  static const String accountNotFoundMessage =
      'Account not found. Contact your administrator.';

  // ── Validation (kept consistent with Validators class messages) ──────
  static const String fieldRequired = 'This field is required';
  static const String invalidEmail = 'Enter a valid email';
  static const String passwordTooShort = 'Minimum 6 characters';
  static const String passwordsDoNotMatch = 'Passwords do not match';
}