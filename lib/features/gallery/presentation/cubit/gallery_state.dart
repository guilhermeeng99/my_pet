import 'package:equatable/equatable.dart';
import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/gallery/domain/entities/pet_photo.dart';

sealed class GalleryState extends Equatable {
  const GalleryState();
  @override
  List<Object?> get props => const [];
}

class GalleryInitial extends GalleryState {
  const GalleryInitial();
}

class GalleryLoading extends GalleryState {
  const GalleryLoading();
}

class GalleryEmpty extends GalleryState {
  const GalleryEmpty();
}

class GalleryLoaded extends GalleryState {
  const GalleryLoaded({required this.photos, required this.uploading});

  /// Newest-first.
  final List<PetPhoto> photos;
  final bool uploading;

  GalleryLoaded copyWith({List<PetPhoto>? photos, bool? uploading}) =>
      GalleryLoaded(
        photos: photos ?? this.photos,
        uploading: uploading ?? this.uploading,
      );

  @override
  List<Object?> get props => [photos, uploading];
}

class GalleryError extends GalleryState {
  const GalleryError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
