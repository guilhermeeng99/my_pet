part of 'startup_cubit.dart';

sealed class StartupState extends Equatable {
  const StartupState();
  @override
  List<Object?> get props => const [];
}

final class StartupInitial extends StartupState {
  const StartupInitial();
}

final class StartupLoading extends StartupState {
  const StartupLoading({required this.progress});
  final double progress;
  @override
  List<Object?> get props => [progress];
}

final class StartupAuthenticated extends StartupState {
  const StartupAuthenticated();
}

final class StartupUnauthenticated extends StartupState {
  const StartupUnauthenticated();
}
