# Spec — Household (shared account)

## Goal

The unit of data ownership is the **household** (family), not the user. This lets admin and members see the same pets without duplicating data.

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
- `memberIds.length ≥ 1` (the owner)

### `Invite` (subcollection `households/{id}/invites/`)

| Field       | Type       | Notes                                            |
| ----------- | ---------- | ------------------------------------------------ |
| `id`        | `String`   | Doc ID                                           |
| `code`      | `String`   | 6 alphanumeric uppercase characters              |
| `createdBy` | `String`   | UID                                              |
| `expiresAt` | `DateTime` | 24h after creation                               |
| `usedBy`    | `String?`  | UID that accepted; null while still valid        |

## Business rules

1. After the first successful sign-in, if `users/{uid}.householdId == null`, create a new household with `ownerId = uid`, `memberIds = [uid]`, and update the user doc.
2. Only the owner can: invite members, remove members, transfer ownership, delete the household.
3. Members (non-owner) can read everything and create/edit pets, vaccines, etc. — but **cannot** hard-delete a pet (only archive) and cannot manage members.
4. Invite codes are unique within `households/{id}/invites` and expire in 24 hours.
5. Accept invite:
   - 5.1. If the user is already in another household, block with `AlreadyInHouseholdFailure` and a clear message.
   - 5.2. Add UID to `memberIds`, mark invite as `usedBy = uid`, update `users/{uid}.householdId`.
   - 5.3. Atomic operation (batched write).
6. Remove member: drops UID from `memberIds` and clears `users/{uid}.householdId`. Pets/data stay in the household.
7. Transfer admin: swap `ownerId`, keep `memberIds`. Only the current owner can transfer.
8. Delete household: only when `memberIds == [ownerId]` (alone); otherwise ask to remove members first. Soft-delete preferred (keeps pets as history).

## Repository contract

```dart
abstract class HouseholdRepository {
  Stream<Household?> watchCurrent(String userId);
  Future<Either<Failure, Household>> createForUser(AuthUser user);
  Future<Either<Failure, Invite>> generateInvite(String householdId, String createdBy);
  Future<Either<Failure, Household>> acceptInvite(String code, String userId);
  Future<Either<Failure, Unit>> removeMember(String householdId, String memberId);
  Future<Either<Failure, Unit>> transferOwnership(String householdId, String newOwnerId);
  Future<Either<Failure, Unit>> renameHousehold(String householdId, String newName);
}
```

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
- Two members edit the same pet offline → conflict resolved last-write-wins by server `updatedAt` (see [`sync.md`](sync.md)).
- Owner lost access to Google account → future: "recover admin" via owner's email to another member.

## Screens

- `HouseholdSettingsPage` — household name, member list, invite button
- `InvitePage` — generates code, shows QR + text, share button
- `JoinHouseholdPage` — code input, "join" button
- `MemberDetailSheet` — option "remove" (owner only) or "transfer admin"

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
