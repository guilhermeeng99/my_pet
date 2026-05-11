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
6. Leave household (partner side): drops the actor from `memberIds` and clears `users/{uid}.householdId`. Household data stays with the owner. Solo owners (no partner) cannot leave; they must use the Danger Zone to dissolve the household.
6b. Remove partner (owner side): owner detaches the partner — partner's `users/{uid}.householdId` is set to `null`, `memberIds` shrinks back to `[ownerId]`. Pets and history stay in the household with the owner. The owner stays put (no router redirect). Enforced server-side: `HouseholdFirestoreDatasource.removeMember` throws `NotOwnerException` if the actor isn't the current owner; Firestore rules permit cross-user `users/{uid}` updates only when the diff is limited to the `householdId` field, so non-owner actors can't abuse the write surface.
7. The Profile tab's member-management action is **asymmetric**:
   - **Owner** sees a danger-tinted "Remove _partner-name_" button → confirmation dialog → `MemberManagementCubit.remove`.
   - **Partner** sees the danger-tinted "Leave household" button → confirmation dialog → `MemberManagementCubit.leave`.
   The 2-member ceiling means there's always exactly one "other" person to act on, so the role flip determines the action. `transferOwnership` stays internal to the datasource batch (e.g. owner-leave auto-transfer in older flows) and has no direct UI surface.
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

- Owner taps Leave while alone (no partner) → `ValidationFailure` (from
  `CannotLeaveAsOwnerException`); UI nudges them to the Danger Zone
  delete-all-data flow.
- Owner taps Leave with a partner present → auto-transfer ownership and
  remove the owner in one batched write; no confirmation step beyond the
  existing leave dialog.
- Expired invite code → `InviteExpiredFailure`.
- Already-used code → `InviteAlreadyUsedFailure`.
- Code does not match any active invite → `InviteNotFoundFailure`.
- User accepting is already in a household → `AlreadyInHouseholdFailure`.
- Target household already has 2 members → `HouseholdFullFailure` (both on accept and on generate).
- Two members edit the same pet offline → conflict resolved last-write-wins by server `updatedAt` (see [`sync.md`](sync.md)).
- Owner lost access to Google account → future: "recover admin" via owner's email to another member.

## Screens

- `HouseholdSetupPage` — post-sign-in choice between "Create my family" and "Enter with a code"
- `ProfilePage` (settings tab) — household identity card with both members, status card, single contextual action (Generate invite when solo / Leave household when paired)
- `JoinHouseholdPage` — code input, "Join" button (reached from setup)
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
