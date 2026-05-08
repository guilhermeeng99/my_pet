# Setup — my_pet

How to wire up your own Firebase backend to run the app from this fork.

> This repository is public and **does not contain** `firebase_options.dart`, `google-services.json` or `GoogleService-Info.plist`. You need to generate your own.

---

## 1. Prerequisites

| Tool             | Version                | Install                                                       |
| ---------------- | ---------------------- | ------------------------------------------------------------- |
| Flutter          | ≥ 3.24 (Dart 3.11)     | https://docs.flutter.dev/get-started/install                  |
| Firebase CLI     | latest                 | `npm i -g firebase-tools`                                     |
| FlutterFire CLI  | latest                 | `dart pub global activate flutterfire_cli`                    |
| Google account with Firebase enabled |    | https://console.firebase.google.com                           |

---

## 2. Create the Firebase project

1. Open https://console.firebase.google.com and click **Add project**.
2. Pick a name (e.g. `mypet-<your-name>`). Google Analytics is optional.
3. Under **Build → Authentication**, enable the **Google** provider.
4. Under **Build → Firestore Database**, create the database in **production** mode in the region closest to you.
5. Under **Build → Storage**, enable Storage.
6. Under **Build → Cloud Messaging**, copy the Server Key (only needed if you'll use remote push, Phase 3).

---

## 3. Wire the app to Firebase

```bash
firebase login
flutterfire configure --project=<your-firebase-project-id>
```

Pick the platforms you intend to support (Android, iOS, Web). The command generates:

- `lib/firebase_options.dart` (gitignored)
- `android/app/google-services.json` (gitignored)
- `ios/Runner/GoogleService-Info.plist` (gitignored)
- `macos/Runner/GoogleService-Info.plist` (gitignored, if applicable)

> ⚠️ These files are personal and contain keys for **your** project. They are gitignored by default — do not force-commit them.

---

## 4. Configure Google Sign-In

### Android

1. Get the SHA-1 of your debug keystore:
   ```bash
   cd android && ./gradlew signingReport
   ```
2. In the Firebase console → **Project settings → Your apps → Android app → Add fingerprint**, paste the SHA-1.
3. Re-run `flutterfire configure` to refresh `google-services.json`.
4. For release builds, repeat with the production keystore SHA-1.

### iOS

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Add `GoogleService-Info.plist` to the **Runner** target (drag & drop, check "Copy items if needed").
3. In `ios/Runner/Info.plist`, add the `REVERSED_CLIENT_ID` as a URL scheme — see the [google_sign_in](https://pub.dev/packages/google_sign_in) docs for the full snippet.

### Web

1. In **Authentication → Sign-in method → Google**, copy the **Web client ID**.
2. Add it to `web/index.html`:
   ```html
   <meta name="google-signin-client_id" content="YOUR_CLIENT_ID.apps.googleusercontent.com">
   ```

---

## 5. Deploy Firestore & Storage rules

```bash
firebase use <your-firebase-project-id>
firebase deploy --only firestore:rules,firestore:indexes,storage
```

Rules live in [`firestore.rules`](firestore.rules) / [`storage.rules`](storage.rules); indexes are in `firestore.indexes.json`. **Deploy these before signing in** — without them Firestore stays in "anyone can write" mode.

---

## 6. Environment variables (optional)

For future external integrations (e.g. clinic APIs, OpenAI), copy:

```bash
cp .env.example .env
# edit .env with your keys
```

`.env` is gitignored — only commit `.env.example`.

---

## 7. Run

```bash
flutter pub get
dart run slang
dart run build_runner build --delete-conflicting-outputs
flutter run
```

For Web: `flutter run -d chrome`.
For iOS: run `pod install` inside `ios/` before `flutter run`.

The first launch initialises Hive boxes (`pets`, `vaccinations`, `outbox`, etc.) under the device's app-support directory. No manual step required.

---

## 8. Shared household

After your first sign-in you become **admin** of a household created automatically. To invite your partner:

1. Open **Settings → Family**.
2. Tap **Invite member** — generates a 6-character code valid for 24 hours.
3. The other person installs the app, signs in with their Google account, then opens **Settings → Family → Join with code** and enters the code.

Details: [`specs/household.md`](specs/household.md).

---

## Common issues

**`flutterfire configure` fails with "permission denied":** confirm you own the Firebase project or have the `Firebase Admin` role.

**Google Sign-In works in debug but not in release:** you forgot to add the release keystore's SHA-1 to Firebase. Run `signingReport` against the release config and paste in the console.

**Web shows `popup_closed_by_user`:** check that the domain is in **Authentication → Settings → Authorized domains**.

**Firestore returns `permission-denied`:** re-run `firebase deploy --only firestore:rules`, and verify the signed-in user has `householdId` set in `users/{uid}`.

**Hive throws `HiveError: Box not found`:** boxes must be opened during bootstrap. Check that `AppBootstrap.openBoxes()` runs before `runApp()` in `lib/main.dart`.
