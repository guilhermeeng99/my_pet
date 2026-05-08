# Spec — Documents

## Goal

Store PDFs and images of important pet documents: pet ID, exams, receipts, adoption contracts, prescriptions.

## Entities

### `PetDocument`

| Field         | Type                | Notes                                              |
| ------------- | ------------------- | -------------------------------------------------- |
| `id`          | `String`            |                                                    |
| `householdId` | `String`            |                                                    |
| `petId`       | `String?`           | Null = household-level doc (e.g. clinic contract)  |
| `title`       | `String`            | 1..120 chars                                       |
| `category`    | `DocumentCategory`  | enum: `petId`, `exam`, `receipt`, `contract`, `prescription`, `other` |
| `fileUrl`     | `String`            | Storage URL                                        |
| `mimeType`    | `String`            | `application/pdf`, `image/jpeg`, etc.              |
| `sizeBytes`   | `int`               |                                                    |
| `pageCount`   | `int?`              | For PDFs                                           |
| `notes`       | `String?`           |                                                    |
| `createdAt`   | `DateTime`          |                                                    |
| `createdBy`   | `String`            |                                                    |

## Business rules

1. Accepted types: `pdf`, `jpeg`, `png`, `heic`. Anything else → error.
2. Max size per file: 20MB.
3. Max total per household: 1GB (warn at 800MB).
4. Storage path: `households/{householdId}/documents/{documentId}.{ext}`.
5. Inline preview:
   - Image → native viewer with zoom
   - PDF → `pdfx` package or similar; download and cache locally

## Repository contract

```dart
abstract class DocumentRepository {
  Stream<List<PetDocument>> watchByHousehold(String householdId);
  Stream<List<PetDocument>> watchByPet(String householdId, String petId);
  Future<Either<Failure, PetDocument>> upload(PetDocument doc, File file);
  Future<Either<Failure, PetDocument>> update(PetDocument doc);
  Future<Either<Failure, Unit>> delete(String householdId, String documentId);
  Future<Either<Failure, File>> download(String householdId, String documentId);
}
```

## Local cache (Hive CE)

- Box: `documents` (metadata only)
- Type ID: `HiveTypeIds.petDocument`
- File bytes cached on disk under app cache directory keyed by `documentId`

## States

```
DocumentsInitial
DocumentsLoading
DocumentsLoaded(documents, groupedByCategory)
DocumentsUploading(progress)
DocumentsEmpty
DocumentsError(failure)
```

## Edge cases

- HEIC on Android → convert to JPEG before upload
- Password-protected PDF → show notice, but allow upload
- Document without `petId` later edited to have one → allowed
- Corrupted file → fail upload with a clear message

## Screens

- `DocumentsTab` (PetDetail) — list filtered by pet
- `DocumentsHomeTab` — every document in the household
- `DocumentFormSheet` — pick file, title, category, pet (optional)
- `DocumentViewerPage` — full-screen viewer

## Permissions

Owner and member: full CRUD.
