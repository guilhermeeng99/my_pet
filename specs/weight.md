# Spec — Weight & growth

## Goal

Record periodic weigh-ins for each pet and visualize the trend in a chart, alerting on large variations.

## Entities

### `WeightEntry`

| Field         | Type        | Notes                                              |
| ------------- | ----------- | -------------------------------------------------- |
| `id`          | `String`    |                                                    |
| `householdId` | `String`    |                                                    |
| `petId`       | `String`    |                                                    |
| `date`        | `DateTime`  |                                                    |
| `weightKg`    | `double`    | > 0, max 200kg (sanity check)                      |
| `notes`       | `String?`   | "After fasting", "Home digital scale", etc.        |
| `createdAt`   | `DateTime`  |                                                    |
| `createdBy`   | `String`    |                                                    |

**Invariants:**
- `weightKg > 0`
- `weightKg <= 200`
- `date <= now`

## Business rules

1. Creating a `WeightEntry` updates `pets/{petId}.currentWeightKg` if `date >= max date in collection`.
2. Deleting the most recent entry recomputes `currentWeightKg` to the second most recent.
3. > 10% change within 30 days → yellow alert badge on the pet card.
4. > 20% change within 30 days → red alert + suggestion "consider seeing a veterinarian".
5. Chart shows the last 12 months by default; user can switch to 3, 6, 12 months or all-time.

## Repository contract

```dart
abstract class WeightRepository {
  Stream<List<WeightEntry>> watchByPet(String householdId, String petId);
  Future<Either<Failure, WeightEntry>> create(WeightEntry entry);
  Future<Either<Failure, WeightEntry>> update(WeightEntry entry);
  Future<Either<Failure, Unit>> delete(String householdId, String petId, String entryId);
  Future<Either<Failure, WeightStats>> computeStats(String householdId, String petId);
}

class WeightStats {
  final WeightEntry? latest;
  final double? change30dPercent;
  final double? change90dPercent;
  final double? min;
  final double? max;
  final double? avg;
}
```

## Local cache (Hive CE)

- Box: `weights`
- Type ID: `HiveTypeIds.weightEntry`

## States

### `WeightHistoryCubit`

```
WeightHistoryInitial
WeightHistoryLoading
WeightHistoryLoaded(entries, stats, range)
WeightHistoryEmpty
WeightHistoryError(failure)
```

## Edge cases

- First weigh-in for the pet → `change30dPercent = null`, no alert
- Two entries < 1h apart → allow, but only the latest is "current"
- Unit: always kg internally; UI converts to lbs if user prefers (Phase 4)

## Screens

- `WeightTab` (inside PetDetail) — chart on top, list below
- `WeightFormSheet` — bottom sheet with numeric input + date picker

## Permissions

Owner and member: full CRUD. Hard-delete allowed for any member.
