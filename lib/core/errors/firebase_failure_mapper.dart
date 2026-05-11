import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:my_pet/core/errors/failures.dart';

/// Translates raw Firebase / IO exceptions into the typed [Failure]
/// hierarchy so the UI can render specific messages instead of a generic
/// "something went wrong" for every error.
///
/// Repositories should `try` their datasource call and pass the caught
/// object + stack trace through this function.
Failure mapFirebaseException(Object error, [StackTrace? stackTrace]) {
  if (error is SocketException || error is TimeoutException) {
    return NetworkFailure(message: error.toString(), cause: stackTrace);
  }

  if (error is FirebaseException) {
    return _mapFirebaseException(error, stackTrace);
  }

  return ServerFailure(message: error.toString(), cause: stackTrace);
}

Failure _mapFirebaseException(FirebaseException e, StackTrace? st) {
  // Firebase uses both 'unavailable' (server) and 'network-request-failed'
  // (client) for transient connectivity problems. Treat both as Network.
  switch (e.code) {
    case 'unavailable':
    case 'network-request-failed':
    case 'deadline-exceeded':
    case 'cancelled':
      return NetworkFailure(message: e.message, cause: st);
    case 'permission-denied':
    case 'unauthenticated':
      return PermissionFailure(message: e.message ?? e.code);
    case 'not-found':
      return NotFoundFailure(message: e.message ?? e.code);
    case 'invalid-argument':
    case 'failed-precondition':
    case 'out-of-range':
      return ValidationFailure(message: e.message ?? e.code);
  }

  return ServerFailure(message: e.message ?? e.code, cause: st);
}
