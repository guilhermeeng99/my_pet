part of 'pets_list_cubit.dart';

sealed class PetsListState extends Equatable {
  const PetsListState();
  @override
  List<Object?> get props => [];
}

class PetsListInitial extends PetsListState {
  const PetsListInitial();
}

class PetsListLoading extends PetsListState {
  const PetsListLoading();
}

class PetsListLoaded extends PetsListState {
  const PetsListLoaded(this.pets);
  final List<Pet> pets;
  @override
  List<Object?> get props => [pets];
}

class PetsListEmpty extends PetsListState {
  const PetsListEmpty();
}

class PetsListError extends PetsListState {
  const PetsListError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
