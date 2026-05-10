import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:my_pet/app/di/injection_container.dart';
import 'package:my_pet/app/i18n/locale_preference_service.dart';
import 'package:my_pet/features/notifications/domain/notification_service.dart';
import 'package:my_pet/firebase_options.dart';
import 'package:my_pet/gen/strings.g.dart';

/// Runs every step required before `runApp`. Order matters:
///
/// 1. Flutter binding so platform channels work.
/// 2. Firebase init so Auth / Firestore / Storage are ready.
/// 3. Google Sign-In init (required by google_sign_in 7.x before any
///    `authenticate()` call).
/// 4. Hive init + open every box up front.
/// 5. Dependency injection wiring.
abstract final class AppBootstrap {
  static Future<void> run() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await GoogleSignIn.instance.initialize();
    await Hive.initFlutter();
    await _openBoxes();
    await configureDependencies();
    await _initLocale();
    // Notifications init lives at the end so DI is ready and so a failure
    // here can't take down the rest of the app — best-effort.
    try {
      await sl<NotificationService>().initialize();
    } on Exception {
      // ignore: notifications are non-critical
    }
  }

  /// Boxes are opened sequentially so Hive's adapter registry stays
  /// deterministic. Adapters are registered inside `configureDependencies`.
  static Future<void> _openBoxes() async {
    // Phase 0 placeholder — actual typed boxes are opened as features land.
    // Keeping this single entry point ensures the order is auditable.
  }

  /// Honors a previously-saved override; falls back to the OS locale on
  /// first run. `listenToDeviceLocale: true` keeps the device fallback live
  /// for users who never picked a language.
  static Future<void> _initLocale() async {
    final prefs = sl<LocalePreferenceService>();
    final stored = prefs.read();
    if (stored != null) {
      await LocaleSettings.setLocale(stored);
    } else {
      await LocaleSettings.useDeviceLocale();
    }
  }
}
