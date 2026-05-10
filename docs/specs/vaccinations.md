# Spec — Vaccinations

## Goal

Maintain a complete history of vaccines applied to each pet and generate automatic reminders for the next dose.

## Entities

### `Vaccination`

| Field            | Type                | Notes                                                       |
| ---------------- | ------------------- | ----------------------------------------------------------- |
| `id`             | `String`            | Doc ID                                                      |
| `householdId`    | `String`            | Partitioning                                                |
| `petId`          | `String`            | FK                                                          |
| `name`           | `String`            | e.g. "V4", "Rabies", "Feline triple"                        |
| `category`       | `VaccineCategory`   | enum: `core`, `noncore`, `rabies`, `other`                  |
| `appliedDate`    | `DateTime`          | UTC, day precision                                          |
| `nextDueDate`    | `DateTime?`         | Suggested next dose                                         |
| `vetName`        | `String?`           | Who applied it                                              |
| `clinicName`     | `String?`           | Where it was applied                                        |
| `batchNumber`    | `String?`           | Batch                                                       |
| `manufacturer`   | `String?`           | Lab                                                         |
| `notes`          | `String?`           | Reactions observed, vet notes                               |
| `attachmentUrls` | `List<String>`      | Receipt (photo of the booklet)                              |
| `reminderId`     | `String?`           | FK to generated reminder (see [`reminders.md`](reminders.md))|
| `createdAt`      | `DateTime`          |                                                             |
| `updatedAt`      | `DateTime`          |                                                             |
| `createdBy`      | `String`            | UID                                                         |

**Invariants:**
- `appliedDate <= now`
- `nextDueDate > appliedDate` if present
- `name.trim().isNotEmpty`

### Derived status: `VaccinationStatus`

```dart
enum VaccinationStatus { upToDate, dueSoon, overdue, noNextDose }
```

Rules:
- `nextDueDate == null` → `noNextDose`
- `nextDueDate < now` → `overdue`
- `nextDueDate <= now + 30d` → `dueSoon`
- otherwise → `upToDate`

## Business rules

1. Every vaccination created with `nextDueDate` automatically creates a reminder with 2 firings: 7 days before and on the day.
2. Editing `nextDueDate` cancels the old reminder and creates a new one.
3. Deleting a vaccination deletes its linked reminder.
4. Per-species presets live in `lib/core/data/vaccine_presets.dart`:
   - **cat:** V3/V4/V5, Rabies, FELV
   - **dog:** V8/V10, Rabies, Kennel cough, Giardia
   - Each preset carries `name`, `category` and `defaultBoosterIntervalDays` (e.g. yearly = 365).
5. When a preset is chosen, `nextDueDate` is pre-filled as `appliedDate + boosterIntervalDays`. The user can edit.
6. The vaccination list shows **overdue** first, then **upcoming**, then history descending by `appliedDate`.

## Repository contract

```dart
abstract class VaccinationRepository {
  Stream<List<Vaccination>> watchByPet(String householdId, String petId);
  Stream<List<VaccinationWithPet>> watchUpcoming(String householdId, {int withinDays = 30});
  Future<Either<Failure, Vaccination>> create(Vaccination vaccination, {List<File> attachments});
  Future<Either<Failure, Vaccination>> update(Vaccination vaccination);
  Future<Either<Failure, Unit>> delete(String householdId, String petId, String vaccinationId);
}
```

`VaccinationWithPet` aggregates `pet` for the upcoming card on Home.

## Local cache (Hive CE)

- Box: `vaccinations` (`Box<VaccinationCacheModel>`)
- Type ID: `HiveTypeIds.vaccination`
- Indexed in memory by `petId` for fast watch streams

## States

### `VaccinationsListCubit`

```
VaccinationsListInitial
VaccinationsListLoading
VaccinationsListLoaded(vaccinations, groupedByStatus)
VaccinationsListError(failure)
```

## Edge cases

- Pet with no `birthDate` → presets still work, the user picks the date manually
- `nextDueDate` in the past on creation (e.g. recording an old dose) → allow, mark as `overdue`
- Multiple attachments > 5MB each → compress each individually

## Screens

- `VaccinationsTab` (inside PetDetail) — list grouped by status
- `VaccinationFormPage` — name autocomplete via presets, date pickers, attachments
- `VaccinationDetailSheet` — view + edit/delete
- `UpcomingVaccinationsCard` (Home) — top 3 upcoming/overdue across all pets

## Permissions

| Operation                 | Owner | Member |
| ------------------------- | :---: | :----: |
| Read                      |  ✅   |   ✅   |
| Create / update / delete  |  ✅   |   ✅   |
