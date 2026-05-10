import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_pet/features/health/domain/entities/health_event.dart';
import 'package:my_pet/features/health/domain/repositories/health_repository.dart';
import 'package:my_pet/features/health/presentation/cubit/health_form_state.dart';

class HealthFormCubit extends Cubit<HealthFormState> {
  HealthFormCubit({required HealthRepository repository})
      : _repository = repository,
        super(const HealthFormIdle());

  final HealthRepository _repository;

  Future<void> create(HealthEvent draft) async {
    emit(const HealthFormSubmitting());
    final result = await _repository.create(draft);
    result.fold(
      (failure) => emit(HealthFormError(failure)),
      (saved) => emit(HealthFormSuccess(saved)),
    );
  }

  Future<void> update(HealthEvent event) async {
    emit(const HealthFormSubmitting());
    final result = await _repository.update(event);
    result.fold(
      (failure) => emit(HealthFormError(failure)),
      (saved) => emit(HealthFormSuccess(saved)),
    );
  }
}
