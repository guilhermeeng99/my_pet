import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/gallery/domain/entities/pet_photo.dart';
import 'package:my_pet/features/gallery/domain/repositories/gallery_repository.dart';
import 'package:my_pet/features/gallery/presentation/cubit/gallery_state.dart';

class GalleryCubit extends Cubit<GalleryState> {
  GalleryCubit({required GalleryRepository repository})
      : _repository = repository,
        super(const GalleryInitial());

  final GalleryRepository _repository;
  StreamSubscription<List<PetPhoto>>? _subscription;
  String? _householdId;
  String? _petId;

  void start(String householdId, String petId) {
    _householdId = householdId;
    _petId = petId;
    emit(const GalleryLoading());
    unawaited(_subscription?.cancel());
    _subscription = _repository.watchByPet(householdId, petId).listen(
      (photos) {
        if (photos.isEmpty) {
          emit(const GalleryEmpty());
          return;
        }
        final current = state;
        final uploading = current is GalleryLoaded && current.uploading;
        emit(GalleryLoaded(photos: photos, uploading: uploading));
      },
      onError: (Object error, StackTrace _) {
        emit(GalleryError(ServerFailure(message: error.toString())));
      },
    );
  }

  Future<Failure?> upload({
    required File source,
    required String createdBy,
    String? caption,
  }) async {
    final hid = _householdId;
    final petId = _petId;
    if (hid == null || petId == null) return null;
    _setUploading(true);
    final result = await _repository.upload(
      householdId: hid,
      petId: petId,
      createdBy: createdBy,
      source: source,
      caption: caption,
    );
    _setUploading(false);
    return result.fold((f) => f, (_) => null);
  }

  Future<void> updateCaption(String photoId, String? caption) async {
    final hid = _householdId;
    final petId = _petId;
    if (hid == null || petId == null) return;
    await _repository.updateCaption(hid, petId, photoId, caption);
  }

  Future<void> delete(String photoId) async {
    final hid = _householdId;
    final petId = _petId;
    if (hid == null || petId == null) return;
    await _repository.delete(
      householdId: hid,
      petId: petId,
      photoId: photoId,
    );
  }

  Future<Failure?> setAsProfile(PetPhoto photo) async {
    final result = await _repository.setAsProfile(
      householdId: photo.householdId,
      petId: photo.petId,
      photoId: photo.id,
      url: photo.url,
    );
    return result.fold((f) => f, (_) => null);
  }

  void _setUploading(bool value) {
    final current = state;
    if (current is GalleryLoaded) {
      emit(current.copyWith(uploading: value));
    } else if (value) {
      // First upload from an empty gallery — show loading until the
      // watch stream fires with the new doc.
      emit(const GalleryLoading());
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
