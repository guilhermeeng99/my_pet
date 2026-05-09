import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/vaccinations/domain/entities/vaccination.dart';
import 'package:my_pet/features/vaccinations/domain/repositories/vaccination_repository.dart';

part 'vaccination_form_state.dart';

class VaccinationFormCubit extends Cubit<VaccinationFormState> {
  VaccinationFormCubit({required VaccinationRepository repository})
      : _repository = repository,
        super(const VaccinationFormIdle());

  final VaccinationRepository _repository;

  Future<void> create(Vaccination draft) async {
    emit(const VaccinationFormSubmitting());
    final result = await _repository.create(draft);
    result.fold(
      (f) => emit(VaccinationFormError(f)),
      (_) => emit(const VaccinationFormSuccess()),
    );
  }

  Future<void> update(Vaccination v) async {
    emit(const VaccinationFormSubmitting());
    final result = await _repository.update(v);
    result.fold(
      (f) => emit(VaccinationFormError(f)),
      (_) => emit(const VaccinationFormSuccess()),
    );
  }

  Future<void> delete(Vaccination v) async {
    emit(const VaccinationFormSubmitting());
    final result =
        await _repository.delete(v.householdId, v.petId, v.id);
    result.fold(
      (f) => emit(VaccinationFormError(f)),
      (_) => emit(const VaccinationFormSuccess()),
    );
  }
}
