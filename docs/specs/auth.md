# Spec — Authentication

## Goal

Let the user sign in with their Google account and have a profile persisted in Firestore. No sign-in, no app.

## Entities

### `AuthUser`

| Field         | Type       | Notes                                              |
| ------------- | ---------- | -------------------------------------------------- |
| `uid`         | `String`   | Firebase Auth UID (primary key)                    |
| `email`       | `String`   | Verified Google email                              |
| `displayName` | `String?`  | Google display name                                |
| `photoUrl`    | `String?`  | Google avatar                                      |
| `householdId` | `String?`  | Null until onboarding creates the household        |

**Invariants:**
- `uid` never changes during a session
- `email` is the basis for matching invites in the future

## Business rules

1. Phase 1 supports only Google Sign-In; other providers come later.
2. On first sign-in, create the document at `users/{uid}` if it does not exist.
3. If `users/{uid}.householdId` is `null`, redirect to the household-creation flow (see [`household.md`](household.md)).
4. Sign-out must clear the local Hive cache and the global state.
5. Cancellation of the Google flow (`SignInCancelled`) is not an error — return to the sign-in screen with no destructive message.
6. Token expiration → silent re-auth; if it fails, sign out and redirect.

## Repository contract

```dart
abstract class AuthRepository {
  Stream<AuthUser?> watchAuthState();
  Future<Either<Failure, AuthUser>> signInWithGoogle();
  Future<Either<Failure, Unit>> signOut();
  Future<Either<Failure, AuthUser>> getCurrentUser();
}
```

Relevant `Failure` types: `AuthCancelledFailure`, `AuthNetworkFailure`, `AuthUnknownFailure`.

## States (AuthBloc)

```
AuthInitial
AuthLoading
AuthAuthenticated(user)
AuthNeedsHousehold(user)        // signed in but householdId == null
AuthUnauthenticated
AuthError(failure)
```

### Main transitions

- `AppStarted` → listens to `watchAuthState()` → emits `Authenticated` or `Unauthenticated`
- `GoogleSignInRequested` → `AuthLoading` → `Authenticated` | `NeedsHousehold` | `Error`
- `SignOutRequested` → `Unauthenticated`

## Edge cases

- No internet → `AuthNetworkFailure` with retry
- Google account with no email (rare) → block with a clear message
- User deleted in console while signed in → force sign-out on next `watchAuthState`
- `uid` collision (very unlikely) → treat as generic error
- **Incomplete `users/{uid}` profile doc** — the Firestore doc is missing
  `email`, `displayName` or `photoUrl` that Firebase Auth carries.
  Reproducer: a prior `wipeAndLeave` deleted the user doc but
  `deleteCurrentUser` failed with `requires-recent-login`; later
  `createAndLinkToUser` recreated the doc with only `{householdId}`.
  `_watchProfileWithFallback` detects the gap on the first stream tick,
  upserts the missing fields via Firebase Auth as the source of truth, and
  suppresses the stale snapshot so the UI never flashes blank identity in
  the Profile tab's members card. Heal runs at most once per stream
  session; failure to write falls back to a merged in-memory entity.

## Screens

- `LoginPage` — sole entry point for unauthenticated users. Mascot + value-prop headline ("Boas-vindas! Vamos cuidar dos seus pets juntos.") + supportive subtitle + "Continuar com o Google" pill button. The headline copy used to live on a separate `WelcomePage`; that intermediate screen was removed because it added a tap without conveying anything beyond what this page already shows.
- `StartupPage` — shown on cold start while `StartupCubit` waits for `AuthBloc` to emit its first non-Initial state. See [`startup.md`](startup.md).

## Permissions

N/A — auth has no owner/member concept; that lives in the household.
