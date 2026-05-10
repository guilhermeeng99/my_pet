import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/gallery/domain/entities/pet_photo.dart';

abstract class GalleryRepository {
  /// All photos for the pet, ordered by `takenAt` (falling back to
  /// `createdAt`) descending.
  Stream<List<PetPhoto>> watchByPet(String householdId, String petId);

  /// Uploads [source] to Storage, persists the metadata doc, and returns
  /// the inserted [PetPhoto]. Caller passes the local file path from
  /// `image_picker`.
  Future<Either<Failure, PetPhoto>> upload({
    required String householdId,
    required String petId,
    required String createdBy,
    required File source,
    String? caption,
  });

  Future<Either<Failure, PetPhoto>> updateCaption(
    String householdId,
    String petId,
    String photoId,
    String? caption,
  );

  /// Removes the Storage objects and the Firestore doc. Best-effort: a
  /// missing Storage object does not surface as an error.
  Future<Either<Failure, Unit>> delete({
    required String householdId,
    required String petId,
    required String photoId,
  });

  /// Sets the photo as the pet's profile photo by overwriting the
  /// `pets/{petId}.photoUrl` field. The gallery doc stays in place.
  Future<Either<Failure, Unit>> setAsProfile({
    required String householdId,
    required String petId,
    required String photoId,
    required String url,
  });
}
