import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_pet/features/weight/domain/entities/weight_entry.dart';
import 'package:my_pet/features/weight/domain/repositories/weight_repository.dart';
import 'package:my_pet/features/weight/presentation/cubit/weight_form_state.dart';

class WeightFormCubit extends Cubit<WeightFormState> {
  WeightFormCubit({required WeightRepository repository})
      : _repository = repository,
        super(const WeightFormIdle());

  final WeightRepository _repository;

  Future<void> create(WeightEntry draft) async {
    emit(const WeightFormSubmitting());
    final result = await _repository.create(draft);
    result.fold(
      (failure) => emit(WeightFormError(failure)),
      (saved) => emit(WeightFormSuccess(saved)),
    );
  }

  Future<void> update(WeightEntry entry) async {
    emit(const WeightFormSubmitting());
    final result = await _repository.update(entry);
    result.fold(
      (failure) => emit(WeightFormError(failure)),
      (saved) => emit(WeightFormSuccess(saved)),
    );
  }
}
