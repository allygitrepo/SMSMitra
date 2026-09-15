import 'package:flutter_test/flutter_test.dart';
import 'package:sms_app/core/helpers/validation_helper.dart';

void main() {
  group('ValidationHelper Unit Tests', () {
    test('validateEmail correctly identifies valid and invalid emails', () {
      expect(ValidationHelper.validateEmail('user@smsmitra.com'), isNull);
      expect(ValidationHelper.validateEmail('test.dev@company.in'), isNull);
      expect(ValidationHelper.validateEmail(''), 'Email is required');
      expect(ValidationHelper.validateEmail('invalid-email'), 'Please enter a valid email address');
      expect(ValidationHelper.validateEmail('user@'), 'Please enter a valid email address');
    });

    test('validatePhone correctly validates phone numbers', () {
      expect(ValidationHelper.validatePhone('9876543210'), isNull);
      expect(ValidationHelper.validatePhone('+919876543210'), isNull);
      expect(ValidationHelper.validatePhone(''), 'Phone number is required');
      expect(ValidationHelper.validatePhone('12345'), 'Please enter a valid phone number');
    });

    test('validatePassword requires at least 6 characters', () {
      expect(ValidationHelper.validatePassword('secret123'), isNull);
      expect(ValidationHelper.validatePassword('123456'), isNull);
      expect(ValidationHelper.validatePassword(''), 'Password is required');
      expect(ValidationHelper.validatePassword('123'), 'Password must be at least 6 characters long');
    });

    test('validateConfirmPassword ensures matching passwords', () {
      expect(ValidationHelper.validateConfirmPassword('pass123', 'pass123'), isNull);
      expect(ValidationHelper.validateConfirmPassword('', 'pass123'), 'Please confirm your password');
      expect(ValidationHelper.validateConfirmPassword('pass456', 'pass123'), 'Passwords do not match');
    });

    test('validateNotEmpty validates required fields', () {
      expect(ValidationHelper.validateNotEmpty('Hello World', 'Message'), isNull);
      expect(ValidationHelper.validateNotEmpty('', 'Message'), 'Message is required');
      expect(ValidationHelper.validateNotEmpty('   ', 'Message'), 'Message is required');
    });
  });
}
