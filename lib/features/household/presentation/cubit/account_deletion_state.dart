part of 'account_deletion_cubit.dart';

sealed class AccountDeletionState extends Equatable {
  const AccountDeletionState();
  @override
  List<Object?> get props => [];
}

class AccountDeletionIdle extends AccountDeletionState {
  const AccountDeletionIdle();
}

class AccountDeletionDeleting extends AccountDeletionState {
  const AccountDeletionDeleting();
}

class AccountDeletionDone extends AccountDeletionState {
  const AccountDeletionDone();
}

class AccountDeletionFailed extends AccountDeletionState {
  const AccountDeletionFailed(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
