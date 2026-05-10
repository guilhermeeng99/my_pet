# Spec — Reminders (generic)

## Goal

Allow the user to create standalone reminders not tied to a specific vaccine/medication. Examples: "Change litter", "Buy food", "Renew clinic plan".

Reminders linked to vaccines/medications are managed by their own features but use the same `Reminder` entity under the hood.

## Entities

### `Reminder`

| Field                    | Type                  | Notes                                                |
| ------------------------ | --------------------- | ---------------------------------------------------- |
| `id`                     | `String`              |                                                      |
| `householdId`            | `String`              |                                                      |
| `petId`                  | `String?`             | Optional — can belong to the whole household         |
| `type`                   | `ReminderType`        | enum: `vaccination`, `medication`, `feeding`, `grooming`, `vetVisit`, `custom` |
| `title`                  | `String`              | 1..80 chars                                          |
| `description`            | `String?`             |                                                      |
| `dueAt`                  | `DateTime`            | UTC                                                  |
| `notifyBeforeMinutes`    | `List<int>`           | e.g. `[10080, 0]` = 7 days before + at time          |
| `recurrence`             | `Recurrence`          | enum: `oneShot`, `daily`, `weekly`, `monthly`, `yearly`, `custom` |
| `recurrenceIntervalDays` | `int?`                | For `custom` (e.g. 90 = quarterly)                   |
| `done`                   | `bool`                |                                                      |
| `doneAt`                 | `DateTime?`           |                                                      |
| `sourceFeature`          | `String?`             | e.g. `"vaccination:abc123"` for reverse-link         |
| `createdAt`              | `DateTime`            |                                                      |
| `createdBy`              | `String`              |                                                      |

**Invariants:**
- All `notifyBeforeMinutes` values ≥ 0
- `recurrence == custom` ⇒ `recurrenceIntervalDays` present and > 0
- `recurrence != oneShot` ⇒ marking `done` creates the next instance shifted by the interval

## Business rules

1. Mark as done:
   - `oneShot` → set `done = true`, `doneAt = now`
   - Recurring → set done on the current instance and create a new instance with `dueAt += interval`
2. Default `notifyBeforeMinutes` per type:
   - `vaccination` → `[10080, 0]` (7d before + day-of)
   - `medication` → `[60, 0]` (1h before + at time)
   - `feeding`, `grooming`, `custom` → `[0]` (at time)
3. Reminders with `petId == null` show on the household home; with `petId` they also show on the pet screen.
4. Cap at 200 active reminders per household to control costs.
5. Reminders with `done == true` are kept 90 days for history, then removed by a job (Phase 3).

## Repository contract

```dart
abstract class ReminderRepository {
  Stream<List<Reminder>> watchUpcoming(String householdId, {int limitDays = 30});
  Stream<List<Reminder>> watchByPet(String householdId, String petId);
  Future<Either<Failure, Reminder>> create(Reminder reminder);
  Future<Either<Failure, Reminder>> update(Reminder reminder);
  Future<Either<Failure, Reminder>> markDone(String householdId, String reminderId);
  Future<Either<Failure, Unit>> delete(String householdId, String reminderId);
}
```

## Local cache (Hive CE)

- Box: `reminders`
- Type ID: `HiveTypeIds.reminder`

## States

### `RemindersCubit`

```
RemindersInitial
RemindersLoading
RemindersLoaded(upcoming, overdue, today)
RemindersEmpty
RemindersError(failure)
```

## Edge cases

- Recurrence edited after several instances were generated → editing changes only the next instance onwards
- Marking a very late daily-recurring reminder as done does not create 30 backlogged instances — it skips to the next future occurrence
- Push fails (Phase 3) → fall back to local notification

## Screens

- `RemindersHomePage` — tabs "Today", "This week", "Later"
- `ReminderFormSheet` — bottom sheet
- `ReminderDetailSheet`

## Permissions

Owner and member: full CRUD.
