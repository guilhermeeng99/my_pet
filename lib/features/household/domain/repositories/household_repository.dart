import 'package:dartz/dartz.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/auth/domain/entities/auth_user.dart';
import 'package:my_pet/features/household/domain/entities/household.dart';

/// Phase-1 contract — only what's needed for auto-create + observation.
/// Members management (invite, remove, transfer) lands in Phase 3 alongside
/// the rest of [`specs/household.md`](../../../../../specs/household.md).
abstract class HouseholdRepository {
  Stream<Household?> watch(String householdId);
  Future<Either<Failure, Household>> createForUser(AuthUser user);
}
