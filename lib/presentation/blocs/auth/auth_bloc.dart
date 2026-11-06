import 'dart:async';
import 'package:expense/core/auth/auth_session_store.dart';
import 'package:expense/core/auth/google_oauth_client.dart';
import 'package:expense/presentation/blocs/auth/profile_name.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_instantdb/flutter_instantdb.dart';

enum AuthStatus { authenticated, unauthenticated, loading }

class AppAuthState {
  final AuthStatus status;
  final AuthUser? user;
  final String? displayName;
  AppAuthState(this.status, {this.user, this.displayName});
}

/// Auth over InstantDB. Reflects [InstantDB.auth.currentUser] and supports
/// passwordless magic-code plus Google OAuth sign-in.
class AuthCubit extends Cubit<AppAuthState> {
  final InstantDB db;
  final AuthSessionStore sessionStore;
  final GoogleOAuthClient? googleOAuthClient;
  late final StreamSubscription<AuthUser?> _sub;
  void Function()? _profileDispose;

  AuthCubit(this.db, this.sessionStore, {this.googleOAuthClient})
    : super(AppAuthState(AuthStatus.loading)) {
    _watchProfile(db.auth.currentUser.value);
    _sub = db.auth.onAuthStateChange.listen(_watchProfile);
  }

  void _watchProfile(AuthUser? user) {
    _profileDispose?.call();
    _profileDispose = null;

    if (user == null) {
      emit(AppAuthState(AuthStatus.unauthenticated));
      return;
    }

    void emitUser([String? profileName]) {
      emit(
        AppAuthState(
          AuthStatus.authenticated,
          user: user,
          displayName: resolveDisplayName(
            email: user.email,
            metadata: user.metadata,
            profileName: profileName,
          ),
        ),
      );
    }

    emitUser();
    final profileQuery = db.subscribeQuery({
      'profiles': {
        'where': {'id': user.id},
      },
    });
    _profileDispose = effect(() {
      final profiles = profileQuery.value.data?['profiles'];
      final profile = profiles is List && profiles.isNotEmpty
          ? profiles.first
          : null;
      final profileName = profile is Map ? profile['name'] as String? : null;
      emitUser(profileName);
    });
  }

  Future<void> sendMagicCode(String email) =>
      db.auth.sendMagicCode(email: email);

  /// Verify the code, then ensure a `profiles` row exists for this user.
  Future<void> verifyMagicCode(String email, String code) async {
    final user = await db.auth.verifyMagicCode(email: email, code: code);
    await _completeSignIn(user);
  }

  bool get isGoogleSignInAvailable => googleOAuthClient != null;

  Future<void> signInWithGoogle() async {
    final client = googleOAuthClient;
    if (client == null) {
      throw StateError('Google authentication is not configured.');
    }
    final user = await client.signIn();
    await _completeSignIn(user);
  }

  Future<void> _completeSignIn(AuthUser user) async {
    final refreshToken = user.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      await db.auth.signOut();
      throw StateError('InstantDB did not return a refresh token.');
    }
    try {
      await sessionStore.writeRefreshToken(refreshToken);
    } catch (_) {
      await db.auth.signOut();
      rethrow;
    }
    await _ensureProfile(user);
  }

  Future<void> _ensureProfile(AuthUser user) async {
    try {
      final res = await db.queryOnce({
        'profiles': {
          'where': {'id': user.id},
        },
      });
      final existing = res.data?['profiles'];
      if (existing is List && existing.isNotEmpty) return;
      final name = resolveDisplayName(
        email: user.email,
        metadata: user.metadata,
      );
      final ops = <Operation>[
        ...db.tx['profiles'].create({
          'id': user.id,
          'name': name,
          'email': user.email,
        }).operations,
        ...db.tx['profiles'][user.id].link({'user': user.id}).operations,
      ];
      await db.transact(ops);
    } catch (_) {
      // Non-fatal: profile can be created lazily later.
    }
  }

  Future<void> updateDisplayName(String name) async {
    final user = db.auth.currentUser.value;
    if (user == null) throw StateError('User is not authenticated.');

    final normalized = normalizeDisplayName(name);
    await db.transact(
      db.tx['profiles'][user.id].update({
        'name': normalized,
        'email': user.email,
      }),
    );
    emit(
      AppAuthState(
        AuthStatus.authenticated,
        user: user,
        displayName: normalized,
      ),
    );
  }

  Future<void> signOut() async {
    await sessionStore.clear();
    await db.auth.signOut();
  }

  @override
  Future<void> close() {
    _profileDispose?.call();
    _sub.cancel();
    return super.close();
  }
}
