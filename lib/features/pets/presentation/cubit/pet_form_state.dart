part of 'pet_form_cubit.dart';

sealed class PetFormState extends Equatable {
  const PetFormState();
  @override
  List<Object?> get props => [];
}

class PetFormIdle extends PetFormState {
  const PetFormIdle();
}

class PetFormSubmitting extends PetFormState {
  const PetFormSubmitting();
}

class PetFormSuccess extends PetFormState {
  const PetFormSuccess(this.pet);
  final Pet pet;
  @override
  List<Object?> get props => [pet];
}

class PetFormError extends PetFormState {
  const PetFormError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
