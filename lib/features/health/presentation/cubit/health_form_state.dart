import 'package:equatable/equatable.dart';
import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/health/domain/entities/health_event.dart';

sealed class HealthFormState extends Equatable {
  const HealthFormState();
  @override
  List<Object?> get props => const [];
}

class HealthFormIdle extends HealthFormState {
  const HealthFormIdle();
}

class HealthFormSubmitting extends HealthFormState {
  const HealthFormSubmitting();
}

class HealthFormSuccess extends HealthFormState {
  const HealthFormSuccess(this.saved);
  final HealthEvent saved;
  @override
  List<Object?> get props => [saved];
}

class HealthFormError extends HealthFormState {
  const HealthFormError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
