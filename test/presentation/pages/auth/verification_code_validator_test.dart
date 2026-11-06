import 'package:expense/presentation/pages/auth/verification_code_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('verification code validation', () {
    test('accepts exactly six digits', () {
      expect(isValidVerificationCode('123456'), isTrue);
      expect(verificationCodeValidationKey('123456'), isNull);
    });

    test('rejects incomplete and non-numeric values', () {
      expect(isValidVerificationCode('12345'), isFalse);
      expect(isValidVerificationCode('12345a'), isFalse);
      expect(
        verificationCodeValidationKey('12345'),
        'verification_code_length',
      );
    });
  });
}
