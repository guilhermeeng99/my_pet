import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/core/services/photo_storage_service.dart';

/// Firebase Storage implementation of [PhotoStorageService]. Resizes and
/// re-encodes large camera/gallery photos to JPEG ≤ 1024 px wide so we stay
/// well under the 2 MB Storage rule documented in `storage.rules`.
class FirebasePhotoStorageService implements PhotoStorageService {
  FirebasePhotoStorageService({required FirebaseStorage storage})
      : _storage = storage;

  final FirebaseStorage _storage;

  static const int _maxBytes = 2 * 1024 * 1024;
  static const int _targetWidth = 1024;
  static const int _jpegQuality = 85;

  @override
  Future<Either<Failure, String>> uploadPetProfile({
    required String householdId,
    required String petId,
    required File source,
  }) async {
    try {
      final raw = await source.readAsBytes();
      final encoded = _resizeJpeg(raw);
      if (encoded.lengthInBytes > _maxBytes) {
        return Left(
          PhotoTooLargeFailure(
            sizeBytes: encoded.lengthInBytes,
            maxBytes: _maxBytes,
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

  Uint8List _resizeJpeg(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;
    final resized = decoded.width <= _targetWidth
        ? decoded
        : img.copyResize(decoded, width: _targetWidth);
    return Uint8List.fromList(img.encodeJpg(resized, quality: _jpegQuality));
  }
}
