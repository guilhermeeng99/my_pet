/// App-wide constants for naming and limits.
///
/// Domain-specific tunables (windows, caps, TTLs) live here so changing them
/// is a single-file edit and tests can reference the same source of truth.
abstract final class AppConstants {
  static const String appName = 'My Pet';

  // ── Household ─────────────────────────────────────────────────────────
  /// Owner + 1 partner. See `docs/specs/household.md`.
  static const int householdMaxMembers = 2;

  /// Lifetime of a generated invite code.
  static const Duration inviteCodeTtl = Duration(hours: 24);

  /// Length of the human-typed invite code.
  static const int inviteCodeLength = 6;

  /// Alphabet used for invite codes — no visually ambiguous glyphs.
  static const String inviteCodeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  /// Max audit entries returned by `watchAudit` (server-side cap).
  static const int auditFeedLimit = 100;

  // ── Reminders / Vaccinations / Stats ──────────────────────────────────
  /// Window before the due date that flips a vaccination to "due soon".
  static const int vaccinationDueSoonWindowDays = 30;

  /// "This week" window used by reminders list and insights.
  static const int upcomingWindowDays = 7;

  /// How far ahead to schedule the pre-due vaccination notification.
  static const int vaccinationReminderLeadDays = 7;

  /// Spec rule 4 in `reminders.md`: cap on active reminders fetched per
  /// household to keep listener payload bounded.
  static const int activeRemindersLimit = 200;

  /// Hard cap on rows returned by per-pet history queries (vaccinations,
  /// health events, weights). Picks the high end of "we never expect more
  /// than this in a single page" — the UI doesn't paginate yet, but capping
  /// the query keeps the listener from going unbounded as data grows.
  static const int historyPageLimit = 200;

  // ── Weight ────────────────────────────────────────────────────────────
  /// Window for the short-term weight delta alert (warning >10%, danger >20%).
  static const int weightShortTermWindowDays = 30;

  /// Window for the long-term weight delta calculation surfaced on charts.
  static const int weightLongTermWindowDays = 90;

  /// Threshold (in percent points, 0..100) above which a 30-day weight
  /// change triggers a warning badge.
  static const double weightWarningPercent = 10;

  /// Threshold (in percent points, 0..100) above which a 30-day weight
  /// change triggers a danger badge.
  static const double weightDangerPercent = 20;
}
