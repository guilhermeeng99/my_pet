import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/core/errors/firebase_failure_mapper.dart';
import 'package:my_pet/core/services/photo_storage_service.dart';
import 'package:my_pet/features/gallery/data/datasources/gallery_firestore_datasource.dart';
import 'package:my_pet/features/gallery/data/models/pet_photo_model.dart';
import 'package:my_pet/features/gallery/domain/entities/pet_photo.dart';
import 'package:my_pet/features/gallery/domain/repositories/gallery_repository.dart';
import 'package:my_pet/features/pets/data/datasources/pet_firestore_datasource.dart';
import 'package:uuid/uuid.dart';

class GalleryRepositoryImpl implements GalleryRepository {
  GalleryRepositoryImpl({
    required GalleryFirestoreDatasource datasource,
    required PhotoStorageService storage,
    required PetFirestoreDatasource pets,
    Uuid uuid = const Uuid(),
  })  : _datasource = datasource,
        _storage = storage,
        _pets = pets,
        _uuid = uuid;

  final GalleryFirestoreDatasource _datasource;
  final PhotoStorageService _storage;
  final PetFirestoreDatasource _pets;
  final Uuid _uuid;

  /// Spec rule 4: 500 photos per pet, warn at 450. The hard cap is
  /// enforced here; the warning is the UI's responsibility.
  static const int _photoCap = 500;

  @override
  Stream<List<PetPhoto>> watchByPet(String householdId, String petId) =>
      _datasource.watchByPet(householdId, petId);

  @override
  Future<Either<Failure, PetPhoto>> upload({
    required String householdId,
    required String petId,
    required String createdBy,
    required File source,
    String? caption,
  }) async {
    try {
      final count = await _datasource.countForPet(householdId, petId);
      if (count >= _photoCap) {
        return const Left(
          ValidationFailure(
            message: 'Gallery is full (500 photos per pet).',
          ),
        );
      }

      final photoId = _uuid.v4();
      final upload = await _storage.uploadGalleryPhoto(
        householdId: householdId,
        petId: petId,
        photoId: photoId,
        source: source,
      );
      return upload.fold<Future<Either<Failure, PetPhoto>>>(
        (failure) async => Left(failure),
        (urls) async {
          final now = DateTime.now().toUtc();
          final draft = PetPhotoModel.fromEntity(
            PetPhoto(
              id: photoId,
              householdId: householdId,
              petId: petId,
              url: urls.originalUrl,
              thumbnailUrl: urls.thumbnailUrl,
              caption: caption,
              takenAt: now,
              createdAt: now,
              createdBy: createdBy,
            ),
          );
          final saved = await _datasource.create(draft);
          return Right(saved);
        },
      );
    } on Exception catch (e, st) {
      return Left(mapFirebaseException(e, st));
    }
  }

  @override
  Future<Either<Failure, PetPhoto>> updateCaption(
    String householdId,
    String petId,
    String photoId,
    String? caption,
  ) async {
    try {
      // We don't keep a cubit-side copy here; reconstruct enough state to
      // patch the doc. Other fields stay untouched because Firestore
      // updates only the keys we pass back in `toFirestoreUpdate`.
      final patch = PetPhotoModel.fromEntity(
        PetPhoto(
          id: photoId,
          householdId: householdId,
          petId: petId,
          url: '',
          thumbnailUrl: '',
          caption: (caption ?? '').trim().isEmpty
              ? null
              : caption!.trim(),
          createdAt: DateTime.now().toUtc(),
          createdBy: '',
        ),
      );
      await _datasource.update(patch);
      return Right(patch);
    } on Exception catch (e, st) {
      return Left(mapFirebaseException(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> delete({
    required String householdId,
    required String petId,
    required String photoId,
  }) async {
    try {
      await _datasource.delete(householdId, petId, photoId);
      // Storage delete is best-effort — already-missing blobs return ok.
      await _storage.deleteGalleryPhoto(
        householdId: householdId,
        petId: petId,
        photoId: photoId,
      );
      return const Right(unit);
    } on Exception catch (e, st) {
      return Left(mapFirebaseException(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> setAsProfile({
    required String householdId,
    required String petId,
    required String photoId,
    required String url,
  }) async {
    try {
      await _pets.setProfilePhotoUrl(householdId, petId, url);
      return const Right(unit);
    } on Exception catch (e, st) {
      return Left(mapFirebaseException(e, st));
    }
  }
}
