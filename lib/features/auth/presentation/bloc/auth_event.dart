part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

/// Subscribe to the auth stream. Dispatched by the bloc itself on creation.
class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class GoogleSignInRequested extends AuthEvent {
  const GoogleSignInRequested();
}

class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}

/// Triggered by the household-setup screen when the user picks "Create my
/// family". Calls into [HouseholdRepository.createForUser] and emits
/// [AuthAuthenticated] on success.
class CreateOwnHouseholdRequested extends AuthEvent {
  const CreateOwnHouseholdRequested();
}

/// Internal: fired whenever the underlying stream emits a new user.
class _AuthStreamUpdated extends AuthEvent {
  const _AuthStreamUpdated(this.user);
  final AuthUser? user;
  @override
  List<Object?> get props => [user];
}
