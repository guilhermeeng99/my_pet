/// Classification of a reminder for default scheduling behavior and icon
/// selection in the UI. See `docs/specs/reminders.md` rule 2 for the
/// default `notifyBeforeMinutes` per type.
enum ReminderType {
  vaccination,
  medication,
  feeding,
  grooming,
  vetVisit,
  custom;

  /// Default lead-time notifications (in minutes before `dueAt`) per type.
  List<int> get defaultNotifyBeforeMinutes => switch (this) {
        ReminderType.vaccination => const [10080, 0], // 7d + day-of
        ReminderType.medication => const [60, 0],
        ReminderType.feeding ||
        ReminderType.grooming ||
        ReminderType.vetVisit ||
        ReminderType.custom =>
          const [0],
      };
}
