import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:my_pet/features/auth/presentation/bloc/auth_bloc.dart';

part 'startup_state.dart';

/// Orchestrates the cold-start → first-screen transition. Today its only job
/// is to wait for [AuthBloc] to leave [AuthInitial], so the router redirect
/// can stay on the splash route until the very first auth emission lands —
/// without that gate, the redirect would flip from splash to welcome and
/// back to home as `AuthBloc` resolved.
///
/// Future hooks (Hive cache warmup, Firestore prefetch, biometric gate)
/// slot into the `Loading(progress: 0.7)` window before the terminal state.
class StartupCubit extends Cubit<StartupState> {
  StartupCubit({required AuthBloc authBloc})
      : _authBloc = authBloc,
        super(const StartupInitial());

  final AuthBloc _authBloc;
  StreamSubscription<AuthState>? _subscription;

  /// Idempotent — repeated calls from non-[StartupInitial] states are a no-op.
  Future<void> initialize() async {
    if (state is! StartupInitial) return;
    emit(const StartupLoading(progress: 0.2));

    final hasSession = await _waitForAuth();
    if (isClosed) return;
    emit(const StartupLoading(progress: 0.7));

    if (!hasSession) {
      emit(const StartupUnauthenticated());
      return;
    }
    emit(const StartupAuthenticated());
  }

  /// Returns true once `AuthBloc` has surfaced a Firebase Auth session
  /// (Authenticated / NeedsHousehold / CreatingHousehold). Returns false
  /// once it has surfaced a non-session state (Unauthenticated / Error).
  /// Waits indefinitely while still in [AuthInitial] or [AuthLoading].
  Future<bool> _waitForAuth() async {
    final current = _authBloc.state;
    if (_isResolved(current)) return _isSignedIn(current);

    final completer = Completer<bool>();
    _subscription = _authBloc.stream.listen((state) {
      if (_isResolved(state) && !completer.isCompleted) {
        completer.complete(_isSignedIn(state));
      }
    });
    return completer.future;
  }

  bool _isResolved(AuthState state) =>
      state is! AuthInitial && state is! AuthLoading;

  bool _isSignedIn(AuthState state) =>
      state is AuthAuthenticated ||
      state is AuthNeedsHousehold ||
      state is AuthCreatingHousehold;

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
