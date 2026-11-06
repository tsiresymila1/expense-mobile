import 'package:expense/presentation/widgets/expense_attachments.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Receipts reject empty files and enforce the 10 MB upload limit', () {
    expect(validReceiptSize(-1), isFalse);
    expect(validReceiptSize(0), isFalse);
    expect(validReceiptSize(1), isTrue);
    expect(validReceiptSize(maxReceiptBytes), isTrue);
    expect(validReceiptSize(maxReceiptBytes + 1), isFalse);
  });
}
