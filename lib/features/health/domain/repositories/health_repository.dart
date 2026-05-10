import 'package:dartz/dartz.dart';
import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/health/domain/entities/health_event.dart';
import 'package:my_pet/features/health/domain/entities/health_event_type.dart';

abstract class HealthRepository {
  /// All health events for a pet, ordered by `date` descending.
  Stream<List<HealthEvent>> watchByPet(String householdId, String petId);

  /// Filtered stream when the user picks a single type from the timeline.
  Stream<List<HealthEvent>> watchByPetAndType(
    String householdId,
    String petId,
    HealthEventType type,
  );

  Future<Either<Failure, HealthEvent>> create(HealthEvent event);
  Future<Either<Failure, HealthEvent>> update(HealthEvent event);
  Future<Either<Failure, Unit>> delete(
    String householdId,
    String petId,
    String eventId,
  );
}
