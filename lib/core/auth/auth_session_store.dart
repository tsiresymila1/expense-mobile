import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_instantdb/flutter_instantdb.dart';
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
  Future<void> clear() async {
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: 'instantdb_user');
  }

  Future<void> saveUser(AuthUser user) =>
      _storage.write(key: 'instantdb_user', value: jsonEncode(user.toJson()));

  Future<AuthUser?> readUser() async {
    final value = await _storage.read(key: 'instantdb_user');
    return value == null ? null : AuthUser.fromJson(jsonDecode(value));
  }
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
    } catch (error) {
      final cause = error is InstantException ? error.originalError : error;
      if (cause is! DioException ||
          ![400, 401, 403].contains(cause.response?.statusCode)) {
        rethrow;
      }
      await _store.clear();
      return false;
    }
  }
}
