import 'package:dartz/dartz.dart';
import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/health/data/datasources/health_firestore_datasource.dart';
import 'package:my_pet/features/health/data/models/health_event_model.dart';
import 'package:my_pet/features/health/domain/entities/health_event.dart';
import 'package:my_pet/features/health/domain/entities/health_event_type.dart';
import 'package:my_pet/features/health/domain/repositories/health_repository.dart';

class HealthRepositoryImpl implements HealthRepository {
  HealthRepositoryImpl({required HealthFirestoreDatasource datasource})
      : _datasource = datasource;

  final HealthFirestoreDatasource _datasource;

  @override
  Stream<List<HealthEvent>> watchByPet(String householdId, String petId) =>
      _datasource.watchByPet(householdId, petId);

  @override
  Stream<List<HealthEvent>> watchByPetAndType(
    String householdId,
    String petId,
    HealthEventType type,
  ) =>
      _datasource.watchByPetAndType(householdId, petId, type);

  @override
  Future<Either<Failure, HealthEvent>> create(HealthEvent event) async {
    final invalid = _validate(event);
    if (invalid != null) return Left(invalid);
    try {
      final created =
          await _datasource.create(HealthEventModel.fromEntity(event));
      return Right(created);
    } on Exception catch (e, st) {
      return Left(ServerFailure(message: e.toString(), cause: st));
    }
  }

  @override
  Future<Either<Failure, HealthEvent>> update(HealthEvent event) async {
    final invalid = _validate(event);
    if (invalid != null) return Left(invalid);
    try {
      final updated =
          await _datasource.update(HealthEventModel.fromEntity(event));
      return Right(updated);
    } on Exception catch (e, st) {
      return Left(ServerFailure(message: e.toString(), cause: st));
    }
  }

  @override
  Future<Either<Failure, Unit>> delete(
    String householdId,
    String petId,
    String eventId,
  ) async {
    try {
      await _datasource.delete(householdId, petId, eventId);
      return const Right(unit);
    } on Exception catch (e, st) {
      return Left(ServerFailure(message: e.toString(), cause: st));
    }
  }

  ValidationFailure? _validate(HealthEvent e) {
    if (e.title.trim().isEmpty) {
      return const ValidationFailure(message: 'Title is required.');
    }
    if (e.date.isAfter(DateTime.now().toUtc())) {
      return const ValidationFailure(
        message: 'Date cannot be in the future.',
      );
    }
    final end = e.endDate;
    if (end != null && end.isBefore(e.date)) {
      return const ValidationFailure(
        message: 'End date must be on or after the start date.',
      );
    }
    if (e.type == HealthEventType.medication && e.medication == null) {
      return const ValidationFailure(
        message: 'Medication details are required for medication events.',
      );
    }
    final cost = e.cost;
    if (cost != null && cost < 0) {
      return const ValidationFailure(message: 'Cost cannot be negative.');
    }
    return null;
  }
}
