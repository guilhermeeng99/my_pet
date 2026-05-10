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
}
```

`WeightStats` is computed in-process by `WeightStatsCalculator` over the
full entry stream and surfaced on `WeightHistoryLoaded.stats`. Spec rules
1 and 2 are enforced inside `WeightRepositoryImpl` via
`PetFirestoreDatasource.setCurrentWeight(...)`; backfilled (non-latest)
entries do not overwrite the pet doc.

```dart
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

- `PetWeightPage` (routed from PetDetail's "Weight" FeatureListCard) —
  alert banner (when applicable), sparkline chart, stats row
  (Latest / 30-day / Average), then the history list.
- `_WeightFormSheet` (bottom sheet) — numeric input + date picker +
  optional notes. Triggered by the FAB on `PetWeightPage`.

The MVP sparkline is rendered with `CustomPaint` to keep the dependency
surface small; `fl_chart` will replace it when richer interactions
(tooltip on tap, range toggle) are needed.

## Permissions

Owner and member: full CRUD. Hard-delete allowed for any member.
