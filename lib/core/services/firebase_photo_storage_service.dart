import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/core/services/photo_storage_service.dart';

/// Firebase Storage implementation of [PhotoStorageService]. Resizes and
/// re-encodes uploads so we stay under the per-path size caps declared in
/// `storage.rules` (2 MB profile, 5 MB gallery original).
class FirebasePhotoStorageService implements PhotoStorageService {
  FirebasePhotoStorageService({required FirebaseStorage storage})
      : _storage = storage;

  final FirebaseStorage _storage;

  static const int _profileMaxBytes = 2 * 1024 * 1024;
  static const int _galleryMaxBytes = 5 * 1024 * 1024;
  static const int _profileTargetWidth = 1024;
  static const int _profileJpegQuality = 85;
  static const int _galleryTargetWidth = 2048;
  static const int _galleryJpegQuality = 88;
  static const int _thumbSize = 256;
  static const int _thumbJpegQuality = 80;

  @override
  Future<Either<Failure, String>> uploadPetProfile({
    required String householdId,
    required String petId,
    required File source,
  }) async {
    try {
      final raw = await source.readAsBytes();
      final encoded = _resizeJpeg(
        raw,
        width: _profileTargetWidth,
        quality: _profileJpegQuality,
      );
      if (encoded.lengthInBytes > _profileMaxBytes) {
        return Left(
          PhotoTooLargeFailure(
            sizeBytes: encoded.lengthInBytes,
            maxBytes: _profileMaxBytes,
          ),
        );
      }
      final ref =
          _storage.ref('households/$householdId/pets/$petId/profile.jpg');
      await ref.putData(
        encoded,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await ref.getDownloadURL();
      return Right(url);
    } on Object catch (e) {
      return Left(ServerFailure(message: e.toString(), cause: e));
    }
  }

  @override
  Future<Either<Failure, GalleryPhotoUploadResult>> uploadGalleryPhoto({
    required String householdId,
    required String petId,
    required String photoId,
    required File source,
  }) async {
    try {
      final raw = await source.readAsBytes();
      final decoded = img.decodeImage(raw);
      if (decoded == null) {
        return const Left(
          ServerFailure(message: 'Could not decode the selected image.'),
        );
      }
      final original = _encodeJpeg(
        decoded.width <= _galleryTargetWidth
            ? decoded
            : img.copyResize(decoded, width: _galleryTargetWidth),
        _galleryJpegQuality,
      );
      if (original.lengthInBytes > _galleryMaxBytes) {
        return Left(
          PhotoTooLargeFailure(
            sizeBytes: original.lengthInBytes,
            maxBytes: _galleryMaxBytes,
          ),
        );
      }
      final thumb = _encodeJpeg(
        img.copyResizeCropSquare(decoded, size: _thumbSize),
        _thumbJpegQuality,
      );

      final basePath =
          'households/$householdId/pets/$petId/gallery/$photoId';
      final originalRef = _storage.ref('$basePath/original.jpg');
      final thumbRef = _storage.ref('$basePath/thumb.jpg');
      await originalRef.putData(
        original,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      await thumbRef.putData(
        thumb,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final urls = await Future.wait<String>([
        originalRef.getDownloadURL(),
        thumbRef.getDownloadURL(),
      ]);
      return Right(
        GalleryPhotoUploadResult(
          originalUrl: urls[0],
          thumbnailUrl: urls[1],
        ),
      );
    } on Object catch (e) {
      return Left(ServerFailure(message: e.toString(), cause: e));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteGalleryPhoto({
    required String householdId,
    required String petId,
    required String photoId,
  }) async {
    final basePath = 'households/$householdId/pets/$petId/gallery/$photoId';
    for (final name in const ['original.jpg', 'thumb.jpg']) {
      try {
        await _storage.ref('$basePath/$name').delete();
      } on FirebaseException catch (e) {
        // Already-missing objects are fine; surface only auth/IO errors.
        if (e.code != 'object-not-found') {
          return Left(ServerFailure(message: e.message ?? e.code, cause: e));
        }
      } on Object catch (e) {
        return Left(ServerFailure(message: e.toString(), cause: e));
      }
    }
    return const Right(unit);
  }

  Uint8List _resizeJpeg(
    Uint8List bytes, {
    required int width,
    required int quality,
  }) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;
    final resized = decoded.width <= width
        ? decoded
        : img.copyResize(decoded, width: width);
    return _encodeJpeg(resized, quality);
  }

  Uint8List _encodeJpeg(img.Image image, int quality) {
    return Uint8List.fromList(img.encodeJpg(image, quality: quality));
  }
}
