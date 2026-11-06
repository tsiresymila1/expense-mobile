import 'package:expense/core/auth/google_oauth_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseOAuthAuthorizationCode', () {
    test('returns the authorization code for a valid callback', () {
      expect(
        parseOAuthAuthorizationCode(
          'ts.mila.expense://login-callback?code=auth-code&state=expected',
          expectedState: 'expected',
        ),
        'auth-code',
      );
    });

    test('rejects a callback with a different state', () {
      expect(
        () => parseOAuthAuthorizationCode(
          'ts.mila.expense://login-callback?code=auth-code&state=other',
          expectedState: 'expected',
        ),
        throwsA(isA<OAuthCallbackException>()),
      );
    });

    test('surfaces the provider error', () {
      expect(
        () => parseOAuthAuthorizationCode(
          'ts.mila.expense://login-callback?error=access_denied',
        ),
        throwsA(isA<OAuthCallbackException>()),
      );
    });

    test('rejects a callback without an authorization code', () {
      expect(
        () => parseOAuthAuthorizationCode('ts.mila.expense://login-callback'),
        throwsA(isA<OAuthCallbackException>()),
      );
    });
  });
}
