# Spec — Household (shared account)

## Goal

The unit of data ownership is the **household** (family), not the user. This lets admin and members see the same pets without duplicating data.

A household holds **at most two members**: the owner (admin) and one partner. Bigger families are out of scope until pet-sitter mode lands (see roadmap).

## Entities

### `Household`

| Field       | Type                  | Notes                                            |
| ----------- | --------------------- | ------------------------------------------------ |
| `id`        | `String`              | Doc ID under `households/`                       |
| `name`      | `String`              | Default: "{ownerDisplayName}'s family"           |
| `ownerId`   | `String`              | UID of the current admin                         |
| `memberIds` | `List<String>`        | UIDs of members (includes the owner)             |
| `createdAt` | `DateTime`            |                                                  |

**Invariants:**
- `ownerId ∈ memberIds` always
- A user belongs to at most one household
- `1 ≤ memberIds.length ≤ 2` (owner alone, or owner + partner)

### `Invite` (top-level collection `inviteCodes/{code}`)

The doc ID **is** the 6-char code. Top-level (not under `households/{id}/`) because the accepting user is not a household member yet, so Firestore rules cannot grant cross-household reads. A signed-in user can read `inviteCodes/{code}` to validate before accepting.

| Field         | Type       | Notes                                            |
| ------------- | ---------- | ------------------------------------------------ |
| `code` (=id)  | `String`   | 6 alphanumeric uppercase chars (no `0/O/1/I/L`)  |
| `householdId` | `String`   | Target household                                 |
| `createdBy`   | `String`   | UID                                              |
| `createdAt`   | `DateTime` |                                                  |
| `expiresAt`   | `DateTime` | 24h after creation                               |
| `usedBy`      | `String?`  | UID that accepted; null while still valid        |

## Business rules

1. After the first successful sign-in, if `users/{uid}.householdId == null`, the app routes to the **household-setup page** with two choices:
   - **Create my family** — calls `createForUser(user)`, owner = uid, memberIds = [uid].
   - **Enter with a code** — opens the join-by-code page; success links the user to an existing household.
   Household creation is **never automatic** — the user must pick. This avoids stranding the partner with an empty auto-created household they have to abandon.
2. Only the owner can: invite members, remove members, transfer ownership, delete the household.
3. Members (non-owner) can read everything and create/edit pets, vaccines, etc. — but **cannot** hard-delete a pet (only archive) and cannot manage members.
4. Invite codes are unique within `households/{id}/invites` and expire in 24 hours. Only one *unused* invite may exist at a time per household — generating a new one supersedes the previous (the previous is left as expired/invalidated).
5. Accept invite:
   - 5.1. If the user is already in another household, block with `AlreadyInHouseholdFailure` and a clear message.
   - 5.2. If the target household already has 2 members, block with `HouseholdFullFailure`.
   - 5.3. Add UID to `memberIds`, mark invite as `usedBy = uid`, update `users/{uid}.householdId`.
   - 5.4. Atomic operation (batched write).
6a. Generate invite is rejected with `HouseholdFullFailure` when `memberIds.length == 2`.
6. Remove member: drops UID from `memberIds` and clears `users/{uid}.householdId`. Pets/data stay in the household.
7. Transfer admin: swap `ownerId`, keep `memberIds`. Only the current owner can transfer.
8. Delete household: only when `memberIds == [ownerId]` (alone); otherwise ask to remove members first. Soft-delete preferred (keeps pets as history).
9. Danger zone — **delete all data**: cascades from the settings tab. Requires `memberIds.length == 1`; otherwise surfaces `HouseholdNotEmptyFailure` with copy asking the user to remove the partner first. The cascade deletes pet subcollections (vaccinations / health_events / weights / photos), pets themselves, household-level reminders / documents, active top-level `inviteCodes` for the household, the household doc, the `users/{uid}` profile doc, and finally the Firebase Auth user. Firestore-first so a stale credential (`requires-recent-login`) doesn't strand data — the wipe is idempotent and the user can sign out, sign back in, and re-tap to finish.

## Repository contract

```dart
abstract class HouseholdRepository {
  Stream<Household?> watch(String householdId);
  Future<Either<Failure, Household>> createForUser(AuthUser user);
  Future<Either<Failure, Invite>> generateInvite({
    required String householdId,
    required String createdBy,
  });
  Future<Either<Failure, Household>> acceptInvite({
    required String code,
    required String userId,
  });
  Future<Either<Failure, List<HouseholdMember>>> fetchMembers(String householdId);
  // Phase 3+ (not yet implemented):
  // Future<Either<Failure, Unit>> removeMember(...);
  // Future<Either<Failure, Unit>> transferOwnership(...);
  // Future<Either<Failure, Unit>> renameHousehold(...);
}
```

`HouseholdMember` is a lightweight read-model with `uid`, `displayName`, `email`, `photoUrl`, and `role ∈ {owner, partner}` — built from `users/{uid}` profile docs.

## States

### `HouseholdCubit`

```
HouseholdInitial
HouseholdLoading
HouseholdLoaded(household, currentUserRole)   // role ∈ {owner, member}
HouseholdNotFound
HouseholdError(failure)
```

### `InviteCubit` (form)

```
InviteIdle
InviteGenerating
InviteGenerated(code, expiresAt)
InviteError(failure)
```

## Edge cases

- Owner removes themselves while alone in the household → not allowed; suggest "delete household".
- Owner removes themselves with other members present → require transferring admin first.
- Expired invite code → `InviteExpiredFailure`.
- Already-used code → `InviteAlreadyUsedFailure`.
- Code does not match any active invite → `InviteNotFoundFailure`.
- User accepting is already in a household → `AlreadyInHouseholdFailure`.
- Target household already has 2 members → `HouseholdFullFailure` (both on accept and on generate).
- Two members edit the same pet offline → conflict resolved last-write-wins by server `updatedAt` (see [`sync.md`](sync.md)).
- Owner lost access to Google account → future: "recover admin" via owner's email to another member.

## Screens

- `HouseholdSetupPage` — post-sign-in choice between "Create my family" and "Enter with a code"
- `ProfilePage` (settings tab) — household identity card, partner list, invite button
- `JoinHouseholdPage` — code input, "Join" button (reached from setup or — once member-management lands — from settings)
- `InviteCodeDialog` — shows the generated code with copy CTA

## Permissions (Firestore)

| Operation                         | Owner | Member | Other |
| --------------------------------- | :---: | :----: | :---: |
| Read household / pets / etc.      |  ✅   |   ✅   |  ❌   |
| Create pet / vaccination / etc.   |  ✅   |   ✅   |  ❌   |
| Update pet / vaccination          |  ✅   |   ✅   |  ❌   |
| Delete pet                        |  ✅   |   ❌*  |  ❌   |
| Manage members / invites          |  ✅   |   ❌   |  ❌   |
| Delete household                  |  ✅   |   ❌   |  ❌   |

*Members can **archive** pets (soft-delete via `archivedAt` flag) but cannot hard-delete.
