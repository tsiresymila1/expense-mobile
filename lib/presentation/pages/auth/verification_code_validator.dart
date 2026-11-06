const verificationCodeLength = 6;

final RegExp _verificationCodePattern = RegExp(r'^\d{6}$');

bool isValidVerificationCode(String? value) {
  return _verificationCodePattern.hasMatch(value?.trim() ?? '');
}

String? verificationCodeValidationKey(String? value) {
  return isValidVerificationCode(value) ? null : 'verification_code_length';
}
