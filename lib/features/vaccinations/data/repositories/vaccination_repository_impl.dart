import 'dart:developer' as developer;

import 'package:dartz/dartz.dart';

import 'package:my_pet/core/constants/app_constants.dart';
import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/core/errors/firebase_failure_mapper.dart';
import 'package:my_pet/features/notifications/domain/notification_service.dart';
import 'package:my_pet/features/vaccinations/data/datasources/vaccination_firestore_datasource.dart';
import 'package:my_pet/features/vaccinations/data/models/vaccination_model.dart';
import 'package:my_pet/features/vaccinations/domain/entities/vaccination.dart';
import 'package:my_pet/features/vaccinations/domain/repositories/vaccination_repository.dart';

class VaccinationRepositoryImpl implements VaccinationRepository {
  VaccinationRepositoryImpl({
    required VaccinationFirestoreDatasource datasource,
    required NotificationService notifications,
  })  : _datasource = datasource,
        _notifications = notifications;

  final VaccinationFirestoreDatasource _datasource;
  final NotificationService _notifications;

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
      await _scheduleReminders(created);
      return Right(created);
    } on Exception catch (e, st) {
      return Left(mapFirebaseException(e, st));
    }
  }

  @override
  Future<Either<Failure, Vaccination>> update(Vaccination vaccination) async {
    final invalid = _validate(vaccination);
    if (invalid != null) return Left(invalid);
    try {
      final updated =
          await _datasource.update(VaccinationModel.fromEntity(vaccination));
      await _scheduleReminders(updated);
      return Right(updated);
    } on Exception catch (e, st) {
      return Left(mapFirebaseException(e, st));
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
      await _notifications.cancelGroup(_groupKey(vaccinationId));
      return const Right(unit);
    } on Exception catch (e, st) {
      return Left(mapFirebaseException(e, st));
    }
  }

  /// Spec rule 1: schedule a reminder 7 days before and on the day of
  /// `nextDueDate`. Best-effort — failure to schedule never breaks the
  /// write.
  Future<void> _scheduleReminders(Vaccination v) async {
    final due = v.nextDueDate;
    final groupKey = _groupKey(v.id);
    if (due == null) {
      await _notifications.cancelGroup(groupKey);
      return;
    }
    try {
      await _notifications.scheduleAll(
        groupKey: groupKey,
        title: '${v.name} reminder',
        body: 'Next dose due',
        firings: [
          due.subtract(
            const Duration(days: AppConstants.vaccinationReminderLeadDays),
          ),
          due,
        ],
      );
    } on Exception catch (e, st) {
      // Notifications are non-critical; we never fail the Firestore write
      // when scheduling breaks, but we DO log so the silent breakage is
      // diagnosable in production logs/Crashlytics.
      developer.log(
        'Failed to schedule vaccination reminders for ${v.id}',
        name: 'notifications',
        error: e,
        stackTrace: st,
      );
    }
  }

  String _groupKey(String vaccinationId) => 'vax:$vaccinationId';

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
