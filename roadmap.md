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
- [x] Auto-create household on first sign-in
- [x] Persist `householdId` in `users/{uid}`
- [ ] Settings placeholder screens (members come in Phase 3)

### 🐾 Pets — [`specs/pets.md`](specs/pets.md)
- [x] Create pet (name, species, sex, birth date)
- [x] Edit pet
- [x] Pet list (home)
- [ ] Profile photo (upload via Firebase Storage)
- [x] Soft-delete (archive pet)
- [x] Age computed from birth date

### 💉 Vaccinations — [`specs/vaccinations.md`](specs/vaccinations.md)
- [ ] Register applied vaccine (name, date, next due date)
- [ ] List history per pet
- [ ] Visual indicator: "due in N days" / "overdue"
- [ ] Edit / delete vaccine
- [ ] Suggestions for common vaccines (V4, V5, rabies)

### 🔔 Local reminders — [`specs/notifications.md`](specs/notifications.md)
- [ ] Local notification 7 days before next dose
- [ ] Local notification on the day
- [ ] Notification permission in onboarding

---

## Phase 2 — Complete pet parent

> Health history, weight, more love.

### 🩺 Health — [`specs/health.md`](specs/health.md)
- [ ] Log vet visit
- [ ] Log medication (with schedule)
- [ ] Log dewormer
- [ ] Log grooming session
- [ ] Attach photo / PDF per event
- [ ] Optional cost (currency-agnostic) per event

### ⚖️ Weight & growth — [`specs/weight.md`](specs/weight.md)
- [ ] Register weigh-in
- [ ] Weight evolution chart (fl_chart)
- [ ] Visual alert if change > 10% month over month

### 📷 Gallery — [`specs/gallery.md`](specs/gallery.md)
- [ ] Add photos to a pet (timeline)
- [ ] Full-screen viewer
- [ ] Share photo

### 📄 Documents — [`specs/documents.md`](specs/documents.md)
- [ ] Upload PDFs / images (pet ID, exams)
- [ ] Category per type
- [ ] Inline preview (PDF + image)

### 🔔 Generic reminders — [`specs/reminders.md`](specs/reminders.md)
- [ ] Standalone reminders (not tied to vaccines)
- [ ] Recurrence (daily, weekly, monthly, yearly)
- [ ] Mark as done

---

## Phase 3 — Sharing & cloud

> You + spouse access the same pets. Real push.

### 👥 Shared household — [`specs/household.md`](specs/household.md)
- [ ] Family members screen
- [ ] Generate invite code (6 chars, 24h TTL)
- [ ] Accept invite
- [ ] Remove member (admin only)
- [ ] Transfer admin
- [ ] Minimal audit ("who changed what")

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
- [ ] A11y audit (semantics, contrast, touch target size)
- [ ] Add pt-BR locale via slang
- [ ] Dynamic font scaling

### 📊 Insights
- [ ] "Health of the month" dashboard (visits, costs, upcoming vaccines)
- [ ] Cumulative veterinary spending

### 🆘 Emergency
- [ ] Pet ID card (microchip, allergies, vet)
- [ ] "Lost pet" mode — printable poster PDF

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
