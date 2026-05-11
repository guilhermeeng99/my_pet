/// Recurrence pattern for a reminder. `custom` pairs with
/// `Reminder.recurrenceIntervalDays` (e.g. 90 = quarterly).
enum Recurrence {
  oneShot,
  daily,
  weekly,
  monthly,
  yearly,
  custom;

  bool get isRecurring => this != oneShot;

  /// Returns the next `dueAt` after marking the current instance done.
  /// Skips backlogged occurrences when [from] is already in the past — the
  /// caller passes the current instance's `dueAt` and the function rolls
  /// forward until the result is in the future (spec edge case 2).
  ///
  /// Returns `null` for `oneShot` (no next instance).
  DateTime? nextAfter(DateTime from, {int? customIntervalDays}) {
    if (this == oneShot) return null;
    var next = _step(from, customIntervalDays);
    final now = DateTime.now().toUtc();
    while (!next.isAfter(now)) {
      next = _step(next, customIntervalDays);
    }
    return next;
  }

  DateTime _step(DateTime d, int? customIntervalDays) {
    return switch (this) {
      Recurrence.oneShot => d,
      Recurrence.daily => d.add(const Duration(days: 1)),
      Recurrence.weekly => d.add(const Duration(days: 7)),
      Recurrence.monthly => _shiftMonths(d, 1),
      Recurrence.yearly => _shiftMonths(d, 12),
      Recurrence.custom => d.add(Duration(days: customIntervalDays ?? 30)),
    };
  }

  /// Adds [months] to [d] while preserving the original day-of-month. When
  /// the target month is shorter (e.g. monthly on Jan 31 → Feb), clamps to
  /// the last day of the target month. Without this, Dart's `DateTime.utc`
  /// would silently roll Feb 31 forward to Mar 3 and the next recurrence
  /// would drift permanently to the start of the next month.
  static DateTime _shiftMonths(DateTime d, int months) {
    final targetMonthZeroBased = d.month - 1 + months;
    final targetYear = d.year + targetMonthZeroBased ~/ 12;
    final targetMonth = targetMonthZeroBased % 12 + 1;
    final daysInTarget = _daysInMonth(targetYear, targetMonth);
    final clampedDay = d.day > daysInTarget ? daysInTarget : d.day;
    return DateTime.utc(
      targetYear,
      targetMonth,
      clampedDay,
      d.hour,
      d.minute,
      d.second,
    );
  }

  static int _daysInMonth(int year, int month) {
    const daysPerMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if (month == 2 && _isLeapYear(year)) return 29;
    return daysPerMonth[month - 1];
  }

  static bool _isLeapYear(int year) {
    if (year % 4 != 0) return false;
    if (year % 100 != 0) return true;
    return year % 400 == 0;
  }
}
