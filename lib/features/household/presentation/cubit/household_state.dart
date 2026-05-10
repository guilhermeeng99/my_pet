part of 'household_cubit.dart';

sealed class HouseholdState extends Equatable {
  const HouseholdState();
  @override
  List<Object?> get props => [];
}

class HouseholdInitial extends HouseholdState {
  const HouseholdInitial();
}

class HouseholdLoading extends HouseholdState {
  const HouseholdLoading();
}

class HouseholdLoaded extends HouseholdState {
  const HouseholdLoaded({required this.household, required this.members});
  final Household household;
  final List<HouseholdMember> members;

  bool get hasPartner => members.length >= 2;

  HouseholdMember? memberFor(String uid) =>
      members.where((m) => m.uid == uid).firstOrNull;

  HouseholdMember? get partnerFor {
    if (members.length < 2) return null;
    return members.firstWhere((m) => m.role == HouseholdRole.partner);
  }

  HouseholdMember? get owner =>
      members.where((m) => m.role == HouseholdRole.owner).firstOrNull;

  @override
  List<Object?> get props => [household, members];
}

class HouseholdNotFound extends HouseholdState {
  const HouseholdNotFound();
}

class HouseholdError extends HouseholdState {
  const HouseholdError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
