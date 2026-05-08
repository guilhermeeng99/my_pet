# Spec — Photo gallery

## Goal

Let the pet parent add photos of their pet over time and browse a visual timeline.

## Entities

### `PetPhoto`

| Field         | Type        | Notes                                              |
| ------------- | ----------- | -------------------------------------------------- |
| `id`          | `String`    |                                                    |
| `householdId` | `String`    |                                                    |
| `petId`       | `String`    |                                                    |
| `url`         | `String`    | Storage download URL                               |
| `thumbnailUrl`| `String`    | 256x256 version for grid                           |
| `caption`     | `String?`   |                                                    |
| `takenAt`     | `DateTime?` | EXIF if available, else `createdAt`                |
| `createdAt`   | `DateTime`  |                                                    |
| `createdBy`   | `String`    |                                                    |

## Business rules

1. Storage path: `households/{householdId}/pets/{petId}/gallery/{photoId}.jpg`.
2. On upload, two versions are generated:
   - `original.jpg` — compressed to max 2048px on long side, q=88
   - `thumb.jpg` — 256x256 cover, q=80
3. Deleting a photo removes both Storage files plus the doc.
4. Limit of 500 photos per pet (to control Storage costs). Warn at 450.
5. Profile photo (`Pet.photoUrl`) is **independent** of the gallery — but a "Set as profile photo" action in the gallery overwrites `profile.jpg`.

## Repository contract

```dart
abstract class GalleryRepository {
  Stream<List<PetPhoto>> watchByPet(String householdId, String petId);
  Future<Either<Failure, PetPhoto>> upload(String householdId, String petId, File file, {String? caption});
  Future<Either<Failure, PetPhoto>> updateCaption(String householdId, String petId, String photoId, String caption);
  Future<Either<Failure, Unit>> delete(String householdId, String petId, String photoId);
  Future<Either<Failure, Unit>> setAsProfile(String householdId, String petId, String photoId);
}
```

## Local cache (Hive CE)

- Box: `photos` (metadata only — image bytes use the device's HTTP cache via `cached_network_image`)
- Type ID: `HiveTypeIds.petPhoto`

## States

### `GalleryCubit`

```
GalleryInitial
GalleryLoading
GalleryLoaded(photos, groupedByMonth)
GalleryUploading(progress)
GalleryEmpty
GalleryError(failure)
```

## Edge cases

- Parallel multi-upload → queue with aggregate progress
- Photo without EXIF date → use `createdAt`
- Photo wrongly rotated → respect EXIF orientation in preview
- Removing the profile photo leaves the pet with the default avatar

## Screens

- `GalleryTab` (inside PetDetail) — 3-column grid grouped by month
- `PhotoViewerPage` — full screen, swipe between photos, actions (caption, set profile, delete, share)

## Permissions

Owner and member: full CRUD.
