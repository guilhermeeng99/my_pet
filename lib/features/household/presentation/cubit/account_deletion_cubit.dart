import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/auth/domain/repositories/auth_repository.dart';
import 'package:my_pet/features/household/domain/repositories/household_repository.dart';

part 'account_deletion_state.dart';

/// Drives the danger-zone "Delete all data" flow: cascade-wipes the user's
/// household subtree, then deletes the Firebase Auth user. Firestore-first
/// so a stale auth credential (`requires-recent-login`) doesn't strand data;
/// the wipe is idempotent and safe to retry after a fresh sign-in.
class AccountDeletionCubit extends Cubit<AccountDeletionState> {
  AccountDeletionCubit({
    required HouseholdRepository households,
    required AuthRepository auth,
  })  : _households = households,
        _auth = auth,
        super(const AccountDeletionIdle());

  final HouseholdRepository _households;
  final AuthRepository _auth;

  Future<void> run({
    required String householdId,
    required String userId,
  }) async {
    _safeEmit(const AccountDeletionDeleting());

    final wipe = await _households.wipeAndLeave(
      householdId: householdId,
      userId: userId,
    );
    final wipeFailure = wipe.fold<Failure?>((f) => f, (_) => null);
    if (wipeFailure != null) {
      _safeEmit(AccountDeletionFailed(wipeFailure));
      return;
    }

    final deleteAuth = await _auth.deleteCurrentAccount();
    final authFailure = deleteAuth.fold<Failure?>((f) => f, (_) => null);
    if (authFailure != null) {
      _safeEmit(AccountDeletionFailed(authFailure));
      return;
    }

    // Auth user is now gone — `_auth.watchAuthState()` will fire null and
    // AuthBloc will navigate away from this page (closing this cubit) before
    // we can emit `Done`. Guard the final emit so it doesn't crash the app.
    _safeEmit(const AccountDeletionDone());
  }

  void _safeEmit(AccountDeletionState state) {
    if (!isClosed) emit(state);
  }

  void reset() => emit(const AccountDeletionIdle());
}
