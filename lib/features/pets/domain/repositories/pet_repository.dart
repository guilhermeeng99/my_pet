import 'package:dartz/dartz.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/pets/domain/entities/pet.dart';

/// Phase-1 contract — covers create/update/watch and archive flow. Hard
/// delete (owner-only) lands once household roles ship in Phase 3.
/// Photo upload is wired separately (PhotoStorageService).
abstract class PetRepository {
  Stream<List<Pet>> watchActive(String householdId);
  Stream<List<Pet>> watchArchived(String householdId);
  Stream<Pet?> watchPet(String householdId, String petId);
  Future<Either<Failure, Pet>> create(Pet pet);
  Future<Either<Failure, Pet>> update(Pet pet);
  Future<Either<Failure, Unit>> archive(String householdId, String petId);
  Future<Either<Failure, Unit>> unarchive(String householdId, String petId);
}
