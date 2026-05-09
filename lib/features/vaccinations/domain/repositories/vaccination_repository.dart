import 'package:dartz/dartz.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/vaccinations/domain/entities/vaccination.dart';

abstract class VaccinationRepository {
  Stream<List<Vaccination>> watchByPet(String householdId, String petId);
  Future<Either<Failure, Vaccination>> create(Vaccination vaccination);
  Future<Either<Failure, Vaccination>> update(Vaccination vaccination);
  Future<Either<Failure, Unit>> delete(
    String householdId,
    String petId,
    String vaccinationId,
  );
}
