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

/// Internal: fired whenever the underlying stream emits a new user.
class _AuthStreamUpdated extends AuthEvent {
  const _AuthStreamUpdated(this.user);
  final AuthUser? user;
  @override
  List<Object?> get props => [user];
}
