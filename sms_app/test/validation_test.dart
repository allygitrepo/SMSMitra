import 'package:flutter_test/flutter_test.dart';
import 'package:sms_app/core/helpers/validation_helper.dart';

void main() {
  group('ValidationHelper Unit Tests', () {
    test('validateName validates full name bounds and empty values', () {
      expect(ValidationHelper.validateName('John Doe'), isNull);
      expect(ValidationHelper.validateName('Al'), isNull);
      expect(ValidationHelper.validateName(''), equals('Name is required'));
      expect(ValidationHelper.validateName('   '), equals('Name is required'));
      expect(ValidationHelper.validateName('A'), equals('Name must be at least 2 characters long'));
      expect(
        ValidationHelper.validateName('A' * 51),
        equals('Name cannot exceed 50 characters'),
      );
    });

    test('validateEmail correctly handles RFC patterns and whitespace trimming', () {
      expect(ValidationHelper.validateEmail('user@smsmitra.com'), isNull);
      expect(ValidationHelper.validateEmail('test.dev+tag@company.in'), isNull);
      expect(ValidationHelper.validateEmail('  user@smsmitra.com  '), isNull);
      expect(ValidationHelper.validateEmail(''), equals('Email is required'));
      expect(ValidationHelper.validateEmail('   '), equals('Email is required'));
      expect(ValidationHelper.validateEmail('invalid-email'), equals('Please enter a valid email address'));
      expect(ValidationHelper.validateEmail('user@'), equals('Please enter a valid email address'));
      expect(ValidationHelper.validateEmail('user@domain'), equals('Please enter a valid email address'));
    });

    test('validatePhone validates 10-digit mobile formats and country prefixes', () {
      expect(ValidationHelper.validatePhone('9876543210'), isNull);
      expect(ValidationHelper.validatePhone('8876543210'), isNull);
      expect(ValidationHelper.validatePhone('7876543210'), isNull);
      expect(ValidationHelper.validatePhone('6876543210'), isNull);
      expect(ValidationHelper.validatePhone('+91 98765 43210'), isNull);
      expect(ValidationHelper.validatePhone('919876543210'), isNull);
      expect(ValidationHelper.validatePhone(''), equals('Phone number is required'));
      expect(ValidationHelper.validatePhone('   '), equals('Phone number is required'));
      expect(ValidationHelper.validatePhone('12345'), equals('Please enter a valid 10-digit mobile number'));
      expect(ValidationHelper.validatePhone('1876543210'), equals('Please enter a valid 10-digit mobile number'));
      expect(ValidationHelper.validatePhone('abcdefghij'), equals('Please enter a valid 10-digit mobile number'));
    });

    test('validatePassword requires at least 6 characters', () {
      expect(ValidationHelper.validatePassword('secret123'), isNull);
      expect(ValidationHelper.validatePassword('123456'), isNull);
      expect(ValidationHelper.validatePassword(''), equals('Password is required'));
      expect(ValidationHelper.validatePassword('123'), equals('Password must be at least 6 characters long'));
    });

    test('validateConfirmPassword ensures matching passwords', () {
      expect(ValidationHelper.validateConfirmPassword('pass123', 'pass123'), isNull);
      expect(ValidationHelper.validateConfirmPassword('', 'pass123'), equals('Please confirm your password'));
      expect(ValidationHelper.validateConfirmPassword('pass456', 'pass123'), equals('Passwords do not match'));
    });

    test('validateSmsLimit validates unlimited (-1) and positive quota ranges', () {
      expect(ValidationHelper.validateSmsLimit('-1'), isNull);
      expect(ValidationHelper.validateSmsLimit('1'), isNull);
      expect(ValidationHelper.validateSmsLimit('100'), isNull);
      expect(ValidationHelper.validateSmsLimit('50000'), isNull);
      expect(ValidationHelper.validateSmsLimit(''), equals('SMS limit is required'));
      expect(ValidationHelper.validateSmsLimit('0'), equals('Limit must be at least 1 or -1 for unlimited'));
      expect(ValidationHelper.validateSmsLimit('-2'), equals('Limit must be at least 1 or -1 for unlimited'));
      expect(ValidationHelper.validateSmsLimit('50001'), equals('Daily limit cannot exceed 50,000'));
      expect(ValidationHelper.validateSmsLimit('abc'), equals('Please enter a valid number (-1 for unlimited)'));
    });

    test('validateNotEmpty validates required fields', () {
      expect(ValidationHelper.validateNotEmpty('Hello World', 'Message'), isNull);
      expect(ValidationHelper.validateNotEmpty('', 'Message'), equals('Message is required'));
      expect(ValidationHelper.validateNotEmpty('   ', 'Message'), equals('Message is required'));
    });
  });
}
