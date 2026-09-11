import 'dart:math';

/// Security utility suite providing sanitization, PII masking, and cryptographic token generation.
class SecurityHelper {
  SecurityHelper._();

  static final Random _secureRandom = Random.secure();

  static final RegExp _htmlTagRegex = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
  static final RegExp _scriptInjectionRegex = RegExp(
    r'(<script|javascript:|onerror=|onload=|document\.cookie|eval\(|<iframe|<object)',
    caseSensitive: false,
  );
  static final RegExp _sqlInjectionRegex = RegExp(
    r"(\b(UNION(\s+ALL)?|SELECT|INSERT|UPDATE|DELETE|DROP|ALTER|CREATE|TRUNCATE)\b.*(\bFROM\b|\bINTO\b|\bTABLE\b)|--|\bOR\b\s+['\d]+=['\d]+)",
    caseSensitive: false,
  );

  /// Strips raw HTML tags and dangerous protocols from user inputs.
  static String sanitizeInput(String input) {
    if (input.isEmpty) return '';
    var sanitized = input.replaceAll(_htmlTagRegex, '');
    sanitized = sanitized
        .replaceAll('javascript:', '')
        .replaceAll('vbscript:', '')
        .replaceAll(RegExp(r'data:text/html', caseSensitive: false), '');
    return sanitized.trim();
  }

  /// Evaluates whether an input contains potentially malicious script or SQL fragments.
  static bool containsSuspiciousPayload(String input) {
    if (input.isEmpty) return false;
    return _scriptInjectionRegex.hasMatch(input) || _sqlInjectionRegex.hasMatch(input);
  }

  /// Masks email addresses to protect Personally Identifiable Information (PII).
  ///
  /// Example: `john.doe@domain.com` -> `j***e@domain.com`
  static String maskEmail(String email) {
    final trimmed = email.trim();
    final atIndex = trimmed.indexOf('@');
    if (atIndex <= 1) return trimmed;

    final username = trimmed.substring(0, atIndex);
    final domain = trimmed.substring(atIndex);

    if (username.length <= 2) {
      return '${username[0]}***$domain';
    }

    final first = username[0];
    final last = username[username.length - 1];
    return '$first***$last$domain';
  }

  /// Masks phone numbers while preserving country and dialing prefixes.
  ///
  /// Example: `+923001234567` -> `+92300****567`
  static String maskPhoneNumber(String phone) {
    final clean = phone.trim();
    if (clean.length < 8) return clean;

    final prefixLength = (clean.length * 0.4).floor();
    final suffixLength = (clean.length * 0.3).floor();
    final maskLength = clean.length - prefixLength - suffixLength;

    final prefix = clean.substring(0, prefixLength);
    final suffix = clean.substring(clean.length - suffixLength);
    return '$prefix${'*' * maskLength}$suffix';
  }

  /// Masks national identity or student registration numbers.
  ///
  /// Example: `17301-1234567-1` -> `17301-******-1`
  static String maskNationalId(String id) {
    final clean = id.trim();
    if (clean.length < 6) return clean;

    final parts = clean.split('-');
    if (parts.length == 3) {
      return '${parts[0]}-${'*' * parts[1].length}-${parts[2]}';
    }

    final start = clean.substring(0, 3);
    final end = clean.substring(clean.length - 2);
    return '$start${'*' * (clean.length - 5)}$end';
  }

  /// Generates a cryptographically secure random hexadecimal token.
  static String generateSecureToken({int byteLength = 16}) {
    final values = List<int>.generate(byteLength, (i) => _secureRandom.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Performs a constant-time equality check to prevent timing attacks.
  static bool constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}
