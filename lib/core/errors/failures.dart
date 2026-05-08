import 'package:equatable/equatable.dart';

/// Sealed base type for every recoverable failure surfaced from a
/// repository or use case. Returned wrapped in `Either<Failure, T>` from
/// dartz. Never thrown.
sealed class Failure extends Equatable {
  const Failure({this.message, this.cause});

  final String? message;
  final Object? cause;

  @override
  List<Object?> get props => [message, runtimeType];
}

// ── Network / generic ─────────────────────────────────────────────────
final class ServerFailure extends Failure {
  const ServerFailure({super.message, super.cause});
}

final class NetworkFailure extends Failure {
  const NetworkFailure({super.message, super.cause});
}

final class UnknownFailure extends Failure {
  const UnknownFailure({super.message, super.cause});
}

// ── Auth ──────────────────────────────────────────────────────────────
sealed class AuthFailure extends Failure {
  const AuthFailure({super.message, super.cause});
}

final class AuthCancelledFailure extends AuthFailure {
  const AuthCancelledFailure();
}

final class AuthNetworkFailure extends AuthFailure {
  const AuthNetworkFailure({super.cause});
}

final class AuthUnknownFailure extends AuthFailure {
  const AuthUnknownFailure({super.message, super.cause});
}

// ── Domain ────────────────────────────────────────────────────────────
final class NotFoundFailure extends Failure {
  const NotFoundFailure({super.message});
}

final class PermissionFailure extends Failure {
  const PermissionFailure({super.message});
}

final class ValidationFailure extends Failure {
  const ValidationFailure({required String super.message});
}

// ── Household ─────────────────────────────────────────────────────────
final class AlreadyInHouseholdFailure extends Failure {
  const AlreadyInHouseholdFailure();
}

final class InviteExpiredFailure extends Failure {
  const InviteExpiredFailure();
}

final class InviteAlreadyUsedFailure extends Failure {
  const InviteAlreadyUsedFailure();
}

// ── Storage ───────────────────────────────────────────────────────────
final class PhotoTooLargeFailure extends Failure {
  const PhotoTooLargeFailure({required int sizeBytes, required int maxBytes})
      : _sizeBytes = sizeBytes,
        _maxBytes = maxBytes;

  final int _sizeBytes;
  final int _maxBytes;

  int get sizeBytes => _sizeBytes;
  int get maxBytes => _maxBytes;

  @override
  List<Object?> get props => [_sizeBytes, _maxBytes];
}
