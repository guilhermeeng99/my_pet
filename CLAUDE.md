# my_pet — Project Conventions

Personal pet management app built with Flutter. Tracks pets, vaccinations, health history, vet visits and more. Supports Android, iOS and Web. Designed for a household (multiple humans, multiple pets) with Google Sign-In and Firebase backend.

This repository is **public**. No secrets, no Firebase config files, no service account keys are ever committed. Every fork must plug in its own Firebase project.

---

## Onboarding (read this first)

Before working on any task in this repo, the agent MUST orient itself using these sources:

* **`docs/roadmap.md`** — current status of every feature (✅ done · 🟡 in progress · ⬜ planned · ❄️ idea). Auto-loaded with this file (see bottom).
* **`docs/specs/<feature>.md`** — one spec per feature (`auth`, `design`, `documents`, `gallery`, `health`, `household`, `notifications`, `pets`, `reminders`, `sync`, `vaccinations`, `weight`). Read the relevant spec **before** modifying that feature's code or tests.
* **This file (`CLAUDE.md`)** — project-wide conventions. Already auto-loaded.

**Keep these in sync with the code.** Whenever implementation, requirements, or scope change:

* Update the spec under `docs/specs/` to reflect the new behavior.
* Tick / untick / move items in `docs/roadmap.md` so its status stays truthful.
* Update `CLAUDE.md` itself if a project-wide convention changed.

If a feature is touched without a corresponding spec update, the spec is now lying — fix it in the same change.

---

## Architecture

**Clean Architecture** with feature-first organization:

```
lib/
├── app/          # App shell: DI, routing, theme, shared widgets
├── core/         # Shared: errors, extensions, utils, network, value objects
├── features/     # Feature modules (each with data/domain/presentation)
└── gen/          # Generated code (i18n via slang, etc.)
```

Each feature follows:

* `domain/` — entities, repository interfaces, use cases
* `data/` — models, datasources (Firestore / Hive CE), repository implementations
* `presentation/` — cubits/blocs, pages, widgets

---

## Code Style

* Functions: 5–25 lines. Split if longer.
* Files: ideally under 400–600 lines.
* One responsibility per function/module (SRP).
* Prefer small, composable widgets over large ones.

### Naming

* Names must be specific and intention-revealing.
* Avoid generic names like `data`, `manager`, `handler`.
* Prefer names that are searchable and unique within the codebase.

### Control Flow

* Prefer early returns over nested conditionals.
* Maximum 2 levels of indentation.

---

## Comments

* Write **WHY**, not WHAT.
* Preserve important context and decisions.
* Do not remove meaningful comments during refactors.
* Public APIs must include intent, parameters, and a usage example.

---

## Key Technologies

| Aspect               | Detail                                                            |
| -------------------- | ----------------------------------------------------------------- |
| **State management** | flutter_bloc (Cubits for simple state, Blocs for event-driven)    |
| **DI**               | get_it (service locator in `lib/app/di/injection_container.dart`) |
| **Routing**          | go_router (declarative, path-based, shell route)                  |
| **Local storage**    | Hive CE (`hive_ce` + `hive_ce_flutter`) — boxes per aggregate     |
| **Remote storage**   | Firebase Firestore (source of truth) + Firebase Storage (photos)  |
| **Auth**             | Firebase Auth + Google Sign-In                                    |
| **Notifications**    | flutter_local_notifications + Firebase Cloud Messaging            |
| **Error handling**   | dartz `Either<Failure, T>` pattern                                |
| **Linting**          | very_good_analysis (strict)                                       |
| **i18n**             | slang (generated in `lib/gen/`) — English primary; pt-BR later    |
| **Theme**            | Light + Dark Material 3, Ahead-inspired tokens (see `docs/specs/design.md`) |
| **Date/Time**        | `intl` + native `DateTime` (UTC stored, local rendered)           |

---

## Commands

```bash
flutter test                            # Run all tests
flutter test test/features/pets/        # Run feature tests
flutter analyze                         # Static analysis (must be zero issues)
flutter run                             # Run the app
dart run build_runner build             # Generate code (Hive adapters, JSON, etc.)
dart run slang                          # Generate i18n
```

---

## Post-Change Checklist

After every code change:

1. Run `dart run slang` if any i18n JSON was modified
2. Run `dart run build_runner build` if Hive `@HiveType` classes or `@JsonSerializable` changed
3. Run `flutter analyze` — **zero** errors, warnings and info-level issues
4. Run `flutter test` — all tests must pass
5. Never add `// ignore` without clear justification
6. Never commit Firebase config files (`firebase_options.dart`, `google-services.json`, `GoogleService-Info.plist`, `.firebaserc`, service account JSON)

---

## Spec-Driven Development

Every feature MUST have a spec at `docs/specs/<feature>.md` before writing new code or tests.

### Workflow

1. Write or update the spec (business rules, contracts, state machines)
2. Write tests based on the spec
3. Implement or modify code to pass the tests
4. Update the spec if requirements change

### Spec Structure

* Entity contract (fields, types, invariants)
* Business rules (numbered, testable)
* Repository contract (methods, parameters, return types)
* State machines (cubit/bloc states and transitions)
* Edge cases

---

## Testing Rules

* Every new use case must have tests
* Every bug fix must include a regression test
* Tests must follow F.I.R.S.T principles: Fast, Independent, Repeatable, Self-validating, Timely

### Test Structure

* One test file per source file (mirrors `lib/`)
* Use `bloc_test` for cubit/bloc testing
* Use factories for test data — never hardcode entities
* Mock at boundaries: repositories for cubits, datasources for repositories

---

## Harness Engineering

Test infrastructure lives in `test/harness/`:

* `mocks.dart` — centralized mock declarations (mocktail)
* `helpers.dart` — shared test setup and utilities
* `factories/` — test data factories per entity (Pet, Vaccination, Household, etc.)

---

## Dependencies

* Depend on abstractions, not implementations
* Inject dependencies via constructor or DI
* External libraries must be wrapped behind project-owned interfaces (e.g. `FirebaseAuthDatasource` wraps `FirebaseAuth`, `HiveBoxStore<T>` wraps `Box<T>`)

---

## Code Conventions

* Entities use `Equatable` and provide `copyWith`
* Failures are sealed classes (`ServerFailure`, `AuthFailure`, `PermissionFailure`, `NotFoundFailure`, etc.)
* Use cases are single-method classes with `call()` operator
* Models extend entities and handle serialization
* All repository methods return `Future<Either<Failure, T>>`
* Use package imports (`package:my_pet/...`)
* Apply `const` constructors wherever possible

### UI & Formatting

* Every user-facing string via slang (`t.section.key`) — never hardcode
* Dates formatted with `intl` (`DateFormat.yMMMd()`) — never display raw `DateTime.toString()`
* Pet ages computed from `birthDate`, never stored
* All photos uploaded via the `PhotoStorageService` boundary (Firebase Storage under the hood)
* Visual styling must use tokens from `lib/app/theme/` — never hardcode colors, radii, font sizes, or spacing in widgets

---

## State Management

* **Bloc** for complex event-driven logic (Auth, Household, Notifications)
* **Cubit** for simpler state (PetProfile, VaccinationsList, etc.)

### Rules

* UI must not contain business logic
* Cubits/Blocs orchestrate, UseCases execute logic
* State must be immutable

### Lifecycle

* Global blocs are singletons (`registerLazySingleton`)
* Form cubits are created per use (`registerFactory`)

---

## Performance

* Avoid unnecessary rebuilds (use `const`, selectors, split widgets)
* Prefer granular widgets over large rebuild scopes
* Lists must use lazy builders (`ListView.builder`, etc.)
* Pet photos loaded via `cached_network_image` with disk cache
* Firestore listeners must be scoped to the active household and cancelled on dispose
* Avoid heavy work on UI thread

---

## Local Storage (Hive CE)

* One box per aggregate root: `pets`, `vaccinations`, `health_events`, `weights`, `reminders`, `documents`, `photos`, `outbox`, `settings`
* Boxes are typed (`Box<PetCacheModel>`); models live in `lib/features/<feature>/data/models/<entity>_cache_model.dart` with `@HiveType` annotation
* All boxes are opened during app bootstrap (`AppBootstrap.openBoxes()`); never lazy-open in feature code
* Cache models include a `_updatedAtServer` field for sync ordering
* Hive is **cache only**, never source of truth — Firestore is canonical (see [`docs/specs/sync.md`](docs/specs/sync.md))
* Type IDs are managed centrally in `lib/core/storage/hive_type_ids.dart` to avoid collisions

---

## Security & Privacy (public-repo specific)

* Repository is public — **never** commit:
  * `lib/firebase_options.dart` (regenerated locally with `flutterfire configure`)
  * `android/app/google-services.json`
  * `ios/Runner/GoogleService-Info.plist`
  * `macos/Runner/GoogleService-Info.plist`
  * `firebase.json`, `.firebaserc`
  * Any `*-service-account*.json`
  * `.env*` files (only `.env.example` is allowed)
* Forks must run their own Firebase setup — see `SETUP.md`
* Firestore rules live in `firestore.rules` (committed) and are deployed via the Firebase CLI
* Firestore data is partitioned by `householdId`, never just `userId`, so household members can read each other's pets but no stranger can

---

## Households (Shared Accounts)

* The unit of data ownership is a **Household**, not a User
* A user can belong to **at most one household** (MVP); each household has 1 `ownerId` (admin) and 0..N `memberIds`
* Owner can: invite members, remove members, transfer ownership, delete household
* Members can: read all data, create/edit pets and records (no destructive actions)
* All Firestore documents (pets, vaccinations, etc.) carry a `householdId` field
* Invitations use short-lived codes (server-generated, 6-char, 24h TTL)

---

## Firestore Collections

```
users/{userId}                                  → uid, email, displayName, photoUrl,
                                                  householdId, createdAt
households/{householdId}                        → name, ownerId, memberIds[], createdAt
households/{householdId}/invites/{inviteId}     → code, createdBy, expiresAt, used
households/{householdId}/pets/{petId}           → name, species, breed, sex, birthDate,
                                                  photoUrl, microchipId, weightKg,
                                                  color, allergies[], notes, createdAt
households/{householdId}/pets/{petId}/vaccinations/{id}
                                                → name, appliedDate, nextDueDate,
                                                  vetName, batchNumber, notes, createdAt
households/{householdId}/pets/{petId}/health_events/{id}
                                                → type (vetVisit | medication | deworming
                                                  | grooming | weighIn | other),
                                                  date, title, description, attachments[],
                                                  costBRL?, createdAt
households/{householdId}/pets/{petId}/weights/{id}
                                                → date, weightKg, notes
households/{householdId}/reminders/{id}         → petId?, type, title, dueAt,
                                                  notifyBeforeMinutes[], done, createdAt
households/{householdId}/documents/{id}         → petId?, title, fileUrl, mimeType, createdAt
```

### Guidelines

* Always scope queries by `householdId`
* Avoid unbounded queries — paginate health/vaccination history
* Use indexes explicitly when needed (declared in `firestore.indexes.json`)
* Prefer batched writes for multi-document updates (e.g. completing a reminder + creating a vaccination)
* Soft-delete is preferred over hard-delete for pets (cats outlive the app — keep memories)

---

## Design System

The visual language is documented in [`docs/specs/design.md`](docs/specs/design.md). It is inspired by the **Ahead** app's aesthetic — vibrant purple primary, generous whitespace, oversized bold headlines, friendly illustrations, large pill buttons. All tokens (colors, typography, spacing, radii, shadows) are defined in `lib/app/theme/` and consumed via `Theme.of(context)` extensions; never inline literals.

---

## Auto-loaded context

The line below imports `docs/roadmap.md` so its full contents are always present in the agent's context — no need to ask the agent to "look at the roadmap".

@docs/roadmap.md
