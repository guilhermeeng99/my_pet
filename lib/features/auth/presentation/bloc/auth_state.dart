part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final AuthUser user;
  @override
  List<Object?> get props => [user];
}

/// Signed in but `householdId == null`. Triggers the auto-create flow.
class AuthNeedsHousehold extends AuthState {
  const AuthNeedsHousehold(this.user);
  final AuthUser user;
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthErrorState extends AuthState {
  const AuthErrorState(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
