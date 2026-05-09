import 'package:dartz/dartz.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/auth/domain/entities/auth_user.dart';

/// See [`specs/auth.md`](../../../../../specs/auth.md).
abstract class AuthRepository {
  Stream<AuthUser?> watchAuthState();
  Future<Either<Failure, AuthUser>> signInWithGoogle();
  Future<Either<Failure, Unit>> signOut();
  Future<Either<Failure, AuthUser>> getCurrentUser();
}
