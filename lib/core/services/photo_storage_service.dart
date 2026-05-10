import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:my_pet/core/errors/failures.dart';

/// Boundary for uploading user-supplied images to remote storage. Wraps
/// Firebase Storage so feature code never depends on the SDK directly.
///
/// Currently single-method (`uploadPetProfile`); held as an interface so the
/// gallery / health-attachment uploaders can land alongside it without
/// breaking call sites.
// ignore: one_member_abstracts
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
}
