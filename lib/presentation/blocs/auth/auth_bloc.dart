import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthEvent {}

class AuthSubscriptionRequested extends AuthEvent {}

class AuthLogoutRequested extends AuthEvent {}

enum AuthStatus { authenticated, unauthenticated, loading }

class AppAuthState {
  final AuthStatus status;
  final User? user;
  AppAuthState(this.status, {this.user});
}

class AuthBloc extends Bloc<AuthEvent, AppAuthState> {
  final SupabaseClient _supabase;

  AuthBloc(this._supabase) : super(AppAuthState(AuthStatus.loading)) {
    on<AuthSubscriptionRequested>((event, emit) async {
      await emit.forEach(
        _supabase.auth.onAuthStateChange,
        onData: (data) {
          final user = data.session?.user;
          return AppAuthState(
            user != null
                ? AuthStatus.authenticated
                : AuthStatus.unauthenticated,
            user: user,
          );
        },
      );
    });

    on<AuthLogoutRequested>((event, emit) async {
      await _supabase.auth.signOut();
    });
  }
}
