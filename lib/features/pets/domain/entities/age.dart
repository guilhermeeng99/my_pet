import 'package:equatable/equatable.dart';

/// Computed age. Source of truth is `Pet.birthDate` — never stored.
/// See [`specs/pets.md`](../../../../../specs/pets.md) for display rules.
class Age extends Equatable {
  const Age({required this.years, required this.months, required this.days});

  final int years;
  final int months;
  final int days;

  /// Returns null when birth date is in the future or null.
  static Age? from(DateTime? birthDate, {DateTime? now}) {
    if (birthDate == null) return null;
    final today = (now ?? DateTime.now()).toUtc();
    if (birthDate.isAfter(today)) return null;

    var years = today.year - birthDate.year;
    var months = today.month - birthDate.month;
    var days = today.day - birthDate.day;

    if (days < 0) {
      months -= 1;
      // Approximate "days in previous month" using a 30-day fallback —
      // good enough for "X days" copy and avoids leap-year edge cases on
      // a UI-only label.
      days += 30;
    }
    if (months < 0) {
      years -= 1;
      months += 12;
    }

    return Age(years: years, months: months, days: days);
  }

  bool get isUnderOneMonth => years == 0 && months == 0;
  bool get isUnderOneYear => years == 0;

  @override
  List<Object?> get props => [years, months, days];
}
