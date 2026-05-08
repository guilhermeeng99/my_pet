import 'package:get_it/get_it.dart';

/// Service locator. All implementations are registered here.
///
/// - `registerLazySingleton` — global services (auth repo, sync engine).
/// - `registerFactory` — short-lived objects like form cubits.
///
/// Features add their registrations via top-level `_registerXxx` functions
/// in this file (or feature-local `register.dart` files imported here),
/// keeping bootstrap order obvious.
final GetIt sl = GetIt.instance;

Future<void> configureDependencies() async {
  if (sl.isRegistered<bool>(instanceName: '_diReady')) return;

  // Phase 0: registrations land as features arrive. Keeping the function
  // here so AppBootstrap has a stable entry point.

  sl.registerSingleton<bool>(true, instanceName: '_diReady');
}
