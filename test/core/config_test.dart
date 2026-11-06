import 'package:expense/core/config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validAppId = '123e4567-e89b-12d3-a456-426614174000';
  const validApiUri = 'https://api.instantdb.site';
  const validEnvironment = {
    'INSTANTDB_APP_ID': validAppId,
    'INSTANTDB_API_URI': validApiUri,
  };

  group('AppConfig', () {
    test('loads the production environment explicitly', () {
      final config = AppConfig.fromEnvironment(
        flavor: AppFlavor.prod,
        environment: validEnvironment,
      );

      expect(config.flavor, AppFlavor.prod);
      expect(config.instantAppId, validAppId);
      expect(config.instantApiUri, Uri.parse(validApiUri));
      expect(config.appName, 'G-spend');
      expect(config.isDevelopment, isFalse);
      expect(AppConfig.environmentFileFor(config.flavor), '.env.prod');
    });

    test('loads the development environment explicitly', () {
      final config = AppConfig.fromEnvironment(
        flavor: AppFlavor.dev,
        environment: validEnvironment,
      );

      expect(config.flavor, AppFlavor.dev);
      expect(config.appName, 'G-spend Dev');
      expect(config.isDevelopment, isTrue);
      expect(AppConfig.environmentFileFor(config.flavor), '.env.dev');
    });

    test('rejects a missing InstantDB app id', () {
      expect(
        () => AppConfig.fromEnvironment(
          flavor: AppFlavor.prod,
          environment: const {},
        ),
        throwsStateError,
      );
    });

    test('rejects an invalid InstantDB app id', () {
      expect(
        () => AppConfig.fromEnvironment(
          flavor: AppFlavor.prod,
          environment: const {
            'INSTANTDB_APP_ID': 'not-a-uuid',
            'INSTANTDB_API_URI': validApiUri,
          },
        ),
        throwsFormatException,
      );
    });

    test('rejects a missing InstantDB API URI', () {
      expect(
        () => AppConfig.fromEnvironment(
          flavor: AppFlavor.prod,
          environment: const {'INSTANTDB_APP_ID': validAppId},
        ),
        throwsStateError,
      );
    });

    test('rejects an invalid InstantDB API URI', () {
      expect(
        () => AppConfig.fromEnvironment(
          flavor: AppFlavor.prod,
          environment: const {
            'INSTANTDB_APP_ID': validAppId,
            'INSTANTDB_API_URI': 'not-a-url',
          },
        ),
        throwsFormatException,
      );
    });

    test('keeps Google auth disabled without OAuth settings', () {
      final config = AppConfig.fromEnvironment(
        flavor: AppFlavor.dev,
        environment: validEnvironment,
      );

      expect(config.isGoogleAuthEnabled, isFalse);
      expect(config.googleOAuthClientName, isNull);
      expect(config.googleOAuthRedirectUri, isNull);
    });

    test('accepts a complete Google OAuth override', () {
      final config = AppConfig.fromEnvironment(
        flavor: AppFlavor.dev,
        environment: const {
          'INSTANTDB_APP_ID': validAppId,
          'INSTANTDB_API_URI': validApiUri,
          'GOOGLE_OAUTH_CLIENT_NAME': 'google-dev',
          'GOOGLE_OAUTH_REDIRECT_URI': 'gspend.dev://oauth',
        },
      );

      expect(config.googleOAuthClientName, 'google-dev');
      expect(config.googleOAuthRedirectUri, Uri.parse('gspend.dev://oauth'));
    });

    test('rejects an incomplete Google OAuth override', () {
      expect(
        () => AppConfig.fromEnvironment(
          flavor: AppFlavor.dev,
          environment: const {
            'INSTANTDB_APP_ID': validAppId,
            'INSTANTDB_API_URI': validApiUri,
            'GOOGLE_OAUTH_CLIENT_NAME': 'google',
          },
        ),
        throwsStateError,
      );
    });
  });
}
