# Spec — Notifications

## Goal

Alert the pet parent (and household members) about important events — upcoming vaccines, manual reminders, ongoing medications.

Two layers:

1. **Local notifications** (`flutter_local_notifications`) — scheduled on the device, work offline, cover the MVP.
2. **Push notifications** (FCM via Cloud Function) — sync across household members. Phase 3.

## Entities

### `Reminder`

Dedicated spec at [`reminders.md`](reminders.md). Here only as a reference: each reminder turns into N local notifications (one per `notifyBeforeMinutes`).

### Local notification payload

```dart
class NotificationPayload {
  final String reminderId;
  final String householdId;
  final String? petId;
  final NotificationDeepLink deepLink; // e.g. pet/{petId}/vaccinations
}
```

## Business rules

1. Notification permission is requested **once** during post-sign-in onboarding. If denied, show a persistent banner under "Settings → Notifications" with a link to system settings.
2. Every reminder create/edit reschedules its local notifications (cancelling old ones by `reminderId`).
3. Tapping a notification opens the app and navigates via go_router to the deep link in the payload.
4. iOS requires declaring `UIBackgroundModes` for FCM background — document this in `SETUP.md`.
5. Web: use Firebase service worker for push; fall back to in-app banners if disabled.
6. Push (Phase 3) is fired by a Cloud Function running daily at 8am UTC:
   - 6.1. Iterates reminders where `dueAt` is in `[now, now + 7d]` and `done == false`
   - 6.2. Sends to all tokens in `users/{memberId}/fcmTokens` for every household member
   - 6.3. Marks `notifiedAt` on the reminder to avoid duplicate sends

## Contract

```dart
abstract class NotificationService {
  Future<bool> requestPermission();
  Future<bool> hasPermission();
  Future<void> schedule(Reminder reminder);
  Future<void> cancel(String reminderId);
  Stream<NotificationPayload> onNotificationTapped();
}
```

## States

`NotificationPermissionCubit`:

```
NotificationPermissionUnknown
NotificationPermissionGranted
NotificationPermissionDenied
NotificationPermissionPermanentlyDenied
```

## Edge cases

- Device timezone change → reschedule all reminders on app start
- Reminder in the past → don't schedule, mark as `missed`
- iOS limits 64 pending notifications per app → prioritize the closest ones; the rest get rescheduled as their window approaches
- Permission revoked after grant → invalidate the permission cache on every `app resume`

## Screens

- `NotificationPermissionPage` (onboarding)
- `NotificationsSettingsPage` (settings) — toggle list per type (vaccines, medications, manual reminders)

## Permissions (Firestore — Phase 3 only)

`users/{userId}/fcmTokens/{tokenId}` is writable only by the user themselves. Household members **do not** read each other's tokens — only the Cloud Function (with service account) does, to send pushes.
