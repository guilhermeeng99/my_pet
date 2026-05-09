import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/auth/domain/entities/auth_user.dart';
import 'package:my_pet/features/auth/domain/repositories/auth_repository.dart';
import 'package:my_pet/features/household/domain/repositories/household_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Global authentication bloc — singleton (CLAUDE.md / Lifecycle). Owns the
/// `watchAuthState` subscription so the rest of the app can react to
/// sign-in/out without re-subscribing.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required AuthRepository repository,
    required HouseholdRepository householdRepository,
  })  : _repository = repository,
        _households = householdRepository,
        super(const AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<_AuthStreamUpdated>(_onStreamUpdated);

    add(const AuthStarted());
  }

  final AuthRepository _repository;
  final HouseholdRepository _households;
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
    await result.fold(
      (failure) async {
        // Cancellation is not a destructive error — return silently to the
        // sign-in screen (spec rule 5).
        if (failure is AuthCancelledFailure) {
          emit(const AuthUnauthenticated());
          return;
        }
        emit(AuthErrorState(failure));
      },
      (user) => _resolveAndEmit(user, emit),
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

  Future<void> _onStreamUpdated(
    _AuthStreamUpdated event,
    Emitter<AuthState> emit,
  ) async {
    final user = event.user;
    if (user == null) {
      emit(const AuthUnauthenticated());
      return;
    }
    await _resolveAndEmit(user, emit);
  }

  /// Decides whether the user lands on Authenticated or NeedsHousehold and,
  /// if NeedsHousehold, kicks off the auto-create flow (household.md rule 1).
  Future<void> _resolveAndEmit(AuthUser user, Emitter<AuthState> emit) async {
    if (user.hasHousehold) {
      emit(AuthAuthenticated(user));
      return;
    }
    emit(AuthNeedsHousehold(user));
    final created = await _households.createForUser(user);
    created.fold(
      (failure) => emit(AuthErrorState(failure)),
      (household) => emit(AuthAuthenticated(
        user.copyWith(householdId: household.id),
      )),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
