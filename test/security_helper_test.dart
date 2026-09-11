import 'package:flutter_test/flutter_test.dart';
import 'package:school_management_system/core/utils/security_helper.dart';

void main() {
  group('SecurityHelper Suite', () {
    test('sanitizeInput removes html tags and dangerous javascript scheme', () {
      const raw = '<b>Hello</b> <script>alert("hack")</script> World <a href="javascript:doEvil()">click</a>';
      final sanitized = SecurityHelper.sanitizeInput(raw);

      expect(sanitized, isNot(contains('<script>')));
      expect(sanitized, isNot(contains('</script>')));
      expect(sanitized, isNot(contains('<b>')));
      expect(sanitized, isNot(contains('javascript:')));
      expect(sanitized, contains('Hello'));
      expect(sanitized, contains('World'));
    });

    test('containsSuspiciousPayload detects SQL and script injection attempts', () {
      expect(SecurityHelper.containsSuspiciousPayload("SELECT * FROM users WHERE '1'='1'"), isTrue);
      expect(SecurityHelper.containsSuspiciousPayload("1' UNION SELECT null, username, password FROM accounts--"), isTrue);
      expect(SecurityHelper.containsSuspiciousPayload("<img src=x onerror=alert(1)>"), isTrue);
      expect(SecurityHelper.containsSuspiciousPayload("javascript:void(0)"), isTrue);

      expect(SecurityHelper.containsSuspiciousPayload("John Doe standard student name"), isFalse);
      expect(SecurityHelper.containsSuspiciousPayload("Mathematics Final Term Examination 2026"), isFalse);
      expect(SecurityHelper.containsSuspiciousPayload("Grade 10 - Section A"), isFalse);
    });

    test('maskEmail obfuscates usernames appropriately', () {
      expect(SecurityHelper.maskEmail('student.john@university.edu'), equals('s***n@university.edu'));
      expect(SecurityHelper.maskEmail('ab@test.com'), equals('a***@test.com'));
      expect(SecurityHelper.maskEmail('invalid-email'), equals('invalid-email'));
    });

    test('maskPhoneNumber masks middle digits', () {
      final masked = SecurityHelper.maskPhoneNumber('+923001234567');
      expect(masked, startsWith('+9230'));
      expect(masked, endsWith('567'));
      expect(masked, contains('*'));
    });

    test('maskNationalId obfuscates identification sequences', () {
      final formattedCnic = SecurityHelper.maskNationalId('17301-1234567-1');
      expect(formattedCnic, equals('17301-*******-1'));

      final nonFormatted = SecurityHelper.maskNationalId('1234567890');
      expect(nonFormatted, startsWith('123'));
      expect(nonFormatted, endsWith('90'));
      expect(nonFormatted, contains('*'));
    });

    test('generateSecureToken produces unique hex strings of requested length', () {
      final token1 = SecurityHelper.generateSecureToken(byteLength: 16);
      final token2 = SecurityHelper.generateSecureToken(byteLength: 16);

      expect(token1.length, 32);
      expect(token2.length, 32);
      expect(token1, isNot(equals(token2)));
    });

    test('constantTimeEquals checks equivalence correctly', () {
      expect(SecurityHelper.constantTimeEquals('secretToken123', 'secretToken123'), isTrue);
      expect(SecurityHelper.constantTimeEquals('secretToken123', 'secretToken456'), isFalse);
      expect(SecurityHelper.constantTimeEquals('short', 'longerString'), isFalse);
    });
  });
}
