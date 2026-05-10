# Specs — my_pet

Each file here is the source of truth for one feature. Before writing code or tests, update the spec; the code follows the spec, not the other way around.

## Standard structure of a spec

1. **Goal** — one sentence on what the feature delivers to the user
2. **Entities** — fields, types, invariants
3. **Business rules** — numbered, testable
4. **Repository contract** — methods, parameters, return types
5. **States (Cubit/Bloc)** — state machine
6. **Edge cases** — what can go wrong
7. **Screens** — high-level list of pages/widgets
8. **Permissions (household)** — owner vs member

## Specs

### Cross-cutting
- [`design.md`](design.md) — visual design system (Ahead-inspired)

### Phase 1 (MVP)
- [`auth.md`](auth.md) — Google Sign-In + global state
- [`household.md`](household.md) — Shared account (admin + members)
- [`pets.md`](pets.md) — Pet CRUD + photo
- [`vaccinations.md`](vaccinations.md) — Vaccines and next doses
- [`notifications.md`](notifications.md) — Local & push notifications

### Phase 2 (Pet parent complete)
- [`health.md`](health.md) — Vet visits, medications, grooming
- [`weight.md`](weight.md) — Weigh-ins and growth chart
- [`gallery.md`](gallery.md) — Photo gallery
- [`documents.md`](documents.md) — Documents (pet ID, exams)
- [`reminders.md`](reminders.md) — Generic reminders

### Phase 3 (Sync)
- [`sync.md`](sync.md) — Hive cache + offline outbox

## How to use with Claude Code

When asking for a feature, reference the spec: "implement `specs/vaccinations.md`". Claude reads it, writes tests, then code, and suggests edits to the spec if anything no longer fits.
