import 'package:flutter_instantdb/flutter_instantdb.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

typedef OAuthBrowserLauncher =
    Future<String> Function({
      required String url,
      required String callbackUrlScheme,
    });

class GoogleOAuthClient {
  GoogleOAuthClient({
    required this.db,
    required this.clientName,
    required this.redirectUri,
    OAuthBrowserLauncher? browserLauncher,
  }) : _browserLauncher = browserLauncher ?? _launchBrowser;

  final InstantDB db;
  final String clientName;
  final Uri redirectUri;
  final OAuthBrowserLauncher _browserLauncher;

  Future<AuthUser> signIn() async {
    final flow = db.auth.createAuthorizationUrl(
      clientName: clientName,
      redirectUri: redirectUri.toString(),
    );
    final callback = await _browserLauncher(
      url: flow.url,
      callbackUrlScheme: redirectUri.scheme,
    );
    final code = parseOAuthAuthorizationCode(
      callback,
      expectedState: flow.state,
    );
    return db.auth.exchangeCodeForToken(
      code: code,
      codeVerifier: flow.codeVerifier,
    );
  }

  static Future<String> _launchBrowser({
    required String url,
    required String callbackUrlScheme,
  }) => FlutterWebAuth2.authenticate(
    url: url,
    callbackUrlScheme: callbackUrlScheme,
  );
}

String parseOAuthAuthorizationCode(String callback, {String? expectedState}) {
  final uri = Uri.parse(callback);
  final error = uri.queryParameters['error'];
  if (error != null && error.isNotEmpty) {
    final description = uri.queryParameters['error_description'];
    throw OAuthCallbackException(description ?? error);
  }

  final returnedState = uri.queryParameters['state'];
  if (expectedState != null &&
      returnedState != null &&
      returnedState != expectedState) {
    throw const OAuthCallbackException('Invalid OAuth state.');
  }

  final code = uri.queryParameters['code'];
  if (code == null || code.trim().isEmpty) {
    throw const OAuthCallbackException(
      'The OAuth callback did not contain an authorization code.',
    );
  }
  return code;
}

class OAuthCallbackException implements Exception {
  const OAuthCallbackException(this.message);

  final String message;

  @override
  String toString() => message;
}
