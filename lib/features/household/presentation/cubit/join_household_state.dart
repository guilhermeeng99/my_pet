part of 'join_household_cubit.dart';

sealed class JoinHouseholdState extends Equatable {
  const JoinHouseholdState();
  @override
  List<Object?> get props => [];
}

class JoinHouseholdIdle extends JoinHouseholdState {
  const JoinHouseholdIdle();
}

class JoinHouseholdInvalidLength extends JoinHouseholdState {
  const JoinHouseholdInvalidLength();
}

class JoinHouseholdSubmitting extends JoinHouseholdState {
  const JoinHouseholdSubmitting();
}

class JoinHouseholdJoined extends JoinHouseholdState {
  const JoinHouseholdJoined(this.household);
  final Household household;
  @override
  List<Object?> get props => [household];
}

class JoinHouseholdError extends JoinHouseholdState {
  const JoinHouseholdError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
