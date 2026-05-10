import 'package:dartz/dartz.dart';
import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/reminders/domain/entities/reminder.dart';

/// Reminder repository contract. The household-wide listener powers the
/// Reminders tab; the per-pet listener powers the upcoming-care strip on
/// the pet detail page. `markDone` and `delete` are separate calls — done
/// for recurring reminders rolls the instance forward, delete drops it.
abstract class ReminderRepository {
  /// Active reminders (done == false) for the household, ordered by dueAt.
  Stream<List<Reminder>> watchActive(String householdId);

  /// Active reminders for a single pet, ordered by dueAt. Used on the pet
  /// detail page; includes pet-scoped reminders only (`petId == petId`).
  Stream<List<Reminder>> watchByPet(String householdId, String petId);

  Future<Either<Failure, Reminder>> create(Reminder reminder);
  Future<Either<Failure, Reminder>> update(Reminder reminder);

  /// Marks the reminder done. For recurring reminders, persists the
  /// completion and rolls a fresh instance forward to the next due date.
  /// Takes the in-memory entity so we avoid a redundant get-by-id — cubits
  /// already hold the latest snapshot from the watch stream.
  Future<Either<Failure, Reminder>> markDone(Reminder reminder);

  Future<Either<Failure, Unit>> delete(
    String householdId,
    String reminderId,
  );
}
