import 'package:dartz/dartz.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/auth/domain/entities/auth_user.dart';
import 'package:my_pet/features/household/data/datasources/household_firestore_datasource.dart';
import 'package:my_pet/features/household/domain/entities/household.dart';
import 'package:my_pet/features/household/domain/repositories/household_repository.dart';

class HouseholdRepositoryImpl implements HouseholdRepository {
  HouseholdRepositoryImpl({required HouseholdFirestoreDatasource datasource})
      : _datasource = datasource;

  final HouseholdFirestoreDatasource _datasource;

  @override
  Stream<Household?> watch(String householdId) => _datasource.watch(householdId);

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

  /// Mirrors household.md ("{ownerDisplayName}'s family"). Falls back to
  /// "My family" when the user has no display name (rare on Google).
  String _defaultNameFor(AuthUser user) {
    final base = user.displayName?.trim();
    if (base == null || base.isEmpty) return 'My family';
    return "$base's family";
  }
}
