/// Date math helpers used across features.
///
/// Centralizes "X days from now / ago" and day-boundary calculations so
/// timezone handling stays consistent (the app stores UTC, renders local —
/// see CLAUDE.md / Date/Time).
abstract final class DateTimeUtils {
  /// Returns `now` with the time of day zeroed (UTC). Used when we need to
  /// compare a `dueAt` against "today" without leaking the current hour.
  static DateTime startOfTodayUtc({DateTime? now}) {
    final n = (now ?? DateTime.now()).toUtc();
    return DateTime.utc(n.year, n.month, n.day);
  }

  /// `start` shifted by exactly [days] (24h windows, no DST drift since UTC).
  static DateTime addDays(DateTime start, int days) {
    return start.add(Duration(days: days));
  }

  /// `start` shifted backwards by exactly [days].
  static DateTime subtractDays(DateTime start, int days) {
    return start.subtract(Duration(days: days));
  }

  /// UTC `now` plus [days] — convenience for "X days from now".
  static DateTime daysFromNow(int days, {DateTime? now}) {
    final n = (now ?? DateTime.now()).toUtc();
    return n.add(Duration(days: days));
  }

  /// UTC `now` minus [days] — convenience for "X days ago".
  static DateTime daysAgo(int days, {DateTime? now}) {
    final n = (now ?? DateTime.now()).toUtc();
    return n.subtract(Duration(days: days));
  }
}
