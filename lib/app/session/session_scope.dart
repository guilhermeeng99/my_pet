import 'package:get_it/get_it.dart';
import 'package:my_pet/features/pets/presentation/cubit/pets_list_cubit.dart';

/// Resets singletons whose lifetime is tied to a signed-in session.
///
/// We intentionally keep [PetsListCubit] as a `lazySingleton` to preserve
/// the active-pets stream across detail navigation, but that means its
/// Firestore subscription must be torn down on sign-out — otherwise the
/// listener for the previous user/household stays attached and (once the
/// new user signs in) emits stale data into the freshly-mounted UI.
class SessionScope {
  SessionScope(this._sl);

  final GetIt _sl;

  /// Closes any session-scoped singletons and clears them from the
  /// container so the next sign-in re-creates them with a fresh stream.
  Future<void> reset() async {
    if (_sl.isRegistered<PetsListCubit>()) {
      await _sl<PetsListCubit>().close();
      await _sl.resetLazySingleton<PetsListCubit>();
    }
  }
}
