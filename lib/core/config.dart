enum AppFlavor { dev, prod }

class AppConfig {
  AppConfig._({
    required this.flavor,
    required this.instantAppId,
    required this.instantApiUri,
    required this.googleOAuthClientName,
    required this.googleOAuthRedirectUri,
  });

  final AppFlavor flavor;
  final String instantAppId;
  final Uri instantApiUri;
  final String? googleOAuthClientName;
  final Uri? googleOAuthRedirectUri;

  String get appName => flavor == AppFlavor.prod ? 'G-spend' : 'G-spend Dev';
  String get flavorName => flavor.name;
  bool get isDevelopment => flavor == AppFlavor.dev;
  bool get isGoogleAuthEnabled =>
      googleOAuthClientName != null && googleOAuthRedirectUri != null;

  static String environmentFileFor(AppFlavor flavor) => '.env.${flavor.name}';

  factory AppConfig.fromEnvironment({
    required AppFlavor flavor,
    required Map<String, String> environment,
  }) {
    final appId = environment['INSTANTDB_APP_ID']?.trim() ?? '';
    if (appId.isEmpty) {
      throw StateError(
        'INSTANTDB_APP_ID is missing from ${environmentFileFor(flavor)}.',
      );
    }
    if (!_uuidPattern.hasMatch(appId)) {
      throw FormatException(
        'INSTANTDB_APP_ID in ${environmentFileFor(flavor)} must be a UUID.',
      );
    }

    final apiUriValue = environment['INSTANTDB_API_URI']?.trim() ?? '';
    if (apiUriValue.isEmpty) {
      throw StateError(
        'INSTANTDB_API_URI is missing from ${environmentFileFor(flavor)}.',
      );
    }
    final apiUri = Uri.tryParse(apiUriValue);
    if (apiUri == null ||
        !apiUri.hasAuthority ||
        apiUri.host.isEmpty ||
        (apiUri.scheme != 'https' && apiUri.scheme != 'http')) {
      throw FormatException(
        'INSTANTDB_API_URI in ${environmentFileFor(flavor)} must be an absolute HTTP(S) URL.',
      );
    }

    final googleClientName =
        environment['GOOGLE_OAUTH_CLIENT_NAME']?.trim() ?? '';
    final googleRedirect =
        environment['GOOGLE_OAUTH_REDIRECT_URI']?.trim() ?? '';
    if (googleClientName.isEmpty != googleRedirect.isEmpty) {
      throw StateError(
        'GOOGLE_OAUTH_CLIENT_NAME and GOOGLE_OAUTH_REDIRECT_URI must be set together.',
      );
    }

    Uri? googleRedirectUri;
    if (googleRedirect.isNotEmpty) {
      googleRedirectUri = Uri.tryParse(googleRedirect);
      if (googleRedirectUri == null ||
          !_oauthSchemePattern.hasMatch(googleRedirectUri.scheme)) {
        throw FormatException(
          'GOOGLE_OAUTH_REDIRECT_URI must use a valid lowercase URL scheme.',
        );
      }
    }

    return AppConfig._(
      flavor: flavor,
      instantAppId: appId,
      instantApiUri: apiUri,
      googleOAuthClientName: googleClientName.isEmpty ? null : googleClientName,
      googleOAuthRedirectUri: googleRedirectUri,
    );
  }

  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  static final RegExp _oauthSchemePattern = RegExp(r'^[a-z][a-z0-9+.-]*$');
}
