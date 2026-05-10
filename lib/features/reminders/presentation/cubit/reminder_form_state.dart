import 'package:equatable/equatable.dart';
import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/reminders/domain/entities/reminder.dart';

sealed class ReminderFormState extends Equatable {
  const ReminderFormState();
  @override
  List<Object?> get props => const [];
}

class ReminderFormIdle extends ReminderFormState {
  const ReminderFormIdle();
}

class ReminderFormSubmitting extends ReminderFormState {
  const ReminderFormSubmitting();
}

class ReminderFormSuccess extends ReminderFormState {
  const ReminderFormSuccess(this.saved);
  final Reminder saved;
  @override
  List<Object?> get props => [saved];
}

class ReminderFormError extends ReminderFormState {
  const ReminderFormError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
