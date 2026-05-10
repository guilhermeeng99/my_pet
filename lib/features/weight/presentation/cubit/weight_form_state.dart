import 'package:equatable/equatable.dart';
import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/weight/domain/entities/weight_entry.dart';

sealed class WeightFormState extends Equatable {
  const WeightFormState();
  @override
  List<Object?> get props => const [];
}

class WeightFormIdle extends WeightFormState {
  const WeightFormIdle();
}

class WeightFormSubmitting extends WeightFormState {
  const WeightFormSubmitting();
}

class WeightFormSuccess extends WeightFormState {
  const WeightFormSuccess(this.saved);
  final WeightEntry saved;
  @override
  List<Object?> get props => [saved];
}

class WeightFormError extends WeightFormState {
  const WeightFormError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
