import 'dart:developer' as developer;

import 'package:dartz/dartz.dart';
import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/core/errors/firebase_failure_mapper.dart';
import 'package:my_pet/features/auth/domain/entities/auth_user.dart';
import 'package:my_pet/features/household/data/datasources/household_firestore_datasource.dart';
import 'package:my_pet/features/household/domain/entities/audit_event.dart';
import 'package:my_pet/features/household/domain/entities/household.dart';
import 'package:my_pet/features/household/domain/entities/household_member.dart';
import 'package:my_pet/features/household/domain/entities/invite.dart';
import 'package:my_pet/features/household/domain/repositories/household_repository.dart';

class HouseholdRepositoryImpl implements HouseholdRepository {
  HouseholdRepositoryImpl({required HouseholdFirestoreDatasource datasource})
      : _datasource = datasource;

  final HouseholdFirestoreDatasource _datasource;

  @override
  Stream<Household?> watch(String householdId) =>
      _datasource.watch(householdId);

  @override
  Future<Either<Failure, Household>> createForUser(AuthUser user) async {
    try {
      final household = await _datasource.createAndLinkToUser(
        userId: user.uid,
        name: _defaultNameFor(user),
      );
      await _bestEffortAudit(
        householdId: household.id,
        action: AuditAction.householdCreated,
        user: user,
      );
      return Right(household);
    } on Exception catch (e, st) {
      return Left(mapFirebaseException(e, st));
    }
  }

  @override
  Future<Either<Failure, Invite>> generateInvite({
    required String householdId,
    required String createdBy,
  }) async {
    try {
      final invite = await _datasource.generateInviteCode(
        householdId: householdId,
        createdBy: createdBy,
      );
      return Right(invite);
    } on HouseholdDatasourceException catch (e) {
      return Left(_mapException(e));
    } on Exception catch (e, st) {
      return Left(mapFirebaseException(e, st));
    }
  }

  @override
  Future<Either<Failure, Household>> acceptInvite({
    required String code,
    required String userId,
  }) async {
    try {
      final household = await _datasource.acceptInviteCode(
        code: code,
        userId: userId,
      );
      return Right(household);
    } on HouseholdDatasourceException catch (e) {
      return Left(_mapException(e));
    } on Exception catch (e, st) {
      return Left(mapFirebaseException(e, st));
    }
  }

  @override
  Future<Either<Failure, List<HouseholdMember>>> fetchMembers(
    Household household,
  ) async {
    try {
      final profiles = await _datasource.fetchMemberProfiles(household.memberIds);
      final byUid = {for (final p in profiles) p.uid: p};
      final members = [
        for (final uid in household.memberIds)
          HouseholdMember(
            uid: uid,
            email: byUid[uid]?.email ?? '',
            displayName: byUid[uid]?.displayName,
            photoUrl: byUid[uid]?.photoUrl,
            role: uid == household.ownerId
                ? HouseholdRole.owner
                : HouseholdRole.partner,
          ),
      ];
      return Right(members);
    } on Exception catch (e, st) {
      return Left(mapFirebaseException(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> wipeAndLeave({
    required String householdId,
    required String userId,
  }) async {
    try {
      await _datasource.wipeAndDelete(
        householdId: householdId,
        userId: userId,
      );
      return const Right(unit);
    } on HouseholdDatasourceException catch (e) {
      return Left(_mapException(e));
    } on Exception catch (e, st) {
      return Left(mapFirebaseException(e, st));
    }
  }

  @override
  Future<Either<Failure, Household>> removeMember({
    required String householdId,
    required AuthUser actor,
    required HouseholdMember target,
  }) async {
    try {
      final household = await _datasource.removeMember(
        householdId: householdId,
        actorUserId: actor.uid,
        memberUserId: target.uid,
      );
      await _datasource.appendAudit(
        householdId: householdId,
        action: AuditAction.memberRemoved,
        actorId: actor.uid,
        actorName: _displayName(actor),
        targetUserId: target.uid,
        targetName: _memberName(target),
      );
      return Right(household);
    } on HouseholdDatasourceException catch (e) {
      return Left(_mapException(e));
    } on Exception catch (e, st) {
      return Left(mapFirebaseException(e, st));
    }
  }

  @override
  Future<Either<Failure, Household>> transferOwnership({
    required String householdId,
    required AuthUser actor,
    required HouseholdMember newOwner,
  }) async {
    try {
      final household = await _datasource.transferOwnership(
        householdId: householdId,
        actorUserId: actor.uid,
        newOwnerId: newOwner.uid,
      );
      await _datasource.appendAudit(
        householdId: householdId,
        action: AuditAction.ownerTransferred,
        actorId: actor.uid,
        actorName: _displayName(actor),
        targetUserId: newOwner.uid,
        targetName: _memberName(newOwner),
      );
      return Right(household);
    } on HouseholdDatasourceException catch (e) {
      return Left(_mapException(e));
    } on Exception catch (e, st) {
      return Left(mapFirebaseException(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> leaveHousehold({
    required String householdId,
    required AuthUser actor,
  }) async {
    try {
      // The audit entry has to be written *before* we leave: once we drop
      // out of memberIds, the rules block our writes.
      await _datasource.appendAudit(
        householdId: householdId,
        action: AuditAction.memberLeft,
        actorId: actor.uid,
        actorName: _displayName(actor),
        targetUserId: actor.uid,
        targetName: _displayName(actor),
      );
      await _datasource.leaveHousehold(
        householdId: householdId,
        userId: actor.uid,
      );
      return const Right(unit);
    } on HouseholdDatasourceException catch (e) {
      return Left(_mapException(e));
    } on Exception catch (e, st) {
      return Left(mapFirebaseException(e, st));
    }
  }

  @override
  Stream<List<AuditEvent>> watchAudit(String householdId) =>
      _datasource.watchAudit(householdId);

  Failure _mapException(HouseholdDatasourceException e) {
    return switch (e) {
      HouseholdFullException() => const HouseholdFullFailure(),
      InviteCodeNotFoundException() => const InviteNotFoundFailure(),
      InviteCodeExpiredException() => const InviteExpiredFailure(),
      InviteCodeAlreadyUsedException() => const InviteAlreadyUsedFailure(),
      AlreadyInHouseholdException() => const AlreadyInHouseholdFailure(),
      HouseholdNotEmptyException() => const HouseholdNotEmptyFailure(),
      HouseholdNotFoundException() => const NotFoundFailure(),
      NotMemberException() => const ValidationFailure(
          message: 'Target is not a member of the household.',
        ),
      CannotRemoveOwnerException() => const ValidationFailure(
          message: 'Transfer ownership before removing the owner.',
        ),
      CannotLeaveAsOwnerException() => const ValidationFailure(
          message: 'Transfer ownership before leaving the household.',
        ),
      NotOwnerException() => const PermissionFailure(
          message: 'Only the owner can perform this action.',
        ),
    };
  }

  /// Audit writes never block a domain operation — Firestore-rule failures
  /// (e.g. transient permission edge cases) are surfaced via logs but the
  /// outer call returns success regardless.
  Future<void> _bestEffortAudit({
    required String householdId,
    required AuditAction action,
    required AuthUser user,
    String? targetUserId,
    String? targetName,
  }) async {
    try {
      await _datasource.appendAudit(
        householdId: householdId,
        action: action,
        actorId: user.uid,
        actorName: _displayName(user),
        targetUserId: targetUserId,
        targetName: targetName,
      );
    } on Exception catch (e, st) {
      // Audit is supplementary, not a precondition for the action — but
      // we log so a chronic write failure (e.g. rules change) doesn't
      // disappear silently from the trail.
      developer.log(
        'Failed to append audit ${action.name} for household $householdId',
        name: 'household.audit',
        error: e,
        stackTrace: st,
      );
    }
  }

  String _displayName(AuthUser user) {
    final name = user.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return user.email;
  }

  String _memberName(HouseholdMember member) {
    final name = member.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return member.email;
  }

  /// Mirrors household.md ("{ownerDisplayName}'s family"). Falls back to
  /// "My family" when the user has no display name (rare on Google).
  String _defaultNameFor(AuthUser user) {
    final base = user.displayName?.trim();
    if (base == null || base.isEmpty) return 'My family';
    return "$base's family";
  }
}
