part of 'invite_cubit.dart';

sealed class InviteState extends Equatable {
  const InviteState();
  @override
  List<Object?> get props => [];
}

class InviteIdle extends InviteState {
  const InviteIdle();
}

class InviteGenerating extends InviteState {
  const InviteGenerating();
}

class InviteGenerated extends InviteState {
  const InviteGenerated(this.invite);
  final Invite invite;
  @override
  List<Object?> get props => [invite];
}

class InviteError extends InviteState {
  const InviteError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
