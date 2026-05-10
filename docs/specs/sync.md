# Spec — Sync & offline

## Goal

App usable offline: local cache in Hive CE, queued writes, automatic sync when connectivity returns. Last write wins on conflicts (with server timestamp).

## Strategy

- **Read-through cache:** UI reads from Hive boxes. In parallel, repositories listen to Firestore and update Hive.
- **Write-through:** UI writes to the repository, which tries to write to Firestore. If it fails offline, the write is enqueued in the `outbox` box and retried when online.
- **Source of truth:** Firestore. Hive is a cache, invalidatable at any time.

## Hive boxes

- `pets`, `vaccinations`, `health_events`, `weights`, `reminders`, `documents`, `photos`
- Each box stores typed cache models with the same shape as the entity plus `_updatedAtServer` (millis since epoch)
- `outbox` — single box keyed by `operationId`, value `OutboxOperationModel(entityType, entityId, payload, attempts, lastError, createdAt)`
- All boxes opened during `AppBootstrap.openBoxes()` before `runApp`
- Type IDs centralized in `lib/core/storage/hive_type_ids.dart`

## Rules

1. Every mutation:
   - 1.1. Optimistically writes to the cache (with `_pending = true`)
   - 1.2. Enqueues an outbox operation
   - 1.3. Tries to execute; on success, removes the outbox entry and updates the cache with the server payload
   - 1.4. On network failure, leaves the entry in outbox and marks the cached doc as pending
2. Conflict resolution: when Firestore stream brings a newer version than the cached pending one, **server wins**. Notify the user if the doc had unsaved local edits (banner: "Your changes to X were overwritten by the server").
3. Outbox processes FIFO per `entityId` (operations on the same doc cannot reorder).
4. After 5 failed attempts, mark the entry as `requiresAttention` and surface it under "Settings → Sync".
5. Photos / Documents: file uploads must persist the file locally before enqueueing. The outbox payload stores the local path.

## Status indicator

Global banner in the shell:

- Online + outbox empty → hidden
- Online + outbox has entries → "Syncing N changes..."
- Offline → "You are offline. Changes will sync when you reconnect."
- Persistent error → "There are N changes with issues. Tap to review."

## Contract

```dart
abstract class SyncEngine {
  Stream<SyncStatus> watch();
  Future<void> processOutbox();
  Future<void> retryFailed();
  Future<void> reset(); // emergency: clear cache and re-pull
}

class SyncStatus {
  final bool online;
  final int pending;
  final int failed;
  final DateTime? lastSuccessAt;
}
```

## Edge cases

- Firebase token expires during upload → silent reauth, retry
- User switched households between operations → outbox drops orphan operations (with warning)
- Storage upload fails after Firestore doc was created → leaving a doc with a non-existent URL is bad; revert the doc if upload fails (composite operation)
- Hive box corruption on cold start → `Hive.deleteBoxFromDisk(name)` and re-open empty; full re-pull triggered

## Screens

- `SyncStatusBanner` (shell)
- `SyncSettingsPage` — list of retry/error entries with "retry" / "discard" actions

## Out of scope (Phase 4+)

- Selective sync (choose which pets to keep offline)
- Manual conflict resolution (current phase: server wins)
- E2E encryption for documents
