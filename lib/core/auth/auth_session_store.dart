import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class AuthSessionStore {
  Future<String?> readRefreshToken();

  Future<void> writeRefreshToken(String refreshToken);

  Future<void> clear();
}

final class SecureAuthSessionStore implements AuthSessionStore {
  SecureAuthSessionStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(storageNamespace: 'g_spend_auth'),
            iOptions: IOSOptions(
              accountName: 'g_spend_auth',
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  static const String _refreshTokenKey = 'instantdb_refresh_token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  @override
  Future<void> writeRefreshToken(String refreshToken) {
    if (refreshToken.trim().isEmpty) {
      throw ArgumentError.value(
        refreshToken,
        'refreshToken',
        'Refresh token must not be empty.',
      );
    }
    return _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  @override
  Future<void> clear() => _storage.delete(key: _refreshTokenKey);
}

final class AuthSessionRestorer {
  const AuthSessionRestorer(this._store);

  final AuthSessionStore _store;

  Future<bool> restore({
    required Future<void> Function(String refreshToken) verify,
  }) async {
    final token = await _store.readRefreshToken();
    if (token == null || token.isEmpty) return false;

    try {
      await verify(token);
      return true;
    } catch (_) {
      await _store.clear();
      return false;
    }
  }
}
