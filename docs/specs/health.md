# Spec — Health (clinical events)

## Goal

Centralize every health event for a pet that is **not** a vaccine: vet visits, medications, dewormers, baths/grooming, weigh-ins (cross-link), exams, observed symptoms.

## Entities

### `HealthEvent`

| Field           | Type                  | Notes                                                       |
| --------------- | --------------------- | ----------------------------------------------------------- |
| `id`            | `String`              |                                                             |
| `householdId`   | `String`              |                                                             |
| `petId`         | `String`              |                                                             |
| `type`          | `HealthEventType`     | see enum                                                    |
| `title`         | `String`              | e.g. "Routine checkup", "Bravecto"                          |
| `date`          | `DateTime`            | When it occurred                                            |
| `endDate`       | `DateTime?`           | For ongoing treatments (e.g. medication for 7 days)         |
| `description`   | `String?`             | Free-form details                                           |
| `vetName`       | `String?`             | (for visits/exams)                                          |
| `clinicName`    | `String?`             |                                                             |
| `medication`    | `MedicationDetails?`  | Sub-object when `type == medication`                        |
| `attachmentUrls`| `List<String>`        | Prescriptions, photos, exam files                           |
| `cost`          | `double?`             | Amount paid (currency stored in user settings)              |
| `reminderIds`   | `List<String>`        | Linked reminders (e.g. take medicine)                       |
| `createdAt`     | `DateTime`            |                                                             |
| `createdBy`     | `String`              |                                                             |

The MVP entity does not carry an `updatedAt` — Firestore docs are
immutable beyond the explicit fields in `_toMap` and there is no
sync-conflict logic yet that would consume it.

```dart
enum HealthEventType {
  vetVisit,        // checkup
  medication,      // medicine
  deworming,       // dewormer
  fleaTickControl, // flea/tick prevention
  grooming,        // bath/grooming
  exam,            // lab/imaging exam
  symptom,         // observed symptom at home
  other,
}

class MedicationDetails {
  final String name;
  final String dosage;          // "10mg"
  final String frequency;       // "every 12h"
  final int durationDays;       // 7
  final String? prescribedBy;
}
```

**Invariants:**
- `title.trim().isNotEmpty`
- `date <= now` for retrospective types; `medication` may have `endDate > now`
- `endDate >= date` if present
- `cost >= 0` if present

## Business rules

1. For `type == medication` with `endDate`, schedule daily reminders until `endDate` at the configured frequency (Phase 2; Phase 1 only schedules a single reminder for the next dose).
2. For `type == deworming` or `fleaTickControl`, suggest a `nextDueDate` based on the product (presets: Bravecto 90d, Drontal 90d, NexGard 30d, etc.) — opt-in, never automatic.
3. For `type == grooming`, optional recurring reminder (e.g. every 30 days).
4. Attachments use the same `PhotoStorageService` as pets. PDFs use `DocumentStorageService` (see [`documents.md`](documents.md)).
5. Total cost per pet/month is computed on demand for the insights screen (Phase 4).
6. Symptoms (`type == symptom`) feed a visual timeline ("what happened this past month") — useful to bring to the vet.

## Repository contract

```dart
abstract class HealthRepository {
  Stream<List<HealthEvent>> watchByPet(String householdId, String petId);
  Stream<List<HealthEvent>> watchByPetAndType(String householdId, String petId, HealthEventType type);
  Stream<List<HealthEvent>> watchRecentForHousehold(String householdId, {int limit = 20});
  Future<Either<Failure, HealthEvent>> create(HealthEvent event, {List<File> attachments});
  Future<Either<Failure, HealthEvent>> update(HealthEvent event);
  Future<Either<Failure, Unit>> delete(String householdId, String petId, String eventId);
}
```

## Local cache (Hive CE)

- Box: `health_events`
- Type ID: `HiveTypeIds.healthEvent`
- Sub-objects (`MedicationDetails`) are also `@HiveType` — type ID `HiveTypeIds.medicationDetails`

## States

### `HealthTimelineCubit`

```
HealthTimelineInitial
HealthTimelineLoading
HealthTimelineLoaded(events, groupedByMonth)
HealthTimelineEmpty
HealthTimelineError(failure)
```

## Edge cases

- Medication created retroactively (already finished) → no reminder scheduled
- PDF attachment too large → 20MB cap, warn upfront
- Editing `type` of an event does not migrate type-specific fields (e.g. removing `medication` drops `MedicationDetails`) — confirm with user

## Screens

- `HealthTab` (inside PetDetail) — timeline with type filters
- `HealthEventFormPage` — adaptive form per `type`
- `HealthEventDetailSheet`
- `HouseholdRecentActivityCard` (Home) — recent events across pets

## Permissions

Same as [`pets.md`](pets.md): owner and member can CRUD; owner-only hard delete is not enforced for granular events (any member can delete a single health event since the impact is small).
