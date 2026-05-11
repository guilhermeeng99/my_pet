import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/core/errors/firebase_failure_mapper.dart';
import 'package:my_pet/core/services/document_storage_service.dart';
import 'package:my_pet/features/documents/data/datasources/document_firestore_datasource.dart';
import 'package:my_pet/features/documents/data/models/pet_document_model.dart';
import 'package:my_pet/features/documents/domain/entities/document_category.dart';
import 'package:my_pet/features/documents/domain/entities/pet_document.dart';
import 'package:my_pet/features/documents/domain/repositories/document_repository.dart';
import 'package:uuid/uuid.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  DocumentRepositoryImpl({
    required DocumentFirestoreDatasource datasource,
    required DocumentStorageService storage,
    Uuid uuid = const Uuid(),
  })  : _datasource = datasource,
        _storage = storage,
        _uuid = uuid;

  final DocumentFirestoreDatasource _datasource;
  final DocumentStorageService _storage;
  final Uuid _uuid;

  @override
  Stream<List<PetDocument>> watchByHousehold(String householdId) =>
      _datasource.watchByHousehold(householdId);

  @override
  Stream<List<PetDocument>> watchByPet(String householdId, String petId) =>
      _datasource.watchByPet(householdId, petId);

  @override
  Future<Either<Failure, PetDocument>> upload({
    required String householdId,
    required String? petId,
    required String createdBy,
    required String title,
    required DocumentCategory category,
    required String mimeType,
    required File source,
    String? notes,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty || trimmed.length > 120) {
      return const Left(
        ValidationFailure(
          message: 'Title is required (1..120 characters).',
        ),
      );
    }
    final documentId = _uuid.v4();
    final upload = await _storage.upload(
      householdId: householdId,
      documentId: documentId,
      source: source,
      mimeType: mimeType,
    );
    return upload.fold<Future<Either<Failure, PetDocument>>>(
      (failure) async => Left(failure),
      (result) async {
        try {
          final now = DateTime.now().toUtc();
          final draft = PetDocumentModel.fromEntity(
            PetDocument(
              id: documentId,
              householdId: householdId,
              petId: petId,
              title: trimmed,
              category: category,
              fileUrl: result.fileUrl,
              mimeType: mimeType,
              sizeBytes: result.sizeBytes,
              notes: notes,
              createdAt: now,
              createdBy: createdBy,
            ),
          );
          final saved = await _datasource.create(draft);
          return Right(saved);
        } on Exception catch (e, st) {
          // Best-effort cleanup: drop the Storage object so we don't
          // leak orphans when the Firestore write fails.
          await _storage.delete(
            householdId: householdId,
            documentId: documentId,
          );
          return Left(ServerFailure(message: e.toString(), cause: st));
        }
      },
    );
  }

  @override
  Future<Either<Failure, PetDocument>> updateMetadata({
    required PetDocument document,
  }) async {
    try {
      final saved = await _datasource.update(
        PetDocumentModel.fromEntity(document),
      );
      return Right(saved);
    } on Exception catch (e, st) {
      return Left(mapFirebaseException(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> delete(
    String householdId,
    String documentId,
  ) async {
    try {
      await _datasource.delete(householdId, documentId);
      await _storage.delete(householdId: householdId, documentId: documentId);
      return const Right(unit);
    } on Exception catch (e, st) {
      return Left(mapFirebaseException(e, st));
    }
  }
}
