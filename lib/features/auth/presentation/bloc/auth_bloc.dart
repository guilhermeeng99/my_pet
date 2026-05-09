import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/auth/domain/entities/auth_user.dart';
import 'package:my_pet/features/auth/domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Global authentication bloc — singleton (CLAUDE.md / Lifecycle). Owns the
/// `watchAuthState` subscription so the rest of the app can react to
/// sign-in/out without re-subscribing.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository repository})
      : _repository = repository,
        super(const AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<_AuthStreamUpdated>(_onStreamUpdated);

    add(const AuthStarted());
  }

  final AuthRepository _repository;
  StreamSubscription<AuthUser?>? _subscription;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    await _subscription?.cancel();
    _subscription = _repository.watchAuthState().listen(
          (user) => add(_AuthStreamUpdated(user)),
        );
  }

  Future<void> _onGoogleSignInRequested(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _repository.signInWithGoogle();
    result.fold(
      (failure) {
        // Cancellation is not a destructive error — return silently to the
        // sign-in screen (spec rule 5).
        if (failure is AuthCancelledFailure) {
          emit(const AuthUnauthenticated());
          return;
        }
        emit(AuthErrorState(failure));
      },
      (user) {
        // Stream listener will also fire, but emit eagerly so the UI moves
        // forward without waiting for the round-trip.
        emit(_resolveAuthenticated(user));
      },
    );
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _repository.signOut();
    result.fold(
      (failure) => emit(AuthErrorState(failure)),
      (_) => emit(const AuthUnauthenticated()),
    );
  }

  void _onStreamUpdated(_AuthStreamUpdated event, Emitter<AuthState> emit) {
    final user = event.user;
    if (user == null) {
      emit(const AuthUnauthenticated());
      return;
    }
    emit(_resolveAuthenticated(user));
  }

  AuthState _resolveAuthenticated(AuthUser user) {
    if (!user.hasHousehold) return AuthNeedsHousehold(user);
    return AuthAuthenticated(user);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
