# Roadmap — my_pet

Tracker of what is done, in progress and planned. Use the checkboxes to mark progress. Each feature links to its spec in [`specs/`](specs/).

**Legend:** ✅ done · 🟡 in progress · ⬜ planned · ❄️ idea / future

---

## Phase 0 — Foundation

> Everything the app needs to graduate from "Hello, World!" Flutter into a navigable, secure skeleton.

- [x] CLAUDE.md with project conventions
- [x] README + SETUP for public forks
- [x] `.gitignore` hardened against Firebase secrets
- [x] Initial specs for all Phase 1 features
- [x] `firestore.rules` + `firestore.indexes.json` versioned
- [x] `storage.rules` versioned
- [x] LICENSE (MIT)
- [x] Design system spec ([`specs/design.md`](specs/design.md))
- [x] `lib/{app,core,features,gen}` folder structure created
- [x] `pubspec.yaml` with full base stack (bloc, get_it, go_router, dartz, hive_ce, firebase_*, slang, etc.)
- [x] Material 3 theme matching the design system (`lib/app/theme/`)
- [x] `go_router` shell + placeholder routes (splash → welcome)
- [x] DI container scaffold (`lib/app/di/injection_container.dart`)
- [x] Hive bootstrap entry point (`AppBootstrap.run`) — boxes opened as features land
- [x] Splash + minimal onboarding (placeholder welcome)
- [x] slang config + `i18n/en.i18n.json` base
- [x] Smoke widget test for theme + welcome page
- [x] Run `flutter pub get` + `flutterfire configure` (manual; see SETUP.md)
- [x] Run `dart run slang` + `dart run build_runner build`
- [x] Basic CI on GitHub Actions (analyze + test)

---

## Phase 1 — MVP (login + 1 pet + vaccinations)

> Goal: usable for real with **one** pet and **one** person.

### 🔐 Authentication — [`specs/auth.md`](specs/auth.md)
- [x] Google Sign-In (Firebase Auth)
- [x] Sign out
- [x] Global auth state (Bloc)
- [x] Network / cancellation error handling

### 🏠 Household (account) — [`specs/household.md`](specs/household.md)
- [x] Setup page after sign-in: "Create my family" / "Enter with a code"
- [x] Persist `householdId` in `users/{uid}`
- [x] Settings tab with identity card + partner section (members management UI)

### 🐾 Pets — [`specs/pets.md`](specs/pets.md)
- [x] Create pet (name, species, sex, birth date)
- [x] Edit pet
- [x] Pet list (home)
- [x] Profile photo (upload via Firebase Storage)
- [x] Soft-delete (archive pet)
- [x] Age computed from birth date

### 💉 Vaccinations — [`specs/vaccinations.md`](specs/vaccinations.md)
- [x] Register applied vaccine (name, date, next due date)
- [x] List history per pet
- [x] Visual indicator: "due in N days" / "overdue"
- [x] Edit / delete vaccine
- [x] Suggestions for common vaccines (V4, V5, rabies)

### 🔔 Local reminders — [`specs/notifications.md`](specs/notifications.md)
- [x] Local notification 7 days before next dose
- [x] Local notification on the day
- [x] Notification permission in onboarding

---

## Phase 1.5 — Visual redesign 🟡

> Reskin to vibrant blue + bottom-nav shell + shared widget catalog. Inspired by the FocaAI reference. Domain / data / cubits unchanged — surface only.

- [x] Repaint primary palette (purple → blue) in `app_colors` / `app_palette` / `app_shadows` / `app_typography`
- [x] Build shared widgets in `lib/app/widgets/` (`AppCard`, `AppPrimaryButton`, `AppSecondaryButton`, `StatCard`, `GreetingCard`, `FeatureListCard`, `SectionHeader`, `StatusBadge`, `AppBottomNav`, `ScreenScaffold`, `PetMascot`)
- [x] `StatefulShellRoute` with 4-tab bottom nav (Home / Reminders / Stats / Profile)
- [x] Restyle Splash, Welcome, Login, Pets Home, Pet Detail, Pet Form, Vaccinations List, Vaccination Form
- [x] Stub pages for Reminders / Stats / Profile tabs
- [x] Reserve `assets/illustrations/mascot.svg` slot — commissioned illustration deferred (programmatic mascot in place)
- [x] Photo viewer page reworked to consume design tokens (no hardcoded colors / radii / font sizes)
- [ ] Manual QA at 200 % font scale (app is light-only — dark mode removed)

---

## Phase 2 — Complete pet parent

> Health history, weight, more love.

### 🩺 Health — [`specs/health.md`](specs/health.md)
- [x] Log vet visit
- [x] Log medication (with schedule — name, dosage, frequency, duration)
- [x] Log dewormer (`HealthEventType.deworming` / `fleaTickControl`)
- [x] Log grooming session
- [ ] Attach photo / PDF per event (deferred — lands with Gallery/Documents)
- [x] Optional cost (currency-agnostic) per event

### ⚖️ Weight & growth — [`specs/weight.md`](specs/weight.md)
- [x] Register weigh-in (bottom-sheet form; updates `pet.currentWeightKg`)
- [x] Weight evolution chart (custom sparkline; fl_chart deferred)
- [x] Visual alert if change > 10% (warning) / > 20% (danger) in 30 days

### 📷 Gallery — [`specs/gallery.md`](specs/gallery.md)
- [x] Add photos to a pet (grid w/ thumbnails)
- [x] Full-screen viewer (pinch-zoom + caption / set-as-profile / delete)
- [ ] Share photo (platform share sheet — deferred)

### 📄 Documents — [`specs/documents.md`](specs/documents.md)
- [x] Upload PDFs / images (pet ID, exams)
- [x] Category per type (`DocumentCategory` enum)
- [x] Inline preview (image fullscreen viewer; PDFs copy link to clipboard until a PDF viewer ships)

### 🔔 Generic reminders — [`specs/reminders.md`](specs/reminders.md)
- [x] Standalone reminders (not tied to vaccines)
- [x] Recurrence (daily, weekly, monthly, yearly, custom interval)
- [x] Mark as done (rolls a new instance forward for recurring reminders)

---

## Phase 3 — Sharing & cloud

> You + spouse access the same pets. Real push.

### 👥 Shared household — [`specs/household.md`](specs/household.md)
> Pulled forward into Phase 1.5: app supports owner + 1 partner (max 2 members).
- [x] Family members screen (settings tab, partner card)
- [x] Generate invite code (6 chars, 24h TTL) — top-level `inviteCodes/{code}`
- [x] Accept invite (atomic batched write, drops empty old household)
- [x] Danger zone — delete-all-data cascade (Firestore + Firebase Auth, idempotent, sole-member only)
- [x] Remove member (admin only)
- [x] Transfer admin
- [x] Leave household (partner-only; data stays with the remaining owner)
- [x] Minimal audit log (`households/{id}/audit`, append-only, capped at 100)
- [x] Tests for repository member-management ops

### ☁️ Sync & offline — [`specs/sync.md`](specs/sync.md)
- [ ] Local Hive cache (read-through)
- [ ] Offline operation queue (outbox box)
- [ ] Conflict resolution: last-write-wins by server timestamp
- [ ] "Syncing" / "offline" indicator

### 📲 Push notifications — [`specs/notifications.md`](specs/notifications.md)
- [ ] Register FCM token in `users/{uid}/fcmTokens`
- [ ] Cloud Function dispatching push N days before vaccinations
- [ ] Push to all household members

---

## Phase 4 — Polish & differentiation

### 🌐 Responsive web
- [ ] Desktop / tablet adapted layouts
- [ ] Keyboard shortcuts in lists

### 🌗 Accessibility & i18n
- [ ] A11y audit (semantics, contrast, touch target size) — needs manual device testing
- [x] Add pt-BR locale via slang
- [x] Dynamic font scaling (relies on Flutter's native MediaQuery.textScaler)

### 📊 Insights
- [x] Insights dashboard MVP (pet count + species breakdown, active / overdue / due-this-week reminders)
- [ ] Cumulative veterinary spending (needs household-wide health-event aggregation)

### 🆘 Emergency
- [x] Pet ID card (microchip, allergies, contact email; copy-summary to clipboard)
- [ ] "Lost pet" mode — printable poster PDF (needs `pdf` package; deferred)

---

## Code-quality pass (2026-05) ✅

> Outcome of the post-Phase-4 audit. Implementation pass on a punch list of
> architecture / robustness items found during code review.

- [x] **Recurrence month-end clamp (BLOCKER)**: `Recurrence.monthly`/`yearly`
      now clamp to last day of target month instead of overflowing
      (`recurrence.dart`). Edge cases covered by `recurrence_test.dart`.
- [x] **Specific failure mapping**: `core/errors/firebase_failure_mapper.dart`
      translates `FirebaseException` codes (`unavailable`,
      `permission-denied`, `not-found`, …) into the typed `Failure`
      hierarchy. Wired into all repositories.
- [x] **Logging on swallowed errors**: vaccinations & reminders schedule
      failures, weight cascade failures, household audit-write failures
      and auth profile-enrichment failures now log via `dart:developer`.
- [x] **`SessionScope`**: `lib/app/session/session_scope.dart` resets
      session-scoped singletons (currently `PetsListCubit`) when
      `AuthBloc` succeeds in signing out.
- [x] **DateTimeUtils + AppConstants**: magic numbers (max members, invite
      TTL, audit cap, due-soon window, weight thresholds, lead days,
      history page limit) centralised in `core/constants/app_constants.dart`;
      shared date helpers in `core/utils/date_time_utils.dart`.
- [x] **Pagination**: `vaccinations`, `health_events`, `weights`,
      `gallery`, `documents`, and active `reminders` queries now apply
      `.limit(historyPageLimit)` (200) so unbounded growth doesn't bite.
- [x] **Cubit smoke tests**: 14 cubits previously without `bloc_test`
      coverage now have it (pet form, vaccinations list/form, weight
      history/form, health timeline/form, gallery, documents list,
      insights, household, invite, join household, account deletion,
      member management). Suite at 129 tests, all green.
- [x] Roadmap, spec for reminders edge cases, and CLAUDE.md kept in sync.

---

## Auth & startup robustness (2026-05) ✅

> Eliminate the race between Firebase Auth and the Firestore profile that was
> causing the household-setup page to flicker on sign-in, the join flow to
> bounce back to setup after success, and cubits to crash with
> "emit after close" when re-signing in after account deletion. Patterned on
> the my-cycle app's [`StartupCubit`] + profile-stream design.

- [x] **Profile-stream auth state**: `AuthRepositoryImpl.watchAuthState` now
      uses `asyncExpand` to switch from Firebase Auth onto a Firestore
      `users/{uid}` snapshots stream. Joining a household via the invite-code
      flow now propagates the new `householdId` into the AuthBloc state
      naturally — no manual refresh event needed.
- [x] **Startup feature** ([`specs/startup.md`](specs/startup.md)): new
      `StartupCubit` gates the router until `AuthBloc` emits its first
      non-`Initial` state. Splash route now hosts `StartupPage` with a
      determinate progress bar. Router redirect short-circuits to `/` until
      startup resolves; `refreshListenable` listens to both `AuthBloc.stream`
      and `StartupCubit.stream`.
- [x] **Cubit lifecycle hardening**: `PetsListCubit` and
      `AccountDeletionCubit` now guard every `emit` with `if (isClosed)
      return;` so async completions that land after the page unmounts (e.g.
      because the auth stream just flipped to null) no longer crash the app.
- [x] **SessionScope on auth-stream null**: `AuthBloc._onStreamUpdated` now
      calls `SessionScope.reset()` when the watcher emits `null` (account
      deletion / external token revocation), not just on explicit
      `SignOutRequested`. Previous-session singletons (`PetsListCubit`) are
      always recreated for the next sign-in.
- [x] **Firestore rules — missing field hardening**: `users/{userId}` create
      rule now checks `!('householdId' in request.resource.data.keys())`
      instead of `request.resource.data.householdId == null`. Dot-access on
      an absent map key derails rule evaluation in Firestore Rules v2; the
      `in keys()` form is safe.

[`StartupCubit`]: ../my-cycle/lib/features/startup/

---

## Release & distribution (2026-05) ✅

> Automated Android delivery to internal testers. Pushes to `main` ship a
> signed APK to Firebase App Distribution without manual steps.

- [x] **Firebase App Distribution wired into CI**: `distribute-android` job in
      `.github/workflows/ci.yml` runs after `analyze-and-test` on `main`,
      uploads via `firebase appdistribution:distribute` to the `internal`
      tester group.
- [x] **Dedicated release keystore** (`my_pet-release.jks`, RSA 2048,
      validity 10000 days). Stored offline + in password manager; never
      committed. Configured in `android/app/build.gradle.kts` via env vars,
      with fallback to debug keystore so local `flutter run --release`
      keeps working.
- [x] **Auto-versioning**: `versionName` read from `pubspec.yaml`,
      `versionCode` = `github.run_number` (monotonic, no collisions on
      re-runs).
- [x] **Sensitive files restored from GitHub Secrets** at CI time:
      `firebase_options.dart`, `google-services.json`, service account
      JSON, keystore. Repo stays public-safe.
- [x] **SHA-1 + SHA-256 of the release keystore** registered on Firebase
      so Google Sign-In works in distributed builds.

---

## Future ideas (❄️)

- Integration with vet clinics (import lab results)
- Food bag estimate (when does it run out)
- Behavior / mood diary
- Support for more species (dogs, birds, reptiles) with species-specific vaccine presets
- Pet sitter mode — temporary invite with reduced permissions
- AI suggestions (Vertex/Gemini) for questions like "common vaccines for an adult cat"
- Export history as PDF for the vet
- Apple Watch / Wear OS for quick weigh-ins

---

## Conventions

- Keep phases in delivery order
- Don't tick ✅ until **spec updated + tests passing + UI manually verified**
- When a future idea moves into build, promote it to the right phase
- No fixed dates — this is a personal project
