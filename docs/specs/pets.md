# Spec — Pets

## Goal

Full CRUD for the household's pets, with profile photo, basic data and static health data (allergies, microchip, etc.).

## Entities

### `Pet`

| Field            | Type                | Notes                                                      |
| ---------------- | ------------------- | ---------------------------------------------------------- |
| `id`             | `String`            | Doc ID                                                     |
| `householdId`    | `String`            | Partitioning key; never changes after creation             |
| `name`           | `String`            | 1..40 chars, required                                      |
| `species`        | `Species`           | enum: `cat`, `dog`, `bird`, `rabbit`, `other`              |
| `breed`          | `String?`           | free text                                                  |
| `sex`            | `Sex`               | enum: `male`, `female`, `unknown`                          |
| `neutered`       | `bool`              | castrated/spayed                                           |
| `birthDate`      | `DateTime?`         | birth date (UTC, day precision)                            |
| `adoptionDate`   | `DateTime?`         | adoption date                                              |
| `color`          | `String?`           | free text                                                  |
| `microchipId`    | `String?`           | microchip number                                           |
| `photoUrl`       | `String?`           | Firebase Storage URL                                       |
| `currentWeightKg`| `double?`           | derived from latest weigh-in (cache field)                 |
| `allergies`      | `List<String>`      | free tags                                                  |
| `notes`          | `String?`           | free text                                                  |
| `archivedAt`     | `DateTime?`         | soft-delete                                                |
| `createdAt`      | `DateTime`          |                                                            |
| `updatedAt`      | `DateTime`          | server timestamp                                           |
| `createdBy`      | `String`            | UID of the member who created it                           |

**Invariants:**
- `name.trim().isNotEmpty`
- `birthDate <= now` if present
- `adoptionDate <= now` if present
- `species` required
- Age is never stored — always computed from `birthDate`

### Computed: `Age`

```dart
class Age {
  final int years;
  final int months;
}
```

Rules:
- No `birthDate` → `null`
- Age < 1 month → "X days"
- Age < 1 year → "X months"
- Age ≥ 1 year → "X years and Y months" (drops months if Y == 0)

## Business rules

1. Only members of the household can see that household's pets.
2. Profile photo: every upload goes through `PhotoStorageService`, which compresses to 1024px max side and converts to JPEG q=85 before upload.
3. Storage path: `households/{householdId}/pets/{petId}/profile.jpg`. Overwrites on upload.
4. Soft-delete (`archive`) is the default; hard-delete is owner-only via an explicit "Delete permanently" flag with double confirmation.
5. Archived pets do not appear on Home; they're available under "Settings → Archived pets".
6. `currentWeightKg` is updated client-side every time a weigh-in is registered (see [`weight.md`](weight.md)) — source of truth is the `weights` collection.
7. Editing `birthDate` is allowed (in case the user mis-typed), but requires confirmation if the pet has linked vaccinations/events.

## Repository contract

```dart
abstract class PetRepository {
  Stream<List<Pet>> watchActive(String householdId);
  Stream<List<Pet>> watchArchived(String householdId);
  Stream<Pet?> watchPet(String householdId, String petId);
  Future<Either<Failure, Pet>> create(Pet pet, {File? profilePhoto});
  Future<Either<Failure, Pet>> update(Pet pet, {File? newProfilePhoto});
  Future<Either<Failure, Unit>> archive(String householdId, String petId);
  Future<Either<Failure, Unit>> unarchive(String householdId, String petId);
  Future<Either<Failure, Unit>> hardDelete(String householdId, String petId); // owner-only
}
```

## Local cache (Hive CE)

- Box name: `pets`
- Cache model: `PetCacheModel` with `@HiveType(typeId: HiveTypeIds.pet)`
- Mirrors the entity 1:1 plus `_updatedAtServer: int` (millis since epoch) for sync ordering
- Cleared on sign-out

## States

### `PetsListCubit`

```
PetsListInitial
PetsListLoading
PetsListLoaded(pets)
PetsListEmpty
PetsListError(failure)
```

### `PetFormCubit`

Form-mode state: idle / submitting / success(petId) / error.

## Edge cases

- Photo > 10MB → `PhotoTooLargeFailure` before starting upload
- No internet → creation saved offline in the Hive `outbox` box and synced later (see [`sync.md`](sync.md))
- Duplicate microchip inside the same household → don't block, just warn
- Pet with no photo → show avatar with the name initial + a color derived from `id`

## Screens

- `PetsHomePage` — grid of pet cards, FAB "add"
- `PetDetailPage` — tabs "Overview", "Vaccines", "Health", "Weight", "Gallery", "Documents"
- `PetFormPage` — create and edit
- `ArchivedPetsPage` — archived list

## Permissions

| Operation        | Owner | Member |
| ---------------- | :---: | :----: |
| Read pets        |  ✅   |   ✅   |
| Create pet       |  ✅   |   ✅   |
| Update pet       |  ✅   |   ✅   |
| Archive (soft)   |  ✅   |   ✅   |
| Unarchive        |  ✅   |   ✅   |
| Hard delete      |  ✅   |   ❌   |

## Species — suggested defaults

To let the UI suggest appropriate vaccines/reminders, we keep a static catalog at `lib/core/data/species_presets.dart`:

- `cat` — cat icon, common vaccines: V4, V5, rabies, FELV, FIV
- `dog` — dog icon, common vaccines: V8/V10, rabies, kennel cough, giardia
- `bird` — bird icon
- `rabbit` — rabbit icon
- `other` — generic icon, no presets
