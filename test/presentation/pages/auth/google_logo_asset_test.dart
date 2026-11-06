import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Google logo asset is bundled', (tester) async {
    final logo = await rootBundle.load('assets/images/google_g.png');

    expect(logo.lengthInBytes, greaterThan(0));
  });
}
