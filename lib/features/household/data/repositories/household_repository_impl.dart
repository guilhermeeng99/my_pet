import 'package:dartz/dartz.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/auth/domain/entities/auth_user.dart';
import 'package:my_pet/features/household/data/datasources/household_firestore_datasource.dart';
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
      return Right(household);
    } on Exception catch (e, st) {
      return Left(ServerFailure(message: e.toString(), cause: st));
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
      return Left(ServerFailure(message: e.toString(), cause: st));
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
      return Left(ServerFailure(message: e.toString(), cause: st));
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
      return Left(ServerFailure(message: e.toString(), cause: st));
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
      return Left(ServerFailure(message: e.toString(), cause: st));
    }
  }

  Failure _mapException(HouseholdDatasourceException e) {
    return switch (e) {
      HouseholdFullException() => const HouseholdFullFailure(),
      InviteCodeNotFoundException() => const InviteNotFoundFailure(),
      InviteCodeExpiredException() => const InviteExpiredFailure(),
      InviteCodeAlreadyUsedException() => const InviteAlreadyUsedFailure(),
      AlreadyInHouseholdException() => const AlreadyInHouseholdFailure(),
      HouseholdNotEmptyException() => const HouseholdNotEmptyFailure(),
    };
  }

  /// Mirrors household.md ("{ownerDisplayName}'s family"). Falls back to
  /// "My family" when the user has no display name (rare on Google).
  String _defaultNameFor(AuthUser user) {
    final base = user.displayName?.trim();
    if (base == null || base.isEmpty) return 'My family';
    return "$base's family";
  }
}
