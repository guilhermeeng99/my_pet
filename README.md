# my_pet

A pet management app for the complete pet parent. Register your animals, track vaccinations with reminders, log vet visits, weigh-ins, medications and more — synced across the whole household.

> **Status:** active development. See [`roadmap.md`](roadmap.md).

---

## Features

- **Multiple pets** with profile photo, breed, birth date, microchip, allergies
- **Vaccinations** with full history and upcoming-dose reminders
- **Health** — vet visits, medications, dewormers, grooming, weigh-ins
- **Growth chart** of weight over time
- **Shared household** — admin + family members access the same pets
- **Notifications** — local for Phase 1, push for Phase 3
- **Photo gallery** per pet
- **Documents** (pet ID, exam PDFs, etc.)
- Light & dark Material 3 themes
- Initial language: English (more locales planned)

---

## Stack

- Flutter (Android, iOS, Web)
- Firebase (Auth, Firestore, Storage, FCM)
- flutter_bloc, get_it, go_router, hive_ce, dartz, slang, very_good_analysis

Conventions and architecture: see [`CLAUDE.md`](CLAUDE.md).

---

## Setup

This repository is **public and ships no Firebase credentials**. You need to create your own Firebase project to run the app.

Full step-by-step in [`SETUP.md`](SETUP.md).

Quick start:

```bash
flutter pub get
dart pub global activate flutterfire_cli
flutterfire configure --project=<your-firebase-project>
dart run slang
dart run build_runner build --delete-conflicting-outputs
flutter run
```

---

## Documentation

- [`CLAUDE.md`](CLAUDE.md) — code conventions, architecture, Firestore rules
- [`SETUP.md`](SETUP.md) — Firebase setup for your fork
- [`roadmap.md`](roadmap.md) — done, in-progress and planned work
- [`specs/`](specs/) — detailed spec per feature
- [`specs/design.md`](specs/design.md) — visual design system
- [`firestore.rules`](firestore.rules) — Firestore security rules (deploy with `firebase deploy --only firestore:rules`)

---

## License

MIT — see [`LICENSE`](LICENSE). Feel free to fork and adapt for your own pets.
