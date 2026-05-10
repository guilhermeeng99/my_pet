import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:my_pet/core/errors/failures.dart';

/// Boundary around document uploads. Wraps Firebase Storage so feature
/// code doesn't depend on the SDK directly.
abstract class DocumentStorageService {
  /// Uploads [source] to `households/{householdId}/documents/{documentId}`
  /// with the provided MIME type. Returns the public download URL on
  /// success. Implementations enforce the 20 MB cap and the accepted
  /// MIME types (PDF, JPEG, PNG, HEIC) before hitting Storage.
  Future<Either<Failure, DocumentUploadResult>> upload({
    required String householdId,
    required String documentId,
    required File source,
    required String mimeType,
  });

  /// Best-effort delete. A missing object is not surfaced as an error.
  Future<Either<Failure, Unit>> delete({
    required String householdId,
    required String documentId,
  });
}

class DocumentUploadResult {
  const DocumentUploadResult({required this.fileUrl, required this.sizeBytes});

  final String fileUrl;
  final int sizeBytes;
}
