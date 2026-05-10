import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:my_pet/core/errors/failures.dart';

/// Boundary for uploading user-supplied images to remote storage. Wraps
/// Firebase Storage so feature code never depends on the SDK directly.
///
/// Two distinct upload flows live behind this interface:
///
/// - profile photos: single small JPEG at
///   `households/{hid}/pets/{petId}/profile.jpg` (2 MB cap),
/// - gallery photos: a higher-resolution original + a 256² thumbnail
///   under `households/{hid}/pets/{petId}/gallery/{photoId}` (5 MB cap
///   per file per `storage.rules`).
abstract class PhotoStorageService {
  /// Uploads a pet profile photo to
  /// `households/{householdId}/pets/{petId}/profile.jpg` and returns the
  /// public download URL on success.
  ///
  /// Implementations should resize / re-encode the [source] before upload
  /// to stay under the 2 MB cap declared in `storage.rules`.
  Future<Either<Failure, String>> uploadPetProfile({
    required String householdId,
    required String petId,
    required File source,
  });

  /// Uploads a gallery photo for the pet under
  /// `households/{householdId}/pets/{petId}/gallery/{photoId}/original.jpg`
  /// and a 256² thumbnail at `.../thumb.jpg`. Returns both URLs so the
  /// caller can persist them on the Firestore doc.
  Future<Either<Failure, GalleryPhotoUploadResult>> uploadGalleryPhoto({
    required String householdId,
    required String petId,
    required String photoId,
    required File source,
  });

  /// Removes both the original and thumbnail blobs from the gallery
  /// folder. Best-effort: a missing object is not surfaced as an error.
  Future<Either<Failure, Unit>> deleteGalleryPhoto({
    required String householdId,
    required String petId,
    required String photoId,
  });
}

/// Tuple-style return for a successful gallery upload.
class GalleryPhotoUploadResult {
  const GalleryPhotoUploadResult({
    required this.originalUrl,
    required this.thumbnailUrl,
  });

  final String originalUrl;
  final String thumbnailUrl;
}
