import 'package:flutter_test/flutter_test.dart';
import 'package:school_management_system/core/utils/validators.dart';

void main() {
  group('Validators Engine Test Suite', () {
    test('required validator detects null, empty, and whitespace strings', () {
      expect(Validators.required(null), 'This field is required');
      expect(Validators.required(''), 'This field is required');
      expect(Validators.required('   '), 'This field is required');
      expect(Validators.required('Valid text'), isNull);
    });

    test('email validator verifies valid and invalid email addresses', () {
      expect(Validators.email(null), 'Email is required');
      expect(Validators.email(''), 'Email is required');
      expect(Validators.email('not-an-email'), 'Enter a valid email');
      expect(Validators.email('user@'), 'Enter a valid email');
      expect(Validators.email('student@edumanage.com'), isNull);
      expect(Validators.email('teacher.name@school.edu.pk'), isNull);
    });

    test('password and confirmPassword validators operate accurately', () {
      expect(Validators.password(null), 'Password is required');
      expect(Validators.password('12345', minLength: 6), 'Minimum 6 characters');
      expect(Validators.password('secret123', minLength: 6), isNull);

      expect(Validators.confirmPassword('secret123', 'secret999'), 'Passwords do not match');
      expect(Validators.confirmPassword('secret123', 'secret123'), isNull);
    });

    test('numeric, amount, score, and gpa validators validate bounds correctly', () {
      expect(Validators.numeric('not-num'), 'This field must be a valid number');
      expect(Validators.numeric('42.5'), isNull);

      expect(Validators.amount('-5', min: 0), 'Amount cannot be less than 0.0');
      expect(Validators.amount('1500', min: 0, max: 1000), 'Amount cannot exceed 1000.0');
      expect(Validators.amount('750.50', min: 0, max: 1000), isNull);

      expect(Validators.score('105'), 'Score must be between 0.0 and 100.0');
      expect(Validators.score('-1'), 'Score must be between 0.0 and 100.0');
      expect(Validators.score('85.5'), isNull);

      expect(Validators.gpa('4.5'), 'GPA must be between 0.0 and 4.0');
      expect(Validators.gpa('3.85'), isNull);
    });

    test('rollNo, url, and date validators work accurately', () {
      expect(Validators.rollNo('bad roll!'), 'Enter a valid alphanumeric roll number');
      expect(Validators.rollNo('STD-2026-001'), isNull);

      expect(Validators.url('htp:/invalid'), 'Enter a valid URL');
      expect(Validators.url('https://res.cloudinary.com/demo/image.png'), isNull);

      expect(Validators.date('2026/09/07'), 'Format must be YYYY-MM-DD');
      expect(Validators.date('2026-09-07'), isNull);
    });

    test('sanitizers clean strings predictably', () {
      expect(Validators.cleanPhone('+1 (555) 234-5678'), '+15552345678');
      expect(Validators.sanitizeText('  Grade    10   -   A   '), 'Grade 10 - A');
      expect(Validators.normalizeEmail('  Admin@EduManage.ORG  '), 'admin@edumanage.org');
    });

    test('composite validator chains multiple rules in sequence', () {
      final composite = Validators.compose([
        (v) => Validators.required(v, fieldName: 'Fee amount'),
        (v) => Validators.numeric(v, fieldName: 'Fee amount'),
        (v) => Validators.amount(v, min: 10, max: 5000),
      ]);

      expect(composite(''), 'Fee amount is required');
      expect(composite('abc'), 'Fee amount must be a valid number');
      expect(composite('5'), 'Amount cannot be less than 10.0');
      expect(composite('6000'), 'Amount cannot exceed 5000.0');
      expect(composite('2500'), isNull);
    });
  });
}
