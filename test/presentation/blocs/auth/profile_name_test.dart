import 'package:expense/presentation/blocs/auth/profile_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('profile name', () {
    test('normalizes surrounding whitespace', () {
      expect(normalizeDisplayName('  Jane Doe  '), 'Jane Doe');
    });

    test('rejects a name shorter than two characters', () {
      expect(() => normalizeDisplayName(' J '), throwsArgumentError);
    });

    test('prefers the profile name over auth metadata', () {
      expect(
        resolveDisplayName(
          email: 'jane@example.com',
          profileName: 'Jane Profile',
          metadata: const {'name': 'Jane Metadata'},
        ),
        'Jane Profile',
      );
    });

    test('falls back to auth metadata then the email prefix', () {
      expect(
        resolveDisplayName(
          email: 'jane@example.com',
          metadata: const {'name': 'Jane Metadata'},
        ),
        'Jane Metadata',
      );
      expect(resolveDisplayName(email: 'jane@example.com'), 'jane');
    });
  });
}
