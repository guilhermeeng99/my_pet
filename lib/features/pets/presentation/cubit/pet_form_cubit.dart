import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/pets/domain/entities/pet.dart';
import 'package:my_pet/features/pets/domain/repositories/pet_repository.dart';

part 'pet_form_state.dart';

/// Form-mode cubit for create/update. Use `registerFactory` so each form
/// session gets a fresh cubit (CLAUDE.md / Lifecycle).
class PetFormCubit extends Cubit<PetFormState> {
  PetFormCubit({required PetRepository repository})
      : _repository = repository,
        super(const PetFormIdle());

  final PetRepository _repository;

  Future<void> create(Pet draft) async {
    emit(const PetFormSubmitting());
    final result = await _repository.create(draft);
    result.fold(
      (failure) => emit(PetFormError(failure)),
      (created) => emit(PetFormSuccess(created)),
    );
  }

  Future<void> update(Pet pet) async {
    emit(const PetFormSubmitting());
    final result = await _repository.update(pet);
    result.fold(
      (failure) => emit(PetFormError(failure)),
      (updated) => emit(PetFormSuccess(updated)),
    );
  }
}
