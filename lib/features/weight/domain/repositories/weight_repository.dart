import 'package:dartz/dartz.dart';
import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/weight/domain/entities/weight_entry.dart';

/// Repository contract for weigh-ins. `create`/`update`/`delete` also
/// cascade the latest weight onto `pets/{petId}.currentWeightKg` when
/// appropriate (spec rules 1 and 2).
abstract class WeightRepository {
  /// All weigh-ins for the pet, ordered by date descending.
  Stream<List<WeightEntry>> watchByPet(String householdId, String petId);

  Future<Either<Failure, WeightEntry>> create(WeightEntry entry);
  Future<Either<Failure, WeightEntry>> update(WeightEntry entry);
  Future<Either<Failure, Unit>> delete(
    String householdId,
    String petId,
    String entryId,
  );
}
