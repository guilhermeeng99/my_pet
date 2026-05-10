import 'package:dartz/dartz.dart';
import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/notifications/domain/notification_service.dart';
import 'package:my_pet/features/reminders/data/datasources/reminder_firestore_datasource.dart';
import 'package:my_pet/features/reminders/data/models/reminder_model.dart';
import 'package:my_pet/features/reminders/domain/entities/recurrence.dart';
import 'package:my_pet/features/reminders/domain/entities/reminder.dart';
import 'package:my_pet/features/reminders/domain/repositories/reminder_repository.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  ReminderRepositoryImpl({
    required ReminderFirestoreDatasource datasource,
    required NotificationService notifications,
  })  : _datasource = datasource,
        _notifications = notifications;

  final ReminderFirestoreDatasource _datasource;
  final NotificationService _notifications;

  @override
  Stream<List<Reminder>> watchActive(String householdId) =>
      _datasource.watchActive(householdId);

  @override
  Stream<List<Reminder>> watchByPet(String householdId, String petId) =>
      _datasource.watchByPet(householdId, petId);

  @override
  Future<Either<Failure, Reminder>> create(Reminder reminder) async {
    final invalid = _validate(reminder);
    if (invalid != null) return Left(invalid);
    try {
      final created =
          await _datasource.create(ReminderModel.fromEntity(reminder));
      await _schedule(created);
      return Right(created);
    } on Exception catch (e, st) {
      return Left(ServerFailure(message: e.toString(), cause: st));
    }
  }

  @override
  Future<Either<Failure, Reminder>> update(Reminder reminder) async {
    final invalid = _validate(reminder);
    if (invalid != null) return Left(invalid);
    try {
      final updated =
          await _datasource.update(ReminderModel.fromEntity(reminder));
      await _schedule(updated);
      return Right(updated);
    } on Exception catch (e, st) {
      return Left(ServerFailure(message: e.toString(), cause: st));
    }
  }

  /// Marks [reminder] done and, when recurring, persists the next
  /// instance shifted forward (spec rule 1). The cubit always has the
  /// in-memory entity available from the watch stream, so we take it as
  /// input rather than re-reading by id.
  @override
  Future<Either<Failure, Reminder>> markDone(Reminder reminder) async {
    try {
      final now = DateTime.now().toUtc();
      final completed = reminder.copyWith(done: true, doneAt: now);
      await _datasource.update(ReminderModel.fromEntity(completed));
      await _notifications.cancelGroup(_groupKey(reminder.id));

      if (!reminder.recurrence.isRecurring) {
        return Right(completed);
      }

      final nextDue = reminder.recurrence.nextAfter(
        reminder.dueAt,
        customIntervalDays: reminder.recurrenceIntervalDays,
      );
      if (nextDue == null) return Right(completed);

      // Datasource.create() will assign a fresh doc id.
      final rolled = reminder.copyWith(
        id: '',
        dueAt: nextDue,
        done: false,
        clearDoneAt: true,
        createdAt: now,
      );
      final created =
          await _datasource.create(ReminderModel.fromEntity(rolled));
      await _schedule(created);
      return Right(created);
    } on Exception catch (e, st) {
      return Left(ServerFailure(message: e.toString(), cause: st));
    }
  }

  @override
  Future<Either<Failure, Unit>> delete(
    String householdId,
    String reminderId,
  ) async {
    try {
      await _datasource.delete(householdId, reminderId);
      await _notifications.cancelGroup(_groupKey(reminderId));
      return const Right(unit);
    } on Exception catch (e, st) {
      return Left(ServerFailure(message: e.toString(), cause: st));
    }
  }

  Future<void> _schedule(Reminder reminder) async {
    final groupKey = _groupKey(reminder.id);
    try {
      final firings = reminder.notifyBeforeMinutes
          .map((m) => reminder.dueAt.subtract(Duration(minutes: m)))
          .toList(growable: false);
      await _notifications.scheduleAll(
        groupKey: groupKey,
        title: reminder.title,
        body: reminder.description ?? '',
        firings: firings,
      );
    } on Exception {
      // Notifications are non-critical; swallow so the write stays the
      // source of truth even if scheduling fails (matches Vaccinations).
    }
  }

  String _groupKey(String reminderId) => 'rem:$reminderId';

  /// Spec invariants: non-empty title (1..80), notifyBeforeMinutes ≥ 0,
  /// recurrence == custom ⇒ recurrenceIntervalDays > 0.
  ValidationFailure? _validate(Reminder r) {
    final trimmed = r.title.trim();
    if (trimmed.isEmpty) {
      return const ValidationFailure(message: 'Reminder title is required.');
    }
    if (trimmed.length > 80) {
      return const ValidationFailure(
        message: 'Reminder title must be 80 characters or fewer.',
      );
    }
    if (r.notifyBeforeMinutes.any((m) => m < 0)) {
      return const ValidationFailure(
        message: 'Lead-time minutes cannot be negative.',
      );
    }
    if (r.recurrence == Recurrence.custom &&
        (r.recurrenceIntervalDays == null ||
            r.recurrenceIntervalDays! <= 0)) {
      return const ValidationFailure(
        message: 'Custom recurrence requires a positive interval (days).',
      );
    }
    return null;
  }
}
