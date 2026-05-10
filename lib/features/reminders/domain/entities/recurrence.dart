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
      Recurrence.monthly => DateTime.utc(
          d.year,
          d.month + 1,
          d.day,
          d.hour,
          d.minute,
          d.second,
        ),
      Recurrence.yearly => DateTime.utc(
          d.year + 1,
          d.month,
          d.day,
          d.hour,
          d.minute,
          d.second,
        ),
      Recurrence.custom => d.add(Duration(days: customIntervalDays ?? 30)),
    };
  }
}
