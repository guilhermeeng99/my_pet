import 'package:dartz/dartz.dart';
import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/pets/data/datasources/pet_firestore_datasource.dart';
import 'package:my_pet/features/weight/data/datasources/weight_firestore_datasource.dart';
import 'package:my_pet/features/weight/data/models/weight_entry_model.dart';
import 'package:my_pet/features/weight/domain/entities/weight_entry.dart';
import 'package:my_pet/features/weight/domain/repositories/weight_repository.dart';

class WeightRepositoryImpl implements WeightRepository {
  WeightRepositoryImpl({
    required WeightFirestoreDatasource datasource,
    required PetFirestoreDatasource pets,
  })  : _datasource = datasource,
        _pets = pets;

  final WeightFirestoreDatasource _datasource;
  final PetFirestoreDatasource _pets;

  /// Sanity cap from `docs/specs/weight.md` invariants: weights must be
  /// in (0, 200] kg. Sized to catch typos before they hit Firestore.
  static const double _maxKg = 200;

  @override
  Stream<List<WeightEntry>> watchByPet(
    String householdId,
    String petId,
  ) =>
      _datasource.watchByPet(householdId, petId);

  @override
  Future<Either<Failure, WeightEntry>> create(WeightEntry entry) async {
    final invalid = _validate(entry);
    if (invalid != null) return Left(invalid);
    try {
      final created =
          await _datasource.create(WeightEntryModel.fromEntity(entry));
      await _cascadeLatestWeight(created);
      return Right(created);
    } on Exception catch (e, st) {
      return Left(ServerFailure(message: e.toString(), cause: st));
    }
  }

  @override
  Future<Either<Failure, WeightEntry>> update(WeightEntry entry) async {
    final invalid = _validate(entry);
    if (invalid != null) return Left(invalid);
    try {
      final updated =
          await _datasource.update(WeightEntryModel.fromEntity(entry));
      await _cascadeLatestWeight(updated);
      return Right(updated);
    } on Exception catch (e, st) {
      return Left(ServerFailure(message: e.toString(), cause: st));
    }
  }

  @override
  Future<Either<Failure, Unit>> delete(
    String householdId,
    String petId,
    String entryId,
  ) async {
    try {
      await _datasource.delete(householdId, petId, entryId);
      await _recomputeAfterDelete(householdId, petId);
      return const Right(unit);
    } on Exception catch (e, st) {
      return Left(ServerFailure(message: e.toString(), cause: st));
    }
  }

  /// Spec rule 1: only the latest-by-date entry cascades onto
  /// `pets/{petId}.currentWeightKg`. Future entries always win; backfilled
  /// historical entries do not overwrite.
  Future<void> _cascadeLatestWeight(WeightEntry entry) async {
    final stream =
        _datasource.watchByPet(entry.householdId, entry.petId);
    final list = await stream.first;
    if (list.isEmpty) return;
    final latest =
        list.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
    if (latest.id != entry.id) return;
    try {
      await _pets.setCurrentWeight(
        entry.householdId,
        entry.petId,
        latest.weightKg,
      );
    } on Exception {
      // Non-fatal: the entry was saved; the cascade is a denorm helper.
    }
  }

  /// Spec rule 2: deleting the most recent entry recomputes
  /// `currentWeightKg` to the new latest (or clears it if no entries
  /// remain).
  Future<void> _recomputeAfterDelete(
    String householdId,
    String petId,
  ) async {
    final list = await _datasource.watchByPet(householdId, petId).first;
    final next = list.isEmpty
        ? null
        : list.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
    try {
      await _pets.setCurrentWeight(householdId, petId, next?.weightKg);
    } on Exception {
      // Non-fatal — see above.
    }
  }

  ValidationFailure? _validate(WeightEntry e) {
    if (e.weightKg <= 0 || e.weightKg > _maxKg) {
      return const ValidationFailure(
        message: 'Weight must be greater than 0 and at most 200 kg.',
      );
    }
    if (e.date.isAfter(DateTime.now().toUtc())) {
      return const ValidationFailure(
        message: 'Weigh-in date cannot be in the future.',
      );
    }
    return null;
  }
}
