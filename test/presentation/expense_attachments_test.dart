import 'dart:async';
import 'package:flutter/services.dart';
import 'package:expense/presentation/widgets/expense_attachments.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Receipt errors distinguish permissions and server timeouts', () {
    expect(
      receiptFailureKey(PlatformException(code: 'photo_access_denied')),
      'receipt_permission_error',
    );
    expect(
      receiptFailureKey(TimeoutException('waiting')),
      'receipt_timeout_error',
    );
    expect(receiptFailureKey(StateError('failed')), 'receipt_error');
  });
  test('Receipts reject empty files and enforce the 10 MB upload limit', () {
    expect(validReceiptSize(-1), isFalse);
    expect(validReceiptSize(0), isFalse);
    expect(validReceiptSize(1), isTrue);
    expect(validReceiptSize(maxReceiptBytes), isTrue);
    expect(validReceiptSize(maxReceiptBytes + 1), isFalse);
  });
}
