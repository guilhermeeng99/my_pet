import 'package:dartz/dartz.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/auth/domain/entities/auth_user.dart';
import 'package:my_pet/features/household/domain/entities/household.dart';
import 'package:my_pet/features/household/domain/entities/household_member.dart';
import 'package:my_pet/features/household/domain/entities/invite.dart';

/// Phase 1.5 contract — owner self-create + 2-member invite/accept flow.
/// Member-management actions (remove, transfer, rename) land later (see
/// [`docs/specs/household.md`](../../../../../docs/specs/household.md)).
abstract class HouseholdRepository {
  Stream<Household?> watch(String householdId);
  Future<Either<Failure, Household>> createForUser(AuthUser user);

  /// Generates a fresh 6-char code and stores it under `inviteCodes/{code}`.
  /// Fails with [HouseholdFullFailure] when the household already has 2
  /// members.
  Future<Either<Failure, Invite>> generateInvite({
    required String householdId,
    required String createdBy,
  });

  /// Looks up `inviteCodes/{code}`, validates expiry/usage, and atomically
  /// adds the user to the target household, marks the invite used, and
  /// updates `users/{uid}.householdId`. If the user's prior household is
  /// empty (only themselves, no pets), it is deleted as part of the same
  /// batch — the typical "spouse signs in fresh and joins" flow.
  Future<Either<Failure, Household>> acceptInvite({
    required String code,
    required String userId,
  });

  /// Resolves UIDs in `household.memberIds` into [HouseholdMember]s by
  /// reading `users/{uid}` profile docs.
  Future<Either<Failure, List<HouseholdMember>>> fetchMembers(
    Household household,
  );

  /// Cascade-deletes everything under `households/{id}` (pets and their
  /// subcollections, household-level reminders / documents, active
  /// `inviteCodes`), then the household doc and `users/{uid}` itself. Only
  /// allowed when the user is the sole member — otherwise returns
  /// [HouseholdNotEmptyFailure]. Idempotent so a retry after a failed
  /// `auth.delete()` is safe.
  Future<Either<Failure, Unit>> wipeAndLeave({
    required String householdId,
    required String userId,
  });
}
