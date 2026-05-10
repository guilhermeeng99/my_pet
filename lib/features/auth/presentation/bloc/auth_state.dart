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

/// Signed in but `householdId == null`. The household-setup page picks up
/// this state and asks the user to create their own family or join one with
/// a code (`docs/specs/household.md` rule 1).
class AuthNeedsHousehold extends AuthState {
  const AuthNeedsHousehold(this.user);
  final AuthUser user;
  @override
  List<Object?> get props => [user];
}

/// Transient: the user has chosen "create my own family" on the setup page
/// and we're waiting for the household doc to be created. Lets the page
/// disable buttons and show a spinner without taking the user away early.
class AuthCreatingHousehold extends AuthState {
  const AuthCreatingHousehold(this.user);
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
