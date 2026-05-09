import 'package:dartz/dartz.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/vaccinations/data/datasources/vaccination_firestore_datasource.dart';
import 'package:my_pet/features/vaccinations/data/models/vaccination_model.dart';
import 'package:my_pet/features/vaccinations/domain/entities/vaccination.dart';
import 'package:my_pet/features/vaccinations/domain/repositories/vaccination_repository.dart';

class VaccinationRepositoryImpl implements VaccinationRepository {
  VaccinationRepositoryImpl({required VaccinationFirestoreDatasource datasource})
      : _datasource = datasource;

  final VaccinationFirestoreDatasource _datasource;

  @override
  Stream<List<Vaccination>> watchByPet(String householdId, String petId) =>
      _datasource.watchByPet(householdId, petId);

  @override
  Future<Either<Failure, Vaccination>> create(Vaccination vaccination) async {
    final invalid = _validate(vaccination);
    if (invalid != null) return Left(invalid);
    try {
      final created =
          await _datasource.create(VaccinationModel.fromEntity(vaccination));
      return Right(created);
    } on Exception catch (e, st) {
      return Left(ServerFailure(message: e.toString(), cause: st));
    }
  }

  @override
  Future<Either<Failure, Vaccination>> update(Vaccination vaccination) async {
    final invalid = _validate(vaccination);
    if (invalid != null) return Left(invalid);
    try {
      final updated =
          await _datasource.update(VaccinationModel.fromEntity(vaccination));
      return Right(updated);
    } on Exception catch (e, st) {
      return Left(ServerFailure(message: e.toString(), cause: st));
    }
  }

  @override
  Future<Either<Failure, Unit>> delete(
    String householdId,
    String petId,
    String vaccinationId,
  ) async {
    try {
      await _datasource.delete(householdId, petId, vaccinationId);
      return const Right(unit);
    } on Exception catch (e, st) {
      return Left(ServerFailure(message: e.toString(), cause: st));
    }
  }

  /// vaccinations.md invariants: name not empty, appliedDate <= now,
  /// nextDueDate (if present) > appliedDate.
  ValidationFailure? _validate(Vaccination v) {
    if (v.name.trim().isEmpty) {
      return const ValidationFailure(message: 'Vaccine name is required.');
    }
    final now = DateTime.now().toUtc();
    if (v.appliedDate.isAfter(now)) {
      return const ValidationFailure(
        message: 'Applied date cannot be in the future.',
      );
    }
    final next = v.nextDueDate;
    if (next != null && !next.isAfter(v.appliedDate)) {
      return const ValidationFailure(
        message: 'Next due date must be after applied date.',
      );
    }
    return null;
  }
}
