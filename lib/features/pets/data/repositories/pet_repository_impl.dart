import 'package:dartz/dartz.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/core/errors/firebase_failure_mapper.dart';
import 'package:my_pet/features/pets/data/datasources/pet_firestore_datasource.dart';
import 'package:my_pet/features/pets/data/models/pet_model.dart';
import 'package:my_pet/features/pets/domain/entities/pet.dart';
import 'package:my_pet/features/pets/domain/repositories/pet_repository.dart';

class PetRepositoryImpl implements PetRepository {
  PetRepositoryImpl({required PetFirestoreDatasource datasource})
      : _datasource = datasource;

  final PetFirestoreDatasource _datasource;

  @override
  Stream<List<Pet>> watchActive(String householdId) =>
      _datasource.watchActive(householdId);

  @override
  Stream<List<Pet>> watchArchived(String householdId) =>
      _datasource.watchArchived(householdId);

  @override
  Stream<Pet?> watchPet(String householdId, String petId) =>
      _datasource.watchPet(householdId, petId);

  @override
  Future<Either<Failure, Pet>> create(Pet pet) async {
    final validation = _validate(pet);
    if (validation != null) return Left(validation);
    try {
      final created = await _datasource.create(PetModel.fromEntity(pet));
      return Right(created);
    } on Exception catch (e, st) {
      return Left(mapFirebaseException(e, st));
    }
  }

  @override
  Future<Either<Failure, Pet>> update(Pet pet) async {
    final validation = _validate(pet);
    if (validation != null) return Left(validation);
    try {
      final updated = await _datasource.update(PetModel.fromEntity(pet));
      return Right(updated);
    } on Exception catch (e, st) {
      return Left(mapFirebaseException(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> archive(String householdId, String petId) async {
    try {
      await _datasource.archive(householdId, petId);
      return const Right(unit);
    } on Exception catch (e, st) {
      return Left(mapFirebaseException(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> unarchive(String householdId, String petId) async {
    try {
      await _datasource.unarchive(householdId, petId);
      return const Right(unit);
    } on Exception catch (e, st) {
      return Left(mapFirebaseException(e, st));
    }
  }

  /// Spec invariants — pet must have a non-empty name and a non-future
  /// birth/adoption date.
  ValidationFailure? _validate(Pet pet) {
    if (pet.name.trim().isEmpty) {
      return const ValidationFailure(message: 'Pet name is required.');
    }
    final now = DateTime.now().toUtc();
    if (pet.birthDate != null && pet.birthDate!.isAfter(now)) {
      return const ValidationFailure(message: 'Birth date cannot be in the future.');
    }
    if (pet.adoptionDate != null && pet.adoptionDate!.isAfter(now)) {
      return const ValidationFailure(message: 'Adoption date cannot be in the future.');
    }
    return null;
  }
}
