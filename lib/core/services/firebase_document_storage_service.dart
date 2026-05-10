import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/core/services/document_storage_service.dart';

class FirebaseDocumentStorageService implements DocumentStorageService {
  FirebaseDocumentStorageService({required FirebaseStorage storage})
      : _storage = storage;

  final FirebaseStorage _storage;

  static const int _maxBytes = 20 * 1024 * 1024;
  static const Set<String> _acceptedMimeTypes = {
    'application/pdf',
    'image/jpeg',
    'image/png',
    'image/heic',
    'image/heif',
  };

  @override
  Future<Either<Failure, DocumentUploadResult>> upload({
    required String householdId,
    required String documentId,
    required File source,
    required String mimeType,
  }) async {
    if (!_acceptedMimeTypes.contains(mimeType)) {
      return Left(
        ValidationFailure(message: 'Unsupported file type: $mimeType.'),
      );
    }
    try {
      final bytes = await source.readAsBytes();
      if (bytes.lengthInBytes > _maxBytes) {
        return Left(
          PhotoTooLargeFailure(
            sizeBytes: bytes.lengthInBytes,
            maxBytes: _maxBytes,
          ),
        );
      }
      final ref =
          _storage.ref('households/$householdId/documents/$documentId');
      await ref.putData(
        bytes,
        SettableMetadata(contentType: mimeType),
      );
      final url = await ref.getDownloadURL();
      return Right(
        DocumentUploadResult(fileUrl: url, sizeBytes: bytes.lengthInBytes),
      );
    } on Object catch (e) {
      return Left(ServerFailure(message: e.toString(), cause: e));
    }
  }

  @override
  Future<Either<Failure, Unit>> delete({
    required String householdId,
    required String documentId,
  }) async {
    try {
      await _storage
          .ref('households/$householdId/documents/$documentId')
          .delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') {
        return Left(ServerFailure(message: e.message ?? e.code, cause: e));
      }
    } on Object catch (e) {
      return Left(ServerFailure(message: e.toString(), cause: e));
    }
    return const Right(unit);
  }
}
