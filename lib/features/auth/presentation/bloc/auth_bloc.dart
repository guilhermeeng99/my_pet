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
    on<CreateOwnHouseholdRequested>(_onCreateOwnHouseholdRequested);
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

  void _onStreamUpdated(
    _AuthStreamUpdated event,
    Emitter<AuthState> emit,
  ) {
    final user = event.user;
    if (user == null) {
      emit(const AuthUnauthenticated());
      return;
    }
    // Skip while a create-household round-trip is in flight — otherwise a
    // stream tick mid-operation would clobber AuthCreatingHousehold.
    if (state is AuthCreatingHousehold) return;
    _resolveAndEmit(user, emit);
  }

  /// Resolves the post-sign-in destination. Users with `householdId` go
  /// straight to Home; users without one land on the household-setup page
  /// (NeedsHousehold) and pick between creating or joining.
  void _resolveAndEmit(AuthUser user, Emitter<AuthState> emit) {
    if (user.hasHousehold) {
      emit(AuthAuthenticated(user));
      return;
    }
    emit(AuthNeedsHousehold(user));
  }

  Future<void> _onCreateOwnHouseholdRequested(
    CreateOwnHouseholdRequested event,
    Emitter<AuthState> emit,
  ) async {
    final user = switch (state) {
      AuthNeedsHousehold(:final user) => user,
      AuthAuthenticated(:final user) => user,
      _ => null,
    };
    if (user == null || user.hasHousehold) return;
    emit(AuthCreatingHousehold(user));
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
