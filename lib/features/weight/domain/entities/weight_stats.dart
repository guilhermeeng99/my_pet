import 'package:equatable/equatable.dart';
import 'package:my_pet/core/constants/app_constants.dart';
import 'package:my_pet/features/weight/domain/entities/weight_entry.dart';

/// Pre-computed aggregates for the weight chart + alerts. Built by
/// [WeightStatsCalculator] over the full entry history; cached on the
/// loaded cubit state so the UI doesn't recompute on every rebuild.
class WeightStats extends Equatable {
  const WeightStats({
    this.latest,
    this.change30dPercent,
    this.change90dPercent,
    this.min,
    this.max,
    this.avg,
  });

  final WeightEntry? latest;
  final double? change30dPercent;
  final double? change90dPercent;
  final double? min;
  final double? max;
  final double? avg;

  /// Spec rule 3: > [AppConstants.weightWarningPercent]% change within
  /// [AppConstants.weightShortTermWindowDays] days triggers a yellow alert.
  bool get hasWarning =>
      change30dPercent != null &&
      change30dPercent!.abs() >= AppConstants.weightWarningPercent;

  /// Spec rule 4: > [AppConstants.weightDangerPercent]% change within
  /// [AppConstants.weightShortTermWindowDays] days triggers a red alert.
  bool get hasDanger =>
      change30dPercent != null &&
      change30dPercent!.abs() >= AppConstants.weightDangerPercent;

  @override
  List<Object?> get props =>
      [latest, change30dPercent, change90dPercent, min, max, avg];
}

class WeightStatsCalculator {
  const WeightStatsCalculator();

  WeightStats from(List<WeightEntry> entries) {
    if (entries.isEmpty) return const WeightStats();
    // Caller is free to pass any order; we make our own sorted view.
    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    final latest = sorted.last;
    final weights = sorted.map((e) => e.weightKg).toList(growable: false);
    var min = weights.first;
    var max = weights.first;
    var sum = 0.0;
    for (final w in weights) {
      if (w < min) min = w;
      if (w > max) max = w;
      sum += w;
    }
    return WeightStats(
      latest: latest,
      change30dPercent: _percentChange(
        sorted,
        days: AppConstants.weightShortTermWindowDays,
      ),
      change90dPercent: _percentChange(
        sorted,
        days: AppConstants.weightLongTermWindowDays,
      ),
      min: min,
      max: max,
      avg: sum / weights.length,
    );
  }

  double? _percentChange(List<WeightEntry> sorted, {required int days}) {
    if (sorted.length < 2) return null;
    final latest = sorted.last;
    final reference = latest.date.subtract(Duration(days: days));
    // Anchor: most recent entry not newer than `reference`.
    WeightEntry? anchor;
    for (final e in sorted) {
      if (!e.date.isAfter(reference)) {
        anchor = e;
      } else {
        break;
      }
    }
    if (anchor == null) return null;
    final delta = latest.weightKg - anchor.weightKg;
    return (delta / anchor.weightKg) * 100;
  }
}
