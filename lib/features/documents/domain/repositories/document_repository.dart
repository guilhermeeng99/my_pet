import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/documents/domain/entities/document_category.dart';
import 'package:my_pet/features/documents/domain/entities/pet_document.dart';

abstract class DocumentRepository {
  /// All household documents, newest first. Surfaces both pet-scoped
  /// and household-level docs; UI filters on `petId`.
  Stream<List<PetDocument>> watchByHousehold(String householdId);

  /// Convenience stream filtered to a single pet (in-memory; cheap for
  /// the document volumes we expect).
  Stream<List<PetDocument>> watchByPet(String householdId, String petId);

  Future<Either<Failure, PetDocument>> upload({
    required String householdId,
    required String? petId,
    required String createdBy,
    required String title,
    required DocumentCategory category,
    required String mimeType,
    required File source,
    String? notes,
  });

  Future<Either<Failure, PetDocument>> updateMetadata({
    required PetDocument document,
  });

  Future<Either<Failure, Unit>> delete(String householdId, String documentId);
}
