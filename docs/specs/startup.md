# Startup — Specification

> Status: draft v1 · Owner: @guiga · Last updated: 2026-05-11

Sequences cold-start work between Firebase init and the first interactive screen. Owns the splash UI and gates the router redirect.

---

## Why a dedicated cubit

Without an explicit startup phase, every screen has to defend against "auth is still resolving" and "Firestore profile is still empty." Worse, the `AuthBloc` historically emitted intermediate states (`AuthNeedsHousehold` mid-resolution) that the router would then bounce on, causing flicker between the household-setup page and home.

Splitting startup out means:

- The **router redirect** has a single boolean — "is startup done?" — instead of decoding partial auth states.
- The **splash UI** can show real progress (auth check, profile fetch, future work) instead of a parked spinner.
- Future init steps (Hive box hydration, Firestore prefetch, biometric gate, locale resolution) plug in here without touching feature code.

The `AuthBloc` resolves on its own via Firebase Auth + the `users/{uid}` Firestore profile stream (`AuthRepositoryImpl.watchAuthState`). `StartupCubit` is the orchestrator that *waits* for that resolution and then runs whatever needs to run before the first authenticated page is rendered.

---

## State machine — `StartupCubit`

```
[Initial] ──initialize()──> [Loading(progress: 0.2)]
                              │
                              ▼
                  wait for AuthBloc to leave AuthInitial
                              │
                              ▼
                          [Loading(progress: 0.7)]
                              │
                ┌─────────────┴─────────────┐
                ▼                           ▼
       [Authenticated]              [Unauthenticated]
```

Today only auth resolution gates the transition. Future hooks slot into the `Loading(progress: 0.7)` window before the terminal state is emitted (`AppBootstrap` already opens Hive boxes synchronously during `main()`, so there is no async hydration step yet).

`initialize()` is idempotent — calling it again from a non-`Initial` state is a no-op.

---

## What counts as "auth resolved"

The `AuthBloc` state machine has six states. Startup only cares whether the *first* emission has arrived from the Firebase Auth / Firestore profile stream:

| AuthState                    | Resolved? | Terminal startup outcome     |
| ---------------------------- | --------- | ---------------------------- |
| `AuthInitial`                | no        | —                            |
| `AuthLoading`                | no        | — (mid-Google-sign-in)       |
| `AuthAuthenticated`          | yes       | `StartupAuthenticated`       |
| `AuthNeedsHousehold`         | yes       | `StartupAuthenticated`       |
| `AuthCreatingHousehold`      | yes       | `StartupAuthenticated`       |
| `AuthUnauthenticated`        | yes       | `StartupUnauthenticated`     |
| `AuthErrorState`             | yes       | `StartupUnauthenticated`     |

`NeedsHousehold` and `CreatingHousehold` count as authenticated for startup purposes — there *is* a Firebase Auth user; the household-setup screen is just one of the post-auth routes.

---

## Public API

```dart
class StartupCubit extends Cubit<StartupState> {
  StartupCubit({required AuthBloc authBloc});
  Future<void> initialize();
}

sealed class StartupState extends Equatable { ... }
final class StartupInitial extends StartupState {}
final class StartupLoading extends StartupState {
  final double progress;       // 0..1
}
final class StartupAuthenticated extends StartupState {}
final class StartupUnauthenticated extends StartupState {}
```

Registered as a DI lazy singleton. `StartupPage.initState` posts a frame callback that calls `initialize()` once. The cubit cancels its `AuthBloc` subscription on `close()`.

---

## Router integration

The `AppRouter` redirect short-circuits to the splash route until startup emits a terminal state:

```dart
final startup = sl<StartupCubit>().state;
final startupDone =
    startup is StartupAuthenticated || startup is StartupUnauthenticated;
if (!startupDone) {
  return loc == AppRoutes.splash ? null : AppRoutes.splash;
}
```

`refreshListenable` re-evaluates the redirect on emissions from *both* `AuthBloc.stream` and `StartupCubit.stream` (combined via a single `ChangeNotifier`).

---

## Splash UI

`StartupPage` keeps the existing branded splash (mascot + wordmark + tagline) but replaces the spinner with a thin determinate `LinearProgressIndicator` driven by `StartupLoading.progress`. Terminal states are never seen visually — the redirect kicks in before the next frame.

---

## Edge cases

1. **Firebase already has a session on cold start** — Firebase Auth restores the user from disk, the profile stream emits the cached Firestore doc, `AuthBloc` transitions to `AuthAuthenticated`, `_waitForAuth()` returns immediately, splash is gone in one frame.
2. **No session, never signed in** — `AuthBloc` emits `AuthUnauthenticated`, `StartupCubit` emits `StartupUnauthenticated`, redirect routes to `/login` (the consolidated sign-in screen; the old `/welcome` intermediate was removed).
3. **`initialize()` called twice** — second call is a no-op (early return when state is not `Initial`).
4. **Auth state flips during startup** — `_waitForAuth()` completes on the first non-`AuthInitial`/`AuthLoading` emission and unsubscribes; later flips are handled by `AuthBloc`-driven router redirects.
5. **Profile stream errors during startup** — `AuthRepositoryImpl._watchProfileWithFallback` yields the raw Firebase entity, `AuthBloc` emits `AuthNeedsHousehold` (no `householdId`), startup resolves to `Authenticated`.
6. **Future: explicit init work fails (e.g. Hive open)** — emit `StartupError(message)` and add a retry path. Not implemented yet.

---

## Test plan

- Initial state is `StartupInitial`.
- `initialize()` from a synchronous `AuthAuthenticated` emits `Loading → Authenticated`.
- `initialize()` from a synchronous `AuthUnauthenticated` emits `Loading → Unauthenticated`.
- `initialize()` while `AuthInitial`, then auth resolves to `AuthAuthenticated`, emits `Loading → Authenticated`.
- `initialize()` while `AuthInitial`, then auth resolves to `AuthNeedsHousehold`, still emits `Loading → Authenticated` (signed in, just missing household).
- Calling `initialize()` twice does not re-emit.
- `close()` cancels the `AuthBloc` subscription before the cubit is disposed.
