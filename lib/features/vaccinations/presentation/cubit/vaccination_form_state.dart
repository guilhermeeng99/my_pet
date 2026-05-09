part of 'vaccination_form_cubit.dart';

sealed class VaccinationFormState extends Equatable {
  const VaccinationFormState();
  @override
  List<Object?> get props => [];
}

class VaccinationFormIdle extends VaccinationFormState {
  const VaccinationFormIdle();
}

class VaccinationFormSubmitting extends VaccinationFormState {
  const VaccinationFormSubmitting();
}

class VaccinationFormSuccess extends VaccinationFormState {
  const VaccinationFormSuccess();
}

class VaccinationFormError extends VaccinationFormState {
  const VaccinationFormError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
