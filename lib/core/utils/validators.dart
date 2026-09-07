/// Shared form validators used across registration, login, and admin
/// "add user" screens. Centralizes logic that was previously duplicated
/// inline in register_screen.dart, login_screen.dart, add_student_screen.dart,
/// add_teacher_screen.dart, and change_password_screen.dart.
class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w]{2,8}$');
  static final RegExp _urlRegex = RegExp(
    r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
    caseSensitive: false,
  );
  static final RegExp _rollNoRegex = RegExp(r'^[A-Za-z0-9\-_]{2,20}$');
  static final RegExp _dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < minLength) return 'Minimum $minLength characters';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? minLength(String? value, int length, {String fieldName = 'This field'}) {
    if (value == null || value.trim().length < length) {
      return '$fieldName must be at least $length characters';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length < 7) return 'Enter a valid phone number';
    return null;
  }

  static String? numeric(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    final parsed = num.tryParse(value.trim());
    if (parsed == null) return '$fieldName must be a valid number';
    return null;
  }

  static String? amount(String? value, {double min = 0.0, double? max}) {
    if (value == null || value.trim().isEmpty) return 'Amount is required';
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Enter a valid amount';
    if (parsed < min) return 'Amount cannot be less than $min';
    if (max != null && parsed > max) return 'Amount cannot exceed $max';
    return null;
  }

  static String? score(String? value, {double min = 0.0, double max = 100.0}) {
    if (value == null || value.trim().isEmpty) return 'Score is required';
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Enter a numeric score';
    if (parsed < min || parsed > max) return 'Score must be between $min and $max';
    return null;
  }

  static String? gpa(String? value, {double max = 4.0}) {
    if (value == null || value.trim().isEmpty) return 'GPA is required';
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Enter a valid numeric GPA';
    if (parsed < 0.0 || parsed > max) return 'GPA must be between 0.0 and $max';
    return null;
  }

  static String? rollNo(String? value) {
    if (value == null || value.trim().isEmpty) return 'Roll number is required';
    if (!_rollNoRegex.hasMatch(value.trim())) {
      return 'Enter a valid alphanumeric roll number';
    }
    return null;
  }

  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) return 'URL is required';
    if (!_urlRegex.hasMatch(value.trim())) return 'Enter a valid URL';
    return null;
  }

  static String? date(String? value) {
    if (value == null || value.trim().isEmpty) return 'Date is required';
    if (!_dateRegex.hasMatch(value.trim())) return 'Format must be YYYY-MM-DD';
    final parsed = DateTime.tryParse(value.trim());
    if (parsed == null) return 'Invalid calendar date';
    return null;
  }

  // ── Sanitizers ──────────────────────────────────────────────────────────
  static String cleanPhone(String value) {
    return value.replaceAll(RegExp(r'[^\d+]'), '');
  }

  static String sanitizeText(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String normalizeEmail(String value) {
    return value.trim().toLowerCase();
  }

  // ── Composite Validator ─────────────────────────────────────────────────
  static String? Function(String?) compose(
    List<String? Function(String?)> validators,
  ) {
    return (String? value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) return result;
      }
      return null;
    };
  }
}