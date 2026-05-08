import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_ce_flutter/adapters.dart';

import 'package:my_pet/app/di/injection_container.dart';
import 'package:my_pet/firebase_options.dart';

/// Runs every step required before `runApp`. Order matters:
///
/// 1. Flutter binding so platform channels work.
/// 2. Firebase init so Auth / Firestore / Storage are ready.
/// 3. Hive init + open every box up front (cache feature code never
///    lazy-opens — see CLAUDE.md "Local Storage").
/// 4. Dependency injection wiring.
abstract final class AppBootstrap {
  static Future<void> run() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await Hive.initFlutter();
    await _openBoxes();
    await configureDependencies();
  }

  /// Boxes are opened sequentially so Hive's adapter registry stays
  /// deterministic. Adapters are registered inside `configureDependencies`.
  static Future<void> _openBoxes() async {
    // Phase 0 placeholder — actual typed boxes are opened as features land.
    // Keeping this single entry point ensures the order is auditable.
  }
}
