/// Project-owned boundary around local notifications.
///
/// Phase 1 covers vaccine reminders only (see [`specs/notifications.md`](../../../../specs/notifications.md)).
/// Push notifications via FCM land in Phase 3.
abstract class NotificationService {
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<bool> hasPermission();

  /// Schedules one local notification per item in `firings` (must be
  /// future-dated; past entries are silently dropped).
  Future<void> scheduleAll({
    required String groupKey,
    required String title,
    required String body,
    required List<DateTime> firings,
  });

  /// Cancels every notification associated with the given group key.
  Future<void> cancelGroup(String groupKey);
}
