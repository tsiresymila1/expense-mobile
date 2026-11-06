import 'package:expense/core/auth/auth_session_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthSessionRestorer', () {
    test('does not verify when there is no stored token', () async {
      final store = _MemoryAuthSessionStore();
      var verificationCount = 0;

      final restored = await AuthSessionRestorer(
        store,
      ).restore(verify: (_) async => verificationCount++);

      expect(restored, isFalse);
      expect(verificationCount, 0);
      expect(store.clearCount, 0);
    });

    test('restores a valid token without deleting it', () async {
      final store = _MemoryAuthSessionStore('valid-token');
      String? verifiedToken;

      final restored = await AuthSessionRestorer(
        store,
      ).restore(verify: (token) async => verifiedToken = token);

      expect(restored, isTrue);
      expect(verifiedToken, 'valid-token');
      expect(store.token, 'valid-token');
      expect(store.clearCount, 0);
    });

    test('deletes a revoked token', () async {
      final store = _MemoryAuthSessionStore('revoked-token');

      final restored = await AuthSessionRestorer(
        store,
      ).restore(verify: (_) async => throw Exception('revoked'));

      expect(restored, isFalse);
      expect(store.token, isNull);
      expect(store.clearCount, 1);
    });
  });
}

final class _MemoryAuthSessionStore implements AuthSessionStore {
  _MemoryAuthSessionStore([this.token]);

  String? token;
  int clearCount = 0;

  @override
  Future<void> clear() async {
    clearCount++;
    token = null;
  }

  @override
  Future<String?> readRefreshToken() async => token;

  @override
  Future<void> writeRefreshToken(String refreshToken) async {
    token = refreshToken;
  }
}
